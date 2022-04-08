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