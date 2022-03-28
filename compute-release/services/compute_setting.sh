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
# config /etc/hosts
##################################
echo "[IP Setting]"
sudo apt install net-tools -y
ifconfig
echo "Set IP ...."
sed -i "s/127.0.1.1 vraptor/\#127.0.1.1 vraptor/" /etc/hosts
echo "$SET_IP controller" >> /etc/hosts
echo "$SET_IP2 compute1" >> /etc/hosts
sudo hostnamectl set-hostname ${H_NAME}
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
echo "server controller iburst" >> /etc/chrony/chrony.conf	
sudo service chrony restart
chronyc sources
chronyc sources
##################################
# Install Openstack Client
##################################
add-apt-repository cloud-archive:xena -y
sudo apt install python3-openstackclient -y