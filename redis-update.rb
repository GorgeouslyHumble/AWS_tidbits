#!/usr/bin/env ruby
#
#

require 'benchmark'
require 'yaml'
require 'aws-sdk'
#require 'fog'
require 'ohm'
require 'csv'
require 'pp'
require 'thread'
require 'net/ssh'
require 'rest_client'

$aws_region = 'us-east-1'
$public_key = ''
$secret_key = ''

class Instance < Ohm::Model
  attribute :instance_id
  attribute :server_state
  attribute :lb_state
  attribute :public_ip
  attribute :private_ip
  attribute :zone
  attribute :version
  attribute :local_launch
  attribute :expiration
  attribute :chef_output
  attribute :term_protection

  index :instance_id
  index :version
  index :server_state
  index :expiration
  index :lb_state
  index :chef_output
  index :term_protection

  def validate
    assert_present :instance_id
    assert_present :farm
  end
end

# class Notification < Ohm::Model
#   attribute :session
#   attribute :message

#   def validate
#     assert_present :session
#   end
# end

# class Log < Ohm::Model
#   attribute :message
#   attribute :timestamp
# end

Ohm.connect 

# - Fog Connection - #
# def connection
#   @connection ||= begin
#     connection = Fog::Compute.new(
#       :provider => 'AWS',
#       :aws_access_key_id => $public_key,
#       :aws_secret_access_key => $secret_key,
#       :region => $aws_region
#     )
#   end
# end

$ec2 = AWS::EC2.new(
  :access_key_id => $public_key,
  :secret_access_key => $secret_key)

# - Update ec2 status - #
def ec2_update

  begin
    #If the server state key in redis is "terminated", clear the key from Redis.
    Instance.find(:server_state => "terminated").each do |instance|
      instance.delete
    end

    servers = $ec2.instances

    instance_collection = Array.new   

    AWS.memoize do
      servers.each do |server|
        print "grabbed server "
        instance_collection << [
          server.id || "Error.",
          server.status,
          server.ip_address,
          server.private_ip_address,
          server.availability_zone,
          server.tags['Name'] || "Error.",
          server.tags['Environment'] || "Error.",
          server.tags['Version'] || "Error.",
          server.launch_time,
          server.tags['chef_run'] || nil,
          server.api_termination_disabled?
        ]
      end
    end

    puts "starting"

    instance_collection.each do |server|
      if Instance.find(:instance_id => server[0]).first
        print "found "
        record = Instance.find(:instance_id => server[0]).first
      else
        print "new "
        record = Instance.new
      end
      record.instance_id = server[0]
      record.server_state = server[1]
      record.public_ip = server[2]
      record.private_ip = server[3]
      record.zone = server[4]
      record.environment = server[5]
      record.version = server[7]
      record.project = server[8]
      record.local_launch = server[9]
      record.expiration = server[10]
      record.is_data_lb = server[11]
      record.chef_result = server[12]
      record.term_protection = server[13]
      record.lb_state = nil
      record.save
    end 

    #Exception handling.
    rescue AWS::Core::Client::NetworkError
      sleep 1
    rescue AWS::EC2::Errors::InvalidInstanceID::NotFound
      sleep 1
    rescue Redis::TimeoutError
      sleep 1
    rescue Exception => error_name
      puts error_name
  end
end
  
def lb_update
    #Draws from Redis
  loadbalancers = Instance.find(:farm => 'haproxy')
  
  #Create the array
  haproxy_raw = []
  
  #Parse the CSV file from Haproxy.
  begin
    loadbalancers.each do |lb|
      haproxy_raw.concat(CSV.parse(RestClient.get "http://admin:uopfat@#{lb.public_ip}:8887/stats;csv;norefresh", :timeout => 9001))
    end
  rescue RestClient::RequestTimeout
    puts "Request timed out"
    sleep 1
  end
  begin    
    loadbalancers.each do |lb|
      haproxy_raw.concat(CSV.parse(RestClient.get "http://admin:uopfat@#{lb.public_ip}:8887/stats;csv;norefresh", :timeout => 9001))
    end
    #puts haproxy_raw
    haproxy_raw.each do |x|
 
      if x[1] =~ /i-[0-9a-f]{8}/
        begin
          #Finds the instance IDs in Redis that were taken from the CSV file and then marks their lb_state as 'UP'.
          record = Instance.find(:instance_id => x[1]).first
          record.lb_state = x[17]
          record.save
        rescue
          #puts "Instance not found: " + x[1]
        end
      end
    end
  rescue
    puts "Problem collecting haproxy stats"
  end
end

time = Benchmark.realtime do
  ec2_update
  lb_update
end
puts "Time elapsed #{time*1000} milliseconds"

puts "complete"
