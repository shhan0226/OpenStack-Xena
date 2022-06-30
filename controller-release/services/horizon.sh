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
#read -p "Do you want to install Horizon? {yes|no|ENTER=yes} " CHECKER_NO_
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
echo "$COMPUTE_HOST"
echo "$SET_IP"
echo "$SET_IP2"
echo "$SET_IP_ALLOW"
echo "$INTERFACE_NAME_"
echo "$STACK_PASSWD"
echo "... set!!"
##################################
# Horizon
##################################
apt install -y openstack-dashboard
cp /etc/openstack-dashboard/local_settings.py /etc/openstack-dashboard/local_settings.py.backup

sed -i "s/OPENSTACK_HOST = \"127.0.0.1\"/OPENSTACK_HOST = \"${SET_IP}\"/" /etc/openstack-dashboard/local_settings.py
sed -i "s/'LOCATION': '127.0.0.1:11211',/'LOCATION': '${SET_IP}:11211',/" /etc/openstack-dashboard/local_settings.py
sed -i 's/http:\/\/\%s\/identity\/v3/http:\/\/\%s:5000\/v3/' /etc/openstack-dashboard/local_settings.py
sed -i 's/TIME_ZONE = "UTC"/TIME_ZONE = "Asia\/Seoul"/' /etc/openstack-dashboard/local_settings.py
echo "SESSION_ENGINE = 'django.contrib.sessions.backends.cache'" >> /etc/openstack-dashboard/local_settings.py
systemctl reload apache2.service
