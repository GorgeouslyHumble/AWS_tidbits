
###################
# This script will get splunk working on some dynamic components. It is bad and I should feel bad.
###################

require 'ohm'
require 'net/ssh'

class Instance < Ohm::Model
  attribute :instance_id
  attribute :server_state
  attribute :lb_state
  attribute :public_ip
  attribute :private_ip
  attribute :zone
  attribute :farm
  attribute :environment
  attribute :project
  attribute :version
  attribute :local_launch
  attribute :build_log
  attribute :expiration
  attribute :is_data_lb
  attribute :chef_result
  attribute :chef_out
  attribute :term_protection
  attribute :instance_type

  index :instance_id
  index :farm
  index :version
  index :environment
  index :project
  index :server_state
  index :expiration
  index :is_data_lb
  index :lb_state
  index :chef_result
  index :term_protection
end

Ohm.connect

#Either dev or qa2
if ARGV[0].nil?
  puts "Enter an environment name - dev or qa2"
end
env_name = ARGV[0]
#The key pair is named class-qa.pem where the attribute for Metis instance keys is qa2... different names for different environments.
env_name == 'dev' ? env_key_pair = 'dev' : env_key_pair = 'qa'
server_list = Instance.find(:is_data_lb => 'yes', :environment => "#{env_name}", :chef_result => 'success', :server_state => 'running')

free_mem_script_two = <<TERMINATE

[script://./bin/free.sh]
interval = 300
sourcetype = free
source = free
index = os
disabled = false
TERMINATE

install_steps = <<TERMINATE
sudo cp free.sh /opt/splunkforwarder/etc/apps/unix/bin/free.sh
sudo chmod +x /opt/splunkforwarder/etc/apps/unix/bin/free.sh
sudo sed -i '85,$d' /opt/splunkforwarder/etc/apps/unix/local/inputs.conf
sudo bash -c 'cat free_mem_script_two >> /opt/splunkforwarder/etc/apps/unix/local/inputs.conf'
sudo cp /opt/splunkforwarder/etc/system/local/outputs.conf /opt/splunkforwarder/etc/system/local/outputs.conf.back
sudo rm /opt/splunkforwarder/etc/system/local/outputs.conf
sudo cp forwarder_address_replace /opt/splunkforwarder/etc/system/local/outputs.conf
sudo service splunk restart
TERMINATE

forwarder_address_replace = <<TERMINATE
[tcpout]
defaultGroup = default_9997
 
[tcpout:default_9997]
#Contained dns names for splunk forwarders.
server = ''
autoLB = true
TERMINATE

outFile = File.new("splunk_install_script.sh", "w")
outFile.puts("#{install_steps}")
outFile.close

outFile = File.new("free_mem_script_two", "w")
outFile.puts("#{free_mem_script_two}")
outFile.close

outFile =File.new("forwarder_address_replace", "w")
outFile.puts("#{forwarder_address_replace}")
outFile.close

begin
  server_list.each do |server|
    if server.version.to_s.match(/2.0.0/)

      scp_cmd = "scp -o StrictHostKeyChecking=no -q -i ../conf/ssh_keys/class-#{env_key_pair}.pem"
      ssh_cmd = "ssh -o StrictHostKeyChecking=no -t -q -i ../conf/ssh_keys/class-#{env_key_pair}.pem"
      public_ip = server.public_ip
      address = "ec2-user@#{public_ip}"
      puts "Operating on server: #{server.instance_id}"
      install_script = `#{scp_cmd} splunk_install_script.sh #{address}:~/`
      free_mem_script = `#{scp_cmd} free.sh #{address}:~/`
      free_mem_script2 = `#{scp_cmd} free_mem_script_two #{address}:~/`
      forwarder_address_replace = `#{scp_cmd} forwarder_address_replace #{address}:~/`

      system_ssh_install_call = `#{ssh_cmd} #{address} 'sudo ln -s /opt/glassfish/default/glassfish/learningplatform/logs/messagetracking.log /var/log/'`
      system_ssh_remove_call = `#{ssh_cmd} #{address} 'rm -rf free.sh splunk_install_script.sh free_mem_script_two forwarder_address_replace'`
      # Net::SSH.start(server.public_ip, 'ec2-user', :keys => ["class-qa.pem"], :paranoid => false) do |ssh|
      #   puts "Connected to #{server.instance_id}"
      #   delete = 'rm -rf splunk_install_script.sh free_mem_script_two.sh free_mem_script.sh free_mem_script free_mem_script_two splunk_install_script forwarder_address_replace.sh forwarder_address_replace'
      #   @return = ssh.exec! delete
      # end
    end
  end
rescue Exception => error
  puts error
end

remove = `rm splunk_install_script.sh free_mem_script_two forwarder_address_replace`

