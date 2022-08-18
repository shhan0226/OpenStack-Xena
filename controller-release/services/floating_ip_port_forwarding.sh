#!/bin/bash

##################################
# Change root privileges.
##################################
IAMACCOUNT=$(whoami)
echo "${IAMACCOUNT}"
if [ "$IAMACCOUNT" = "root" ]; then
    echo "It's root account."
else
    echo "It's not a root account."
	  exit 100
fi

echo "port_forwarding set..."
crudini --set /etc/neutron/neutron.conf DEFAULT service_plugins router,segments,port_forwarding
crudini --set /etc/neutron/l3_agent.ini agent extensions port_forwarding

. admin-openrc
openstack extension list --network
