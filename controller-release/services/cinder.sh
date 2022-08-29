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

##################################
# auth
##################################
# Inpute Value
CONTROLLER_HOST="controller"
COMPUTE_HOST="compute1"
SET_IP="192.168.1.105"
SET_IP2="192.168.1.105"
SET_IP_ALLOW="192.168.0.0/22"
INTERFACE_NAME_="br-provider"
STACK_PASSWD="stack"

. admin-openrc
echo "$CONTROLLER_HOST"
echo "$SET_IP"
echo "$SET_IP2"
echo "$SET_IP_ALLOW"
echo "$INTERFACE_NAME_"
echo "$STACK_PASSWD"
echo "... set!!"


##################################
# Cinder
##################################
echo "Cinder !!"



##################################
# Controller node
echo "Cinder CREATE DB ..."
mysql -e "CREATE DATABASE cinder;"
mysql -e "GRANT ALL PRIVILEGES ON cinder.* TO 'cinder'@'localhost' IDENTIFIED BY '${STACK_PASSWD}';"
mysql -e "GRANT ALL PRIVILEGES ON cinder.* TO 'cinder'@'%' IDENTIFIED BY '${STACK_PASSWD}';"
mysql -e "FLUSH PRIVILEGES;"

echo "Cinder CREATE SERVICE ..."
. admin-openrc

openstack user create --domain default --password ${STACK_PASSWD} cinder

openstack role add --project service --user cinder admin

openstack service create --name cinderv3 --description "OpenStack Block Storage" volumev3

echo "Create the Block Storage service API endpoints:"
openstack endpoint create --region RegionOne volumev3 public http://${SET_IP}:8776/v3/%\(project_id\)s

openstack endpoint create --region RegionOne volumev3 internal http://${SET_IP}:8776/v3/%\(project_id\)s

openstack endpoint create --region RegionOne volumev3 admin http://${SET_IP}:8776/v3/%\(project_id\)s
  
echo "Cinder Install on Controller..."
apt install -y cinder-api cinder-scheduler
crudini --set /etc/cinder/cinder.conf database connection mysql+pymysql://cinder:${STACK_PASSWD}@${SET_IP}/cinder
crudini --set /etc/cinder/cinder.conf DEFAULT transport_url rabbit://openstack:${STACK_PASSWD}@${SET_IP}
crudini --set /etc/cinder/cinder.conf DEFAULT auth_strategy keystone
crudini --set /etc/cinder/cinder.conf keystone_authtoken www_authenticate_uri http://${SET_IP}:5000
crudini --set /etc/cinder/cinder.conf keystone_authtoken auth_url http://${SET_IP}:5000
crudini --set /etc/cinder/cinder.conf keystone_authtoken memcached_servers ${SET_IP}:11211
crudini --set /etc/cinder/cinder.conf keystone_authtoken auth_type password
crudini --set /etc/cinder/cinder.conf keystone_authtoken project_domain_name default
crudini --set /etc/cinder/cinder.conf keystone_authtoken user_domain_name default
crudini --set /etc/cinder/cinder.conf keystone_authtoken project_name service
crudini --set /etc/cinder/cinder.conf keystone_authtoken username cinder
crudini --set /etc/cinder/cinder.conf keystone_authtoken password ${STACK_PASSWD}
crudini --set /etc/cinder/cinder.conf DEFAULT my_ip ${SET_IP}
crudini --set /etc/cinder/cinder.conf oslo_concurrency lock_path /var/lib/cinder/tmp

echo "Cinder Reg. DB ..."
su -s /bin/sh -c "cinder-manage db sync" cinder

echo "Configure Compute to use Block Storage ..."
crudini --set /etc/nova/nova.conf cinder os_region_name RegionOne

echo "Cinder Verify operation ..."
service nova-api restart
service cinder-scheduler restart
service apache2 restart



##################################
# storage node

echo "Cinder Install on Storage Node..."
apt install lvm2 thin-provisioning-tools
