require 'aws-sdk'
require 'pp'
require 'ohm'

$public_key = ''
$secret_key = ''

$ec2 = AWS::EC2.new(
  :access_key_id => $public_key,
  :secret_access_key => $secret_key)


def self.tcp_test_ssh(hostname)
  tcp_socket = TCPSocket.new(hostname, 22)
  readable = IO.select([tcp_socket], nil, nil, 5)
  if readable
    puts "sshd accepting connections on #{hostname}, banner is #{tcp_socket.gets}"
    yield
    true
  else
    false
  end
  rescue SocketError
    sleep 2
    false
  rescue Errno::ETIMEDOUT
    false
  rescue Errno::EPERM
    false
  rescue Errno::ECONNREFUSED
    sleep 2
    false
  rescue Errno::EHOSTUNREACH
    sleep 2
    false
  rescue Errno::EPIPE
    sleep 2
    false
  rescue IOError
    sleep 2
    false
  rescue Errno::ENETUNREACH
    sleep 2
    false
  ensure
    tcp_socket && tcp_socket.close
end

def spawn_server
  server = $ec2.instances.create(
    :image_id => 'ami-1e831d77',
    :instance_type => 'm1.small',
    :key_name => ''
  )

  while server.status == :pending
    print '.'
  end

  puts "The server #{server.id} was created."

  print(".") until tcp_test_ssh(server.dns_name) {
    sleep 15
  }

  puts "#{server.tags['Name']} is accessible."

  $ec2.instances[server.instance_id].tag('Name', :value => 'Blank server')

  return server.id
end

spawn_server


