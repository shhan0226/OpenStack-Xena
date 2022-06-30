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
#read -p "Do you want to install ovs-neutron? {yes|no|ENTER=yes} " CHECKER_NO_
#if [ "$CHECKER_NO_" = "no" ]; then
#    exit 100
#else
#    echo "Keep Going!!"
#fi
echo "$CONTROLLER_HOST"
echo "$COMPUTE_HOST"
echo "$SET_IP"
echo "$SET_IP2"
echo "$SET_IP_ALLOW"
echo "$INTERFACE_NAME_"
echo "$STACK_PASSWD"
echo "... set!!"
##################################
# Neutron compute1
##################################
echo "Neutron CREATE SERVICE ..."
apt install openvswitch-switch neutron-openvswitch-agent -y
crudini --set /etc/neutron/neutron.conf DEFAULT transport_url rabbit://openstack:${STACK_PASSWD}@${SET_IP}
crudini --set /etc/neutron/neutron.conf DEFAULT core_plugin ml2
crudini --set /etc/neutron/neutron.conf DEFAULT auth_strategy keystone
crudini --set /etc/neutron/neutron.conf keystone_authtoken www_authenticate_uri http://${SET_IP}:5000
crudini --set /etc/neutron/neutron.conf keystone_authtoken auth_url http://${SET_IP}:5000
crudini --set /etc/neutron/neutron.conf keystone_authtoken memcached_servers ${SET_IP}:11211
crudini --set /etc/neutron/neutron.conf keystone_authtoken auth_type password
crudini --set /etc/neutron/neutron.conf keystone_authtoken project_domain_name default
crudini --set /etc/neutron/neutron.conf keystone_authtoken user_domain_name default
crudini --set /etc/neutron/neutron.conf keystone_authtoken project_name service
crudini --set /etc/neutron/neutron.conf keystone_authtoken username neutron
crudini --set /etc/neutron/neutron.conf keystone_authtoken password ${STACK_PASSWD}
crudini --set /etc/neutron/neutron.conf oslo_concurrency lock_path /var/lib/neutron/tmp
echo  "Networking Option 2: Self-service networks"
crudini --set /etc/neutron/plugins/ml2/openvswitch_agent.ini ovs bridge_mappings provider:${INTERFACE_NAME_}
crudini --set /etc/neutron/plugins/ml2/openvswitch_agent.ini ovs local_ip ${SET_IP2}
crudini --set /etc/neutron/plugins/ml2/openvswitch_agent.ini agent tunnel_types vxlan 
crudini --set /etc/neutron/plugins/ml2/openvswitch_agent.ini agent l2_population True
crudini --set /etc/neutron/plugins/ml2/openvswitch_agent.ini securitygroup firewall_driver iptables_hybrid
crudini --set /etc/neutron/dhcp_agent.ini DEFAULT interface_driver openvswitch
crudini --set /etc/neutron/dhcp_agent.ini DEFAULT enable_isolated_metadata True
crudini --set /etc/neutron/dhcp_agent.ini DEFAULT force_metadata True
crudini --set /etc/neutron/metadata_agent.ini DEFAULT nova_metadata_host ${SET_IP}
crudini --set /etc/neutron/metadata_agent.ini DEFAULT metadata_proxy_shared_secret ${STACK_PASSWD}
sysctl net.bridge.bridge-nf-call-iptables
sysctl net.bridge.bridge-nf-call-ip6tables
echo "Configure the Compute service to use the Networking service"
crudini --set /etc/nova/nova.conf neutron auth_url http://${SET_IP}:5000
crudini --set /etc/nova/nova.conf neutron auth_type password
crudini --set /etc/nova/nova.conf neutron project_domain_name default
crudini --set /etc/nova/nova.conf neutron user_domain_name default
crudini --set /etc/nova/nova.conf neutron region_name RegionOne
crudini --set /etc/nova/nova.conf neutron project_name service
crudini --set /etc/nova/nova.conf neutron username neutron
crudini --set /etc/nova/nova.conf neutron password ${STACK_PASSWD}
service nova-compute restart
service neutron-openvswitch-agent restart
