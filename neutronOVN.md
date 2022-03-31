#neutronOVN

## Prerequisites
- vlan, bridge 설치
  ```
  sudo apt install vlan bridge-utils
  ```
- 라우팅 :모든 인터페이스는 IP4트래픽을 전달
  ```
  vi /etc/sysctl.conf
  >
  net.ipv4.conf.default.rp_filter=0
  net.ipv4.conf.all.rp_filter=0
  net.ipv4.ip_forward=1
  ```
- Open vSwitch 설치
  - [참고](https://www.xmodulo.com/install-configure-kvm-open-vswitch-ubuntu-debian.html)
  ```
  sudo apt-get install -y openvswitch-switch
  ```
- OVS 커널 모듈 확인
  ```
  sudo lsmod | grep openvswitch
  ```
- DKMS 모듈(오버레이가 없을경우; 선택사항)
  ```
  sudo apt-get -y install openvswitch-datapath-dkms
  ```
- 내부 OVS브리지 구성하기
  ```
  sudo ovs-vsctl add-br br-int
  ```



---

## Controller Node

1. openvswitch-ovn및 networking-ovn패키지 를 설치
2. OVS 서비스를 시작

systemctl start openvswitch
# ovn-ctl스크립트 사용할 경우
/usr/share/openvswitch/scripts/ovs-ctl start  --system-id="random"

3. ovsdb-server요소를 구성
ovsdb-server 서비스는 Unix 소켓을 통한 데이터베이스에 대한 로컬 액세스만 허용
원격 데이터베이스 액세스를 허용

# 0.0.0.0은 컨트롤 노드 인터페이스
ovn-nbctl set-connection ptcp:6641:0.0.0.0 -- \
    set connection . inactivity_probe=60000
ovn-sbctl set-connection ptcp:6642:0.0.0.0 -- \
    set connection . inactivity_probe=60000
# if using the VTEP functionality:
ovs-appctl -t ovsdb-server ovsdb-server/add-remote ptcp:6640:0.0.0.0

4.  ovn-northd 서비스 시작
systemctl start ovn-northd

# ovn-ctl스크립트 사용할 경우
/usr/share/openvswitch/scripts/ovn-ctl start_northd

start_northd 에 대한 옵션
# /usr/share/openvswitch/scripts/ovn-ctl start_northd --help
# ...
# DB_NB_SOCK="/usr/local/etc/openvswitch/nb_db.sock"
# DB_NB_PID="/usr/local/etc/openvswitch/ovnnb_db.pid"
# DB_SB_SOCK="usr/local/etc/openvswitch/sb_db.sock"
# DB_SB_PID="/usr/local/etc/openvswitch/ovnsb_db.pid"
# ...

5. 네트워킹 서버 구성 요소를 구성
vi /etc/neutron/neutron.conf
>
[DEFAULT]
core_plugin = ml2
service_plugins = ovn-router

6. ML2 플러그인을 구성
vi /etc/neutron/plugins/ml2/ml2_conf.ini
>
[ml2]
...
mechanism_drivers = ovn
type_drivers = local,flat,vlan,geneve
tenant_network_types = geneve
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

[ovn]
...
ovn_nb_connection = tcp:IP_ADDRESS:6641
ovn_sb_connection = tcp:IP_ADDRESS:6642
ovn_l3_scheduler = OVN_L3_SCHEDULER


ovs-vsctl set open . external-ids:ovn-cms-options=enable-chassis-as-gw


## Compute node
1. openvswitch-ovn및 networking-ovn패키지 를 설치

2. OVS 서비스를 시작
systemctl start openvswitch
# ovs-ctl스크립트 사용할 경우:
/usr/share/openvswitch/scripts/ovs-ctl start --system-id="random"

3. OVS 서비스를 구성
ovs-vsctl set open . external-ids:ovn-remote=tcp:IP_ADDRESS:6642
ovs-vsctl set open . external-ids:ovn-encap-type=geneve,vxlan
ovs-vsctl set open . external-ids:ovn-encap-ip=IP_ADDRESS

4. ovn-controller서비스를 시작합니다 
systemctl start ovn-controller
# ovs-ctl스크립트 사용할 경우:
/usr/share/openvswitch/scripts/ovn-ctl start_controller

## 컴퓨트 노드에서 ovn-controller 인스턴스 확인
# ovn-sbctl show
  <output>