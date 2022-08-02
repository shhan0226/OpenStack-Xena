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
read -p "Do you want to set up? {yes|no|ENTER=yes} " CHECKER_NO_
if [ "$CHECKER_NO_" = "no" ]; then
    exit 100
else
    echo "Keep Going!!"
fi
echo "$CONTROLLER_HOST"
echo "$COMPUTE_HOST"
echo "$SET_IP"
echo "$SET_IP2"
echo "$SET_IP_ALLOW"
echo "$INTERFACE_NAME_"
echo "$STACK_PASSWD"
echo "... set!!"
##################################
# config /etc/hosts
##################################
sudo apt install net-tools -y
ifconfig
echo "Set IP ...."
sed -i "s/127.0.1.1/\#127.0.1.1/" /etc/hosts
echo "$SET_IP $CONTROLLER_HOST" >> /etc/hosts
echo "$SET_IP2 $COMPUTE_HOST" >> /etc/hosts
sudo hostnamectl set-hostname ${COMPUTE_HOST}
sync
##################################
# SET Interface 
##################################
mkdir -p /etc/network
touch /etc/network/interfaces
echo "auto $INTERFACE_NAME_" >> /etc/network/interfaces
echo "iface $INTERFACE_NAME_ inet manual" >> /etc/network/interfaces
echo "up ip link set dev $INTERFACE_NAME_ up" >> /etc/network/interfaces
echo "down ip link set dev $INTERFACE_NAME_ down" >> /etc/network/interfaces
sync
##################################
# APT update & upgrade
##################################
sudo apt update
sudo apt upgrade -y
##################################
# Install Package
##################################
sudo apt install -y git vim curl wget build-essential python3-pip python-is-python3
echo "Install simplejson ..."
pip install simplejson
pip install --ignore-installed simplejson
echo "Install crudini ..."
wget https://github.com/pixelb/crudini/releases/download/0.9.3/crudini-0.9.3.tar.gz
tar xvf crudini-0.9.3.tar.gz
mv crudini-0.9.3/crudini /usr/bin/
pip3 install iniparse
rm -rf crudini-0.9.3 crudini-0.9.3.tar.gz
sync
##################################
# Install NTP
##################################
apt install chrony -y
echo "server $CONTROLLER_HOST iburst" >> /etc/chrony/chrony.conf	
sudo service chrony restart
chronyc sources
chronyc sources
##################################
# Install Openstack Client
##################################
add-apt-repository cloud-archive:xena -y
sudo apt install python3-openstackclient -y
