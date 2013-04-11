##This is just an incomplete chunk out of a larger source file. I want to keep this around...

def self.automated_lb_switch(env, scale_set_id)
  #This is meant to be 'glue code' that will feed the collection of instances to the update_lb_config method. It will analyze Redis, looking for a scale set to put on the load balancer.
  #How am I going to keep that scale set intact AND limit its lifespan? Possible answer: I could clear that attribute from all the relative keys after the automated_lb_switch method runs. However, that can be unwieldy later when we try to do fancy auto healing stuff.
  instance_set = Instance.find(:environment => env, :scale_set_id => scale_set_id)
  puts "Waiting until all the instances are running."
  instance_set.each do |instance|
    until $ec2[instance.instance_id].status == 'running'
      sleep 3; print '.'
    end
  end
  lb = Instance.find(:environment => env, :farm => "haproxy")
  for instance in lb do
    update_lb_config(instance.public_ip, instance_set, 'back_end')
  end
  instance_set.each do |record|
    record.scale_set_id = nil
    record.save
  end
end