#!/bin/bash

echo "Install Controller for OpenStack ..."
export H_NAME="controller"
export SET_IP="192.168.1.10"
export SET_IP2="192.168.1.11"
export SET_IP_ALLOW="192.168.0.0/22"
export INTERFACE_NAME_="eth0"
export STACK_PASSWD="stack"

echo "$H_NAME"
echo "$SET_IP"
echo "$SET_IP2"
echo "$SET_IP_ALLOW"
echo "$INTERFACE_NAME_"
echo "$STACK_PASSWD"
echo "... set!!"


echo "Install Controller Setting ..."
source ./services/controller-setting.sh

echo "Install Keystone ..."
#source ./serviceskeystone.sh