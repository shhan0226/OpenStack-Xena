#!/bin/bash

echo "Install Controller for OpenStack ..."

# Inpute Value
H_NAMEv="compute1"
SET_IPv="192.168.1.5"
SET_IP2v="192.168.1.6"
SET_IP_ALLOWv="192.168.0.0/22"
INTERFACE_NAME_v="eth0"
STACK_PASSWDv="stack"

read -p "Do you want to input ?? {yes|no|ENTER=no} :" CHECKER_O_
if [ "$CHECKER_O_" = "yes" ]; then
    read -p "Input HOSTNAME: " H_NAMEv
    read -p "Input Contorller IP: (ex.192.168.0.2) " SET_IPv
    read -p "Input Compute1 IP: (ex.192.168.0.3) " SET_IP2v
    read -p "Input the allow IP (ex 192.168.0.0/24): " SET_IP_ALLOWv
    read -p "Input INTERFACE_NAME: " INTERFACE_NAME_v
    read -p "Input STACK_PASSWD: " STACK_PASSWDv
    export H_NAME=H_NAMEv
    export SET_IP=SET_IPv
    export SET_IP2=SET_IP2v
    export SET_IP_ALLOW=SET_IP_ALLOWv
    export INTERFACE_NAME_=INTERFACE_NAME_v
    export STACK_PASSWD=STACK_PASSWDv
else    
    export H_NAME=H_NAMEv
    export SET_IP=SET_IPv
    export SET_IP2=SET_IP2v
    export SET_IP_ALLOW=SET_IP_ALLOWv
    export INTERFACE_NAME_=INTERFACE_NAME_v
    export STACK_PASSWD=STACK_PASSWDv
fi

# INPUT DATA PRINT
echo "$H_NAME"
echo "$SET_IP"
echo "$SET_IP2"
echo "$SET_IP_ALLOW"
echo "$INTERFACE_NAME_"
echo "$STACK_PASSWD"
echo "... set!!"

# INSTALL START
echo "1. Install Compute Setting ..."
source ./services/compute_setting.sh
read -p "Install Nova ?? {yes|no|ENTER=yes} :" CHECKER_Node
if [ "$CHECKER_Node" = "no" ]; then
    echo "Please Install Contoller Node (Nova)"
    exit 100
else
    echo "2. Install Nova ..."
    source ./services/nova_compute.sh
fi
read -p "Install Neutron ?? {yes|no|ENTER=yes} :" CHECKER_Node
if [ "$CHECKER_Node" = "no" ]; then
    echo "Please Install Contoller Node (Neutron)"
    exit 100
else
    echo "3. Install Neutron ..."
    source ./services/neutron-compute.sh
fi






