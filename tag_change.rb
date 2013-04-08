require 'aws-sdk'

begin
  $ec2 = AWS::EC2.new(
    :access_key_id => '',
    :secret_access_key => '')
rescue Exception => error
  puts error
end

instance_id = `curl --silent http://169.254.169.254/latest/meta-data/instance-id`
server = $ec2.instances[instance_id]
bundle_status = ARGV[0]

begin
  if bundle_status.to_s.match('installed')
    server.tag('bundle_status', :value => 'installed')
    puts 'installed'
  else bundle_status.to_s.match('error')
    puts 'error'
    server.tag('bundle_status', :value => 'error')
  end
rescue Exception => error
  puts error
end