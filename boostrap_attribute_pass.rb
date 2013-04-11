### I USUALLY DON'T KNOW WHAT I'M DOING.


runlist = [ "RECIPES ALL OVER THE PLACE" ]

attributes = {"app" => { "key" => "#{service}" }}.to_json

ruby = "ruby-" + RUBY_VERSION + "-p" + RUBY_PATCHLEVEL.to_s

begin
  knife = `~/.rvm/gems/#{ruby}/gems/chef-10.12.0/bin/knife bootstrap #{server.dns_name} -N #{server.id} --sudo --no-host-key-verify --identity-file #{APPLICATION_PATH}/conf/ssh_keys/#{$environment[env]['key_name']}.pem --environment #{$environment[env]['chef_env']} --ssh-user ec2-user --run-list '#{runlist.join(",")}' --json-attributes '#{attributes}' --template-file #{APPLICATION_PATH}/chef/amazon.erb -c #{APPLICATION_PATH}/conf/knife_config.rb`
rescue Exception => error_name
  LoggingControl::log('deployment_control', error_name)
end

# --- What is happening here:

# So there are parameters you can pass to knife that will be interpolated into a Chef bootsrap script. But here's the kicker: I couldn't find those variable names documented any where. I just knew that the 'run_list' variable was a hash that had your recipes in it. (the --run-list flag)
# After digging through knife source code, GitHub commits, and messing around with deployments... I found out that the first_boot variable was a combination of both the run list and any json attributes that you pass through knife. Yay. This was to get New Relic operational. The below
# chunk of script comes from opscode.


#     (
# cat <<'EOP'
# <%= validation_key %>
# EOP
# ) > /tmp/validation.pem
# awk NF /tmp/validation.pem > /etc/chef/validation.pem
# rm /tmp/validation.pem

# (
# cat <<'EOP'
# <%= config_content %>
# EOP
# ) > /etc/chef/client.rb

# (
# cat <<'EOP'
# <%= first_boot.to_json %>
# EOP
# ) > /etc/chef/first-boot.json

# <%= start_chef %>'