require 'aws-sdk'
require 'fog'
require 'pp'

$aws_region = 'us-east-1'
$public_key = ''
$secret_key = ''

AWS.config(:access_key_id => $public_key, :secret_access_key => $secret_key)

# - Fog Connection - #
def connection
  @connection ||= begin
    connection = Fog::Compute.new(
      :provider => 'AWS',
      :aws_access_key_id => $public_key,
      :aws_secret_access_key => $secret_key,
      :region => $aws_region
    )
  end
end

server_list = connection.servers.all

ec2 = AWS::EC2.new

#"i-ad37ecdc"

#pp AWS::EC2::Instance.instance_methods

servers = connection.servers.all

#pp ec2.instances["i-ad37ecdc"].api_termination_disabled?

# ec2.instances.each do |server|
#   if server.instance_id == "i-ad37ecdc"
#     puts server.api_termination_disabled?
#   end
# end

servers.each do |server|
  puts ec2.instances["#{server}"].api_termination_disabled?
end