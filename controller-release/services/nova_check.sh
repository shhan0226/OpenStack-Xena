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
#read -p "Do you want to check Nova? {yes|no|ENTER=yes} " CHECKER_NO_
#if [ "$CHECKER_NO_" = "no" ]; then
#    exit 100
#else
#    echo "Keep Going!!"
#fi
##################################
# auth
##################################
. admin-openrc
echo "$CONTROLLER_HOST"
echo "$SET_IP"
echo "$SET_IP2"
echo "$SET_IP_ALLOW"
echo "$INTERFACE_NAME_"
echo "$STACK_PASSWD"
echo "... set!!"
##################################
# nova check
##################################
sync
openstack compute service list --service nova-compute
su -s /bin/sh -c "nova-manage cell_v2 discover_hosts --verbose" nova
crudini --set /etc/nova/nova.conf scheduler discover_hosts_in_cells_interval 300
echo "NOVA Verify operation"
. admin-openrc
openstack compute service list
openstack catalog list
openstack image list
nova-status upgrade check
