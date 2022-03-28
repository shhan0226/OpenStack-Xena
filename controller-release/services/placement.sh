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
read -p "Do you want to FINISH?? {yes|no|ENTER=no} " CHECKER_NO_
if [ "$CHECKER_NO_" = "yes" ]; then
    exit 100
else
    echo "Keep Going!!"
fi
##################################
# Inpute value
##################################
H_NAME="controller"
SET_IP="192.168.1.10"
SET_IP2="192.168.1.11"
SET_IP_ALLOW="192.168.0.0/22"
INTERFACE_NAME_="eth0"
STACK_PASSWD="stack"
##################################
# auth
##################################
. admin-openrc
##################################
# Placement
##################################
echo "Placement !!"
mysql -e "CREATE DATABASE placement;"
mysql -e "GRANT ALL PRIVILEGES ON placement.* TO 'placement'@'localhost' IDENTIFIED BY '${STACK_PASSWD}';"
mysql -e "GRANT ALL PRIVILEGES ON placement.* TO 'placement'@'%' IDENTIFIED BY '${STACK_PASSWD}';"
mysql -e "FLUSH PRIVILEGES;"
echo "Placement CREATE DB ..."
openstack user create --domain default --password ${STACK_PASSWD} placement
openstack role add --project service --user placement admin
openstack service create --name placement \
  --description "Placement API" placement
openstack endpoint create --region RegionOne \
  placement public http://controller:8778
openstack endpoint create --region RegionOne \
  placement internal http://controller:8778
openstack endpoint create --region RegionOne \
  placement admin http://controller:8778
echo "Placement Install ..."
apt install -y placement-api
crudini --set /etc/placement/placement.conf placement_database connection mysql+pymysql://placement:${STACK_PASSWD}@controller/placement 
crudini --set /etc/placement/placement.conf api auth_strategy keystone
crudini --set /etc/placement/placement.conf keystone_authtoken auth_url http://controller:5000/v3
crudini --set /etc/placement/placement.conf keystone_authtoken memcached_servers controller:11211
crudini --set /etc/placement/placement.conf keystone_authtoken auth_type password
crudini --set /etc/placement/placement.conf keystone_authtoken project_domain_name Default
crudini --set /etc/placement/placement.conf keystone_authtoken user_domain_name Default
crudini --set /etc/placement/placement.conf keystone_authtoken project_name service
crudini --set /etc/placement/placement.conf keystone_authtoken username placement 
crudini --set /etc/placement/placement.conf keystone_authtoken password ${STACK_PASSWD}
echo "Placement - python (option)"
su -s /bin/sh -c "placement-manage db sync" placement
service apache2 restart
echo "Placement Verify operation ..."
. admin-openrc
placement-status upgrade check
pip3 install osc-placement
openstack --os-placement-api-version 1.2 resource class list --sort-column name
openstack --os-placement-api-version 1.6 trait list --sort-column name
