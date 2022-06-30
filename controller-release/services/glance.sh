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
#read -p "Do you want to install Glance? {yes|no|ENTER=yes} " CHECKER_NO_
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
# Glance
##################################
echo "Glance !!"
echo "Glance CREATE DB ..."
mysql -e "CREATE DATABASE glance;"
mysql -e "GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'localhost' IDENTIFIED BY '${STACK_PASSWD}';"
mysql -e "GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'%' IDENTIFIED BY '${STACK_PASSWD}';"
mysql -e "FLUSH PRIVILEGES;"
echo "Glance CREATE SERVICE ..."
. admin-openrc
openstack user create --domain default --password ${STACK_PASSWD} glance
openstack role add --project service --user glance admin
openstack service create --name glance \
  --description "OpenStack Image" image
echo "Glance - Create the Image service API endpoints ..."
openstack endpoint create --region RegionOne \
  image public http://${SET_IP}:9292
openstack endpoint create --region RegionOne \
  image internal http://${SET_IP}:9292
openstack endpoint create --region RegionOne \
  image admin http://${SET_IP}:9292
echo "Glance Install ..."
apt install -y glance
crudini --set /etc/glance/glance-api.conf database connection mysql+pymysql://glance:${STACK_PASSWD}@${SET_IP}/glance
crudini --set /etc/glance/glance-api.conf keystone_authtoken www_authenticate_uri http://${SET_IP}:5000
crudini --set /etc/glance/glance-api.conf keystone_authtoken auth_url http://${SET_IP}:5000
crudini --set /etc/glance/glance-api.conf keystone_authtoken memcached_servers ${SET_IP}:11211
crudini --set /etc/glance/glance-api.conf keystone_authtoken auth_type password
crudini --set /etc/glance/glance-api.conf keystone_authtoken project_domain_name Default
crudini --set /etc/glance/glance-api.conf keystone_authtoken user_domain_name Default
crudini --set /etc/glance/glance-api.conf keystone_authtoken project_name service
crudini --set /etc/glance/glance-api.conf keystone_authtoken username glance
crudini --set /etc/glance/glance-api.conf keystone_authtoken password ${STACK_PASSWD}
crudini --set /etc/glance/glance-api.conf paste_deploy flavor keystone
crudini --set /etc/glance/glance-api.conf glance_store stores file,http
crudini --set /etc/glance/glance-api.conf glance_store default_store file
crudini --set /etc/glance/glance-api.conf glance_store filesystem_store_datadir /var/lib/glance/images/
echo "Glance Reg. DB ..."
su -s /bin/sh -c "glance-manage db_sync" glance
service glance-api restart
echo "Glance Verify operation ..."
sync
. admin-openrc
wget https://download.cirros-cloud.net/0.4.0/cirros-0.4.0-aarch64-disk.img

## GLANCE TEST
#glance image-create --name "cirros" --file cirros-0.4.0-aarch64-disk.img --disk-format qcow2 --container-format bare --visibility=public 
#glance image-create --name "u20-ARM" --file focal-server-cloudimg-arm64.img --disk-format qcow2 --container-format bare --visibility=public
#glance image-list
