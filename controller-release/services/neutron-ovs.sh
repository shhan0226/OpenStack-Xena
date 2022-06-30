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
# Neutron
##################################
mysql -e "CREATE DATABASE neutron;"
mysql -e "GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'localhost' IDENTIFIED BY '${STACK_PASSWD}';"
mysql -e "GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'%' IDENTIFIED BY '${STACK_PASSWD}';"
mysql -e "FLUSH PRIVILEGES;"
echo "Neutron CREATE DB ..."
openstack user create --domain default --password ${STACK_PASSWD} neutron
openstack role add --project service --user neutron admin
openstack service create --name neutron \
  --description "OpenStack Networking" network
openstack endpoint create --region RegionOne \
  network public http://${SET_IP}:9696
openstack endpoint create --region RegionOne \
  network internal http://${SET_IP}:9696
openstack endpoint create --region RegionOne \
  network admin http://${SET_IP}:9696  
echo "Networking Option 2: Self-service networks"
apt install -y bridge-utils openvswitch-switch
apt install -y neutron-server neutron-plugin-ml2 neutron-l3-agent neutron-dhcp-agent neutron-metadata-agent neutron-openvswitch-agent 
crudini --set /etc/neutron/neutron.conf database connection mysql+pymysql://neutron:${STACK_PASSWD}@${SET_IP}/neutron
crudini --set /etc/neutron/neutron.conf DEFAULT core_plugin ml2
crudini --set /etc/neutron/neutron.conf DEFAULT service_plugins router
crudini --set /etc/neutron/neutron.conf DEFAULT allow_overlapping_ips true
crudini --set /etc/neutron/neutron.conf DEFAULT transport_url rabbit://openstack:${STACK_PASSWD}@${SET_IP}
crudini --set /etc/neutron/neutron.conf DEFAULT auth_strategy keystone
crudini --set /etc/neutron/neutron.conf DEFAULT dhcp_agents_per_network 2
crudini --set /etc/neutron/neutron.conf DEFAULT notify_nova_on_port_status_changes true
crudini --set /etc/neutron/neutron.conf DEFAULT notify_nova_on_port_data_changes true
crudini --set /etc/neutron/neutron.conf keystone_authtoken www_authenticate_uri http://${SET_IP}:5000
crudini --set /etc/neutron/neutron.conf keystone_authtoken auth_url http://${SET_IP}:5000
crudini --set /etc/neutron/neutron.conf keystone_authtoken memcached_servers ${SET_IP}:11211
crudini --set /etc/neutron/neutron.conf keystone_authtoken auth_type password
crudini --set /etc/neutron/neutron.conf keystone_authtoken project_domain_name default
crudini --set /etc/neutron/neutron.conf keystone_authtoken user_domain_name default
crudini --set /etc/neutron/neutron.conf keystone_authtoken project_name service
crudini --set /etc/neutron/neutron.conf keystone_authtoken username neutron
crudini --set /etc/neutron/neutron.conf keystone_authtoken password ${STACK_PASSWD}
crudini --set /etc/neutron/neutron.conf nova auth_url http://${SET_IP}:5000
crudini --set /etc/neutron/neutron.conf nova auth_type password
crudini --set /etc/neutron/neutron.conf nova project_domain_name default
crudini --set /etc/neutron/neutron.conf nova user_domain_name default
crudini --set /etc/neutron/neutron.conf nova region_name RegionOne
crudini --set /etc/neutron/neutron.conf nova project_name service
crudini --set /etc/neutron/neutron.conf nova username nova
crudini --set /etc/neutron/neutron.conf nova password ${STACK_PASSWD}
crudini --set /etc/neutron/neutron.conf oslo_concurrency lock_path /var/lib/neutron/tmp
echo "Configure the Modular Layer 2 (ML2) plug-in"
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 type_drivers flat,vlan,vxlan
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 tenant_network_types vxlan
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 mechanism_drivers openvswitch,l2population
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 extension_drivers port_security
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2_type_flat flat_networks provider
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2_type_vlan network_vlan_ranges provider
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2_type_vxlan vni_ranges 1:1000
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini securitygroup enable_ipset true
crudini --set /etc/neutron/plugins/ml2/openvswitch_agent.ini ovs bridge_mappings provider:${INTERFACE_NAME_}
crudini --set /etc/neutron/plugins/ml2/openvswitch_agent.ini ovs local_ip ${SET_IP}
crudini --set /etc/neutron/plugins/ml2/openvswitch_agent.ini agent tunnel_types vxlan
crudini --set /etc/neutron/plugins/ml2/openvswitch_agent.ini agent l2_population True
crudini --set /etc/neutron/plugins/ml2/openvswitch_agent.ini securitygroup firewall_driver iptables_hybrid
sysctl net.bridge.bridge-nf-call-iptables
sysctl net.bridge.bridge-nf-call-ip6tables
echo "Configure the layer-3 agent"
crudini --set /etc/neutron/l3_agent.ini DEFAULT interface_driver openvswitch
echo "DHCP agent config"
crudini --set /etc/neutron/dhcp_agent.ini DEFAULT interface_driver openvswitch
crudini --set /etc/neutron/dhcp_agent.ini DEFAULT dhcp_driver neutron.agent.linux.dhcp.Dnsmasq
crudini --set /etc/neutron/dhcp_agent.ini DEFAULT enable_isolated_metadata true
crudini --set /etc/neutron/dhcp_agent.ini DEFAULT force_metadata true
echo "Configure the metadata agent"
crudini --set /etc/neutron/metadata_agent.ini DEFAULT nova_metadata_host ${SET_IP}
crudini --set /etc/neutron/metadata_agent.ini DEFAULT metadata_proxy_shared_secret ${STACK_PASSWD}
crudini --set /etc/nova/nova.conf neutron auth_url http://${SET_IP}:5000
crudini --set /etc/nova/nova.conf neutron auth_type password
crudini --set /etc/nova/nova.conf neutron project_domain_name default
crudini --set /etc/nova/nova.conf neutron user_domain_name default
crudini --set /etc/nova/nova.conf neutron region_name RegionOne
crudini --set /etc/nova/nova.conf neutron project_name service
crudini --set /etc/nova/nova.conf neutron username neutron
crudini --set /etc/nova/nova.conf neutron password ${STACK_PASSWD}
crudini --set /etc/nova/nova.conf neutron service_metadata_proxy true
crudini --set /etc/nova/nova.conf neutron metadata_proxy_shared_secret ${STACK_PASSWD}
echo "Neutron - Finalize installation"
su -s /bin/sh -c "neutron-db-manage --config-file /etc/neutron/neutron.conf \
  --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head" neutron
service nova-api restart
service neutron-server restart
service neutron-openvswitch-agent restart
service neutron-dhcp-agent restart
service neutron-metadata-agent restart
service neutron-l3-agent restart
