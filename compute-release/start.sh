#!/bin/bash

echo "Install Compute for OpenStack ..."

# Inpute Value
CONTROLLER_HOSTv="controller"
COMPUTE_HOSTv="compute1"
SET_IPv="192.168.1.5"
SET_IP2v="192.168.1.6"
SET_IP_ALLOWv="192.168.0.0/22"
INTERFACE_NAME_v="eth0"
STACK_PASSWDv="stack"

read -p "Do you want to input ?? {yes|no|ENTER=no} :" CHECKER_O_
if [ "$CHECKER_O_" = "yes" ]; then
    read -p "Input CONTROLLER HOSTNAME: " CONTROLLER_HOSTv
    read -p "Input COMPUTE HOSTNAME: " CONTROLLER_HOSTv
    read -p "Input Contorller IP: (ex.192.168.0.2) " SET_IPv
    read -p "Input Compute1 IP: (ex.192.168.0.3) " SET_IP2v
    read -p "Input the allow IP (ex 192.168.0.0/24): " SET_IP_ALLOWv
    read -p "Input INTERFACE_NAME: " INTERFACE_NAME_v
    read -p "Input STACK_PASSWD: " STACK_PASSWDv
    export CONTROLLER_HOST=$CONTROLLER_HOSTv
    export COMPUTE_HOST=$COMPUTE_HOSTv
    export SET_IP=$SET_IPv
    export SET_IP2=$SET_IP2v
    export SET_IP_ALLOW=$SET_IP_ALLOWv
    export INTERFACE_NAME_=$INTERFACE_NAME_v
    export STACK_PASSWD=$STACK_PASSWDv
else    
    export CONTROLLER_HOST=$CONTROLLER_HOSTv
    export COMPUTE_HOST=$COMPUTE_HOSTv
    export SET_IP=$SET_IPv
    export SET_IP2=$SET_IP2v
    export SET_IP_ALLOW=$SET_IP_ALLOWv
    export INTERFACE_NAME_=$INTERFACE_NAME_v
    export STACK_PASSWD=$STACK_PASSWDv
fi

# INPUT DATA PRINT
echo "$CONTROLLER_HOST"
echo "$COMPUTE_HOST"
echo "$SET_IP"
echo "$SET_IP2"
echo "$SET_IP_ALLOW"
echo "$INTERFACE_NAME_"
echo "$STACK_PASSWD"
echo "... set!!"

# INSTALL START
echo "1. Install Compute Setting ..."
source ./services/compute_setting.sh
read -p "Are you going to install Nova? {yes|no|ENTER=yes} :" CHECKER_Node
if [ "$CHECKER_Node" = "no" ]; then
    echo "Please Install Contoller Node (Nova)"
    exit 100
else
    echo "2. Install Nova ..."
    source ./services/nova_compute.sh
fi
read -p "Are you going to install Neutron? {yes|no|ENTER=yes} :" CHECKER_Node
if [ "$CHECKER_Node" = "no" ]; then
    echo "Please Install Contoller Node (Neutron)"
    exit 100
else
    echo "3. Install Neutron ..."
    read -p "Is OVS installed? {yes|no|ENTER=no} :" CHECKER_OVS
    if [ "$CHECKER_OVS" = "yes" ]; then
        echo "OVS-Neutorn!!"
        source ./services/neutron-compute-ovs.sh
    else
        echo "Neutorn!!"
        source ./services/neutron-compute.sh        
    fi
fi

# echo "4. Floating IP port forwarding..."
# read -p "SET PORT FORWARDING? {yes|no|ENTER=no} :" CHECKER_FORWARDING
# if [ "$CHECKER_FORWARDING" = "yes" ]; then
# 		source ./services/floating_ip_port_forwarding.sh
# else
# 		echo "Done..."
# fi

