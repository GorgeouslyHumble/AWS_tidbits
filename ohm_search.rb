require 'pp'
require 'fog'
require 'ohm'
require 'redis'

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

Ohm.connect

collection = Instance.find(:lb_state => 'UP')

collection.each do |i|
  pp i
end

# # - Warning: DO NOT RUN UNLESS YOU KNOW WHAT YOU ARE DOING! - #
# def reaper
#   #Healthy represents all the instances that are healthy in the environment. I.e, previous deployments.
#   healthy = Instance.find(:is_data_lb => "yes", :server_state => "running", :lb_state => nil, :term_protection => "false")
#   healthy.each do |instance|
#     if instance.version.match('\d.\d.\d.\d{4}')
#       #RedisControl::terminate(instance.instance_id)
#       pp instance
#     end
#   end
#   incomplete = Instance.find(:is_data_lb => 'no', :server_state => 'running', :farm => 'Error', :environment => 'Error')
#   incomplete.each do |instance|
#     pp instance
#     #RedisControl::terminate(instance.instance_id)
#   end
# end
# reaper


