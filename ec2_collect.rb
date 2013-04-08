require 'aws-sdk'
require 'pp'
require 'ohm'

$ec2 = AWS::EC2.new(
  :access_key_id => '',
  :secret_access_key => '')

servers = $ec2.instances

array = Array.new

AWS.memoize do
  servers.each do |server|
    array << [
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

pp array