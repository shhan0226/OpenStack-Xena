# Neutron-OVS


## Controller node

- IP 설정
  ```
  # 패키지 설치
  sudo apt install openvswitch-switch
  sudo apt install bridge-utils
  sudo apt install net-tools
  # ovs 확인
  ovs-vsctl show
  # 브리지 확인
  brctl show
  # OVS 브리지 생성
  sudo ovs-vsctl add-br br-provider
  # OVS 브리지 확인
  sudo ovs-vsctl list-br 
  # 기본 네트워크 삭제
  sudo ifconfig eth0 0.0.0.0
  # 기본 포트 추가 (네트워크안됨)
  ovs-vsctl add-port br-provider eth0
  # 기본 포트 추가확인
  sudo ovs-vsctl list-ports br-provider
  # ip설정
  sudo vi /etc/netplan/00-.yaml
  >
  # This is the network config written by 'subiquity'
  network:
    version: 2
    ethernets:
      eth0: {}
    bridges:
      br-provider:
        openvswitch: {}      
        addresses: [192.168.1.3/22]
        gateway4: 192.168.0.1
        nameservers:
          addresses: [8.8.8.8,8.8.4.4]
  ```

- OVS provider bridge br-provider:
  ```
  sudo ovs-vsctl add-br br-provider
  sudo ovs-vsctl add-port br-provider PROVIDER_INTERFACE
  sudo netplan apply
  ```


- neutron.conf
  ```
  vi /etc/neutron/neutron.conf
  >
  [DEFAULT]
  core_plugin = ml2
  auth_strategy = keystone
  dhcp_agents_per_network = 2
  service_plugins = router
  allow_overlapping_ips = True
  ```

-  ml2_conf.ini
  ```
  vi /etc/neutron/plugins/ml2/ml2_conf.ini
  >
  [ml2]
  type_drivers = flat,vlan,vxlan
  tenant_network_types = vxlan
  mechanism_drivers = openvswitch,l2population
  extension_drivers = port_security   
  [ml2_type_flat]
  flat_networks = provider
  [ml2_type_vlan]
  network_vlan_ranges = provider
  [ml2_type_vxlan]
  #vni_ranges = VNI_START:VNI_END
  vni_ranges = 1:1000
  ```

- databases:
  ```
  su -s /bin/sh -c "neutron-db-manage --config-file /etc/neutron/neutron.conf \
  --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head" neutron
  ```


## Network node / Controller node
- neutron.conf
  ```
  vi /etc/neutron/neutron.conf
  >
  [DEFAULT]
  core_plugin = ml2
  auth_strategy = keystone
  ```

- openvswitch_agent.ini:
  ```
  vi /etc/neutron/plugins/ml2/openvswitch_agent.ini
  >
  [ovs]
  bridge_mappings = provider:br-provider
  local_ip = 192.168.1.8
  [agent]
  tunnel_types = vxlan
  l2_population = True
  [securitygroup]
  firewall_driver = iptables_hybrid
  ```

- l3_agent.ini 수정
  ```
  vi /etc/neutron/l3_agent.ini
  >
  [DEFAULT]
  interface_driver = openvswitch
  ```



## Compute node

- OVS설치
  ```
  apt install -y openvswitch-switch neutron-openvswitch-agent
  ```

- neutron.conf
  ```
  vi /etc/neutron/neutron.conf
  >
  [DEFAULT]
  core_plugin = ml2
  auth_strategy = keystone
  ```

- openvswitch_agent.ini
  ```
  vi /etc/neutron/plugins/ml2/openvswitch_agent.ini
  >
  [ovs]
  bridge_mappings = provider:br-provider
  local_ip = 192.168.1.9
  [agent]
  tunnel_types = vxlan
  l2_population = True
  [securitygroup]
  firewall_driver = iptables_hybrid
  ```

- dhcp_agent.ini
  ```
  vi /etc/neutron/dhcp_agent.ini
  >
  [DEFAULT]
  interface_driver = openvswitch
  enable_isolated_metadata = True
  force_metadata = True
  ```

- metadata_agent.ini
  ```
  vi /etc/neutron/metadata_agent.ini
  >
  [DEFAULT]
  nova_metadata_host = controller
  metadata_proxy_shared_secret = stack
  ```

- OVS provider bridge br-provider:
  ```
  sudo ovs-vsctl add-br br-provider
  # sudo ovs-vsctl add-port br-provider PROVIDER_INTERFACE 
  sudo ovs-vsctl add-port br-provider eth0
  sudo netplan apply
  ```


















- Prerequisites

```
mysql -u root -p
CREATE DATABASE neutron;
#
# GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'localhost' \
  IDENTIFIED BY 'NEUTRON_DBPASS';
GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'localhost' \
  IDENTIFIED BY 'stack';
#
# GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'%' \
  IDENTIFIED BY 'NEUTRON_DBPASS';
GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'%' \
  IDENTIFIED BY 'stack';
#
FLUSH PRIVILEGES;
exit;
#
. admin-openrc
#
# openstack user create --domain default --password-prompt neutron
openstack user create --domain default --password stack neutron
#
openstack role add --project service --user neutron admin
# Create the neutron service entity:
openstack service create --name neutron \
  --description "OpenStack Networking" network
# Create the Networking service API endpoints:
openstack endpoint create --region RegionOne \
  network public http://controller:9696
openstack endpoint create --region RegionOne \
  network internal http://controller:9696
openstack endpoint create --region RegionOne \
  network admin http://controller:9696
```

---




## Configure networking options (OVS)
- https://docs.openstack.org/neutron/xena/admin/deploy-ovs-selfservice.html

- Controller : install
```
apt install -y neutron-server neutron-plugin-ml2 \
  neutron-l3-agent neutron-dhcp-agent neutron-metadata-agent
#  
apt install -y openvswitch-switch neutron-openvswitch-agent
```

- Controller : neutron.conf
```
cp /etc/neutron/neutron.conf /etc/neutron/neutron.conf.org
vi /etc/neutron/neutron.conf
>
[DEFAULT]
core_plugin = ml2
auth_strategy = keystone
service_plugins = router
allow_overlapping_ips = True
dhcp_agents_per_network = 2
#transport_url = rabbit://openstack:RABBIT_PASS@controller
transport_url = rabbit://openstack:stack@controller
notify_nova_on_port_status_changes = true
notify_nova_on_port_data_changes = true
#
[database]
# connection = mysql+pymysql://neutron:NEUTRON_DBPASS@controller/neutron
connection = mysql+pymysql://neutron:stack@controller/neutron
#
[keystone_authtoken]
www_authenticate_uri = http://controller:5000
auth_url = http://controller:5000
memcached_servers = controller:11211
auth_type = password
project_domain_name = default
user_domain_name = default
project_name = service
username = neutron
#password = NEUTRON_PASS
password = stack
#
[nova]
auth_url = http://controller:5000
auth_type = password
project_domain_name = default
user_domain_name = default
region_name = RegionOne
project_name = service
username = nova
#password = NOVA_PASS
password = stack
#
[oslo_concurrency]
lock_path = /var/lib/neutron/tmp
#
[agent]
```

- Controller : ml2
```
cp /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugins/ml2/ml2_conf.ini.org
vi /etc/neutron/plugins/ml2/ml2_conf.ini
>
[ml2]
type_drivers = flat,vlan,vxlan
tenant_network_types = vxlan
mechanism_drivers = openvswitch,l2population
extension_drivers = port_security
#
[ml2_type_flat]
flat_networks = provider
#
[ml2_type_vlan]
network_vlan_ranges = provider
#
[ml2_type_vxlan]
#vni_ranges = VNI_START:VNI_END
vni_ranges = 1:1000
#
[securitygroup]
enable_ipset = true
```

- 데이터베이스
```
su -s /bin/sh -c "neutron-db-manage --config-file /etc/neutron/neutron.conf \
  --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head" neutron
```



- 네트워크노드 설정
```
ovs-vsctl add-br br-provider
#ovs-vsctl add-port br-provider PROVIDER_INTERFACE
ovs-vsctl add-port br-provider eth0
```

- openvswitch_agent 수정
```
cp /etc/neutron/plugins/ml2/openvswitch_agent.ini /etc/neutron/plugins/ml2/openvswitch_agent.ini.org
c
>
[ovs]
bridge_mappings = provider:br-provider
#local_ip = OVERLAY_INTERFACE_IP_ADDRESS
local_ip = 192.168.1.5
#
[agent]
tunnel_types = vxlan
l2_population = True
#
[securitygroup]
firewall_driver = iptables_hybrid
#
# 아래는 확인 필요
#[vxlan]
#enable_vxlan = true
#local_ip = OVERLAY_INTERFACE_IP_ADDRESS
#l2_population = true
#
#sysctl net.bridge.bridge-nf-call-iptables
#sysctl net.bridge.bridge-nf-call-ip6tables
```

- l3_agent.ini 수정
```
cp /etc/neutron/l3_agent.ini /etc/neutron/l3_agent.ini.org
vi /etc/neutron/l3_agent.ini
>
[DEFAULT]
interface_driver = openvswitch
```



---

## Configure the metadata agent - Controller

```
cp /etc/neutron/metadata_agent.ini /etc/neutron/metadata_agent.ini.org
vi /etc/neutron/metadata_agent.ini
>
[DEFAULT]
nova_metadata_host = controller
#metadata_proxy_shared_secret = METADATA_SECRET
metadata_proxy_shared_secret = stack
```

## Configure the Compute service to use the Networking service : controller

```
cp /etc/nova/nova.conf /etc/nova/nova.conf.org
vi /etc/nova/nova.conf
>
[neutron]
auth_url = http://controller:5000
auth_type = password
project_domain_name = default
user_domain_name = default
region_name = RegionOne
project_name = service
username = neutron
#password = NEUTRON_PASS
password = stack
service_metadata_proxy = true
#metadata_proxy_shared_secret = METADATA_SECRET
metadata_proxy_shared_secret = stack
```

## Finalize installation : controller
```
su -s /bin/sh -c "neutron-db-manage --config-file /etc/neutron/neutron.conf \
  --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head" neutron

service nova-api restart
service neutron-server restart
service neutron-openvswitch-agent restart
service neutron-dhcp-agent restart
service neutron-metadata-agent restart
service neutron-l3-agent restart
```

- #참고사항
```
sed -i 's/#net.ipv4.conf.default.rp_filter=1/net.ipv4.conf.default.rp_filter=0/g' /etc/sysctl.conf
sed -i 's/#net.ipv4.conf.all.rp_filter=1/net.ipv4.conf.all.rp_filter=0/g' /etc/sysctl.conf
sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' /etc/sysctl.conf

```


---


## Compute node
- OVS설치
```
apt install -y openvswitch-switch neutron-openvswitch-agent
```

- neutron.conf
```
cp /etc/neutron/neutron.conf /etc/neutron/neutron.conf.org
vi /etc/neutron/neutron.conf
>
[DEFAULT]
#transport_url = rabbit://openstack:RABBIT_PASS@controller
transport_url = rabbit://openstack:stack@controller
service_plugins = router
allow_overlapping_ips = True
#
[keystone_authtoken]
www_authenticate_uri = http://controller:5000
auth_url = http://controller:5000
memcached_servers = controller:11211
auth_type = password
project_domain_name = default
user_domain_name = default
project_name = service
username = neutron
#password = NEUTRON_PASS
password = stack
[oslo_concurrency]
lock_path = /var/lib/neutron/tmp
```

- openvswitch_agent 수정
```
cp /etc/neutron/plugins/ml2/openvswitch_agent.ini /etc/neutron/plugins/ml2/openvswitch_agent.ini.org
vi /etc/neutron/plugins/ml2/openvswitch_agent.ini
>
[ovs]
bridge_mappings = provider:br-provider
#local_ip = OVERLAY_INTERFACE_IP_ADDRESS
local_ip = 192.168.1.6
[securitygroup]
firewall_driver = iptables_hybrid
[agent]
tunnel_types = vxlan
l2_population = True
```

- dhcp_agent.ini 수정
```
cp /etc/neutron/dhcp_agent.ini /etc/neutron/dhcp_agent.ini.org
vi /etc/neutron/dhcp_agent.ini
>
[DEFAULT]
interface_driver = openvswitch
enable_isolated_metadata = True
force_metadata = True
```


- metadata_agent.ini
```
cp /etc/neutron/metadata_agent.ini /etc/neutron/metadata_agent.ini.org
vi /etc/neutron/metadata_agent.ini
>
[DEFAULT]
nova_metadata_host = controller
#metadata_proxy_shared_secret = METADATA_SECRET
metadata_proxy_shared_secret = stack
```

- ovs
```
ovs-vsctl add-br br-provider
#ovs-vsctl add-port br-provider PROVIDER_INTERFACE
ovs-vsctl add-port br-provider eth0
```

## Configure the Compute service to use the Networking service : compute
```
cp /etc/nova/nova.conf /etc/nova/nova.conf.org
vi /etc/nova/nova.conf
>
[neutron]
auth_url = http://controller:5000
auth_type = password
project_domain_name = default
user_domain_name = default
region_name = RegionOne
project_name = service
username = neutron
#password = NEUTRON_PASS
password = stack
```


- 다음 서비스를 시작합니다.
    - OVS 에이전트
    - DHCP 에이전트
    - 메타데이터 에이전트


## 서비스 확인
```
openstack network agent list
```

## 공급자 네트워크를 업데이트
```
. admin-openrc
openstack network set --external provider1
```

## Finalize installation
```
service nova-compute restart
service neutron-openvswitch-agent restart
```