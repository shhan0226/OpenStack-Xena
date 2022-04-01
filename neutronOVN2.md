1. openvswitch-ovn및 networking-ovn패키지 를 설치
```
apt -y install neutron-server neutron-plugin-ml2 python3-neutronclient ovn-central openvswitch-switch
```

2. 네트워킹 서버 구성 요소를 구성
```
mv /etc/neutron/neutron.conf /etc/neutron/neutron.conf.org
vi /etc/neutron/neutron.conf
>
[DEFAULT]
core_plugin = ml2
service_plugins = ovn-router
    # 참고
    auth_strategy = keystone
    state_path = /var/lib/neutron
    allow_overlapping_ips = True
    notify_nova_on_port_status_changes = True
    notify_nova_on_port_data_changes = True
    # RabbitMQ connection info
    transport_url = rabbit://openstack:password@controller
    # Keystone auth info
    [keystone_authtoken]
    www_authenticate_uri = http://controller:5000
    auth_url = http://controller:5000
    memcached_servers = controller:11211
    auth_type = password
    project_domain_name = default
    user_domain_name = default
    project_name = service
    username = neutron
    password = servicepassword
    [database]
    connection = mysql+pymysql://neutron:password@controller/neutron_ml2
    [nova]
    auth_url = http://controller:5000
    auth_type = password
    project_domain_name = default
    user_domain_name = default
    region_name = RegionOne
    project_name = service
    username = nova
    password = servicepassword
    [oslo_concurrency]
    lock_path = $state_path/tmp
```

3. 네트워킹 서버 구성 요소를 구성
```
mv /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugins/ml2/ml2_conf.ini.org
vi /etc/neutron/plugins/ml2/ml2_conf.ini
>
[ml2]
...
type_drivers = local,flat,vlan,geneve
tenant_network_types = geneve
mechanism_drivers = ovn
extension_drivers = port_security
overlay_ip_version = 4
[ml2_type_geneve]
...
vni_ranges = 1:65536
max_header_size = 38
[ml2_type_vlan]
...
#network_vlan_ranges = PHYSICAL_NETWORK:MIN_VLAN_ID:MAX_VLAN_ID
network_vlan_ranges = physnet1,physnet2:1001:2000
[securitygroup]
...
enable_security_group = true
    # 참고
    firewall_driver = neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver
[ovn]
...
ovn_nb_connection = tcp:controller:6641
ovn_sb_connection = tcp:controller:6642
#ovn_l3_scheduler = OVN_L3_SCHEDULER
    # 참고
    ovn_l3_scheduler = leastloaded
    ovn_metadata_enabled = True
    # 참고
    [ml2_type_flat]
    flat_networks = *
```