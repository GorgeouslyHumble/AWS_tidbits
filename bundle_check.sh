#!/bin/bash

cd /opt/scripts/bundle_check
sudo rm artifacts_installed artifacts_to_install screenlog.0
grep -E '(^helio_name:|^version:)' /opt/glassfish/metadata.txt
grep prod /opt/glassfish/metadata.txt | sort -u | awk '{print "          " $2}'
grep '^curl_osgi /opt/glassfish/' /opt/glassfish/install_bundles.sh | awk -F/ '{print "osgi:     " $5}' > artifacts_to_install
grep '^/opt/glassfish/default/glassfish/bin/asadmin deploy' /opt/glassfish/install_bundles.sh | awk -F/ '{print "asadmin:  " $11}' >> artifacts_to_install

screen -d -m -L -S CONSOLE sudo telnet localhost 6666
sleep 1
screen -p 0 -S CONSOLE -X eval "stuff "ps"\015"
sleep 2
screen -p 0 -S CONSOLE -X eval "stuff \04"
grep -E "\[   (18|19|20)\]" screenlog.0 > artifacts_installed
killall screen
sudo /opt/glassfish/default/glassfish/bin/asadmin list-components | grep web >> artifacts_installed

bundle_count=$(wc -l artifacts_to_install | awk '{print $1}')
install_count=$(wc -l artifacts_installed | awk '{print $1}')
#Instead of calling an external Ruby script I should be using the EC2 API tools that come with the instance.
#Also to note, an IAM role needs to be established so the instance can change its own tags.
if [ $bundle_count == $install_count ]
then
  ruby tag_change.rb installed
else
  ruby tag_change.rb error
fi
rm screenlog.0