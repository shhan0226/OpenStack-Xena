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
echo "Install Controller for OpenStack ..."
# Inpute Value
H_NAMEv="controller"
SET_IPv="192.168.1.5"
SET_IP2v="192.168.1.6"
SET_IP_ALLOWv="192.168.0.0/22"
INTERFACE_NAME_v="eth0"
STACK_PASSWDv="stack"
# INPUT DATA PRINT
echo "$H_NAME"
echo "$SET_IP"
echo "$SET_IP2"
echo "$SET_IP_ALLOW"
echo "$INTERFACE_NAME_"
echo "$STACK_PASSWD"
echo "... set!!"
##################################
# config /etc/hosts
##################################
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
apt install -y chrony
echo "server controller iburst" >> /etc/chrony/chrony.conf	
echo "allow $SET_IP_ALLOW" >> /etc/chrony/chrony.conf
sudo service chrony restart
##################################
# Install Openstack Client
##################################
add-apt-repository cloud-archive:xena -y
sudo apt install -y python3-openstackclient
##################################
# SQL database for Ubuntu
##################################
sudo apt install -y mariadb-server python3-pymysql
crudini --set /etc/mysql/mariadb.conf.d/99-openstack.cnf mysqld bind-address $SET_IP 
crudini --set /etc/mysql/mariadb.conf.d/99-openstack.cnf mysqld default-storage-engine innodb
crudini --set /etc/mysql/mariadb.conf.d/99-openstack.cnf mysqld innodb_file_per_table on
crudini --set /etc/mysql/mariadb.conf.d/99-openstack.cnf mysqld max_connections 4096
crudini --set /etc/mysql/mariadb.conf.d/99-openstack.cnf mysqld collation-server utf8_general_ci
crudini --set /etc/mysql/mariadb.conf.d/99-openstack.cnf mysqld character-set-server utf8
service mysql restart
echo -e "\ny\ny\nstack\nstack\ny\ny\ny\ny" | mysql_secure_installation
sync
##################################
# Message queue for Ubuntu
##################################
apt install -y rabbitmq-server
rabbitmqctl add_user openstack stack
rabbitmqctl set_permissions openstack ".*" ".*" ".*"
##################################
# Memcached for Ubuntu
##################################
apt install -y memcached python3-memcache
sed -i s/127.0.0.1/${SET_IP}/ /etc/memcached.conf
service memcached restart
##################################
# Etcd for Ubuntu
##################################
wget https://github.com/etcd-io/etcd/releases/download/v3.4.1/etcd-v3.4.1-linux-arm64.tar.gz
tar -xvf etcd-v3.4.1-linux-arm64.tar.gz
sudo cp etcd-v3.4.1-linux-arm64/etcd* /usr/bin/
sudo groupadd --system etcd
sudo useradd --home-dir "/var/lib/etcd" \
        --system \
        --shell /bin/false \
        -g etcd \
        etcd
sudo mkdir -p /etc/etcd
sudo chown etcd:etcd /etc/etcd
sudo mkdir -p /var/lib/etcd
sudo chown etcd:etcd /var/lib/etcd
touch /etc/etcd/etcd.conf.yml
echo "name: controller" >> /etc/etcd/etcd.conf.yml
echo "data-dir: /var/lib/etcd" >> /etc/etcd/etcd.conf.yml
echo "initial-cluster-state: 'new'" >> /etc/etcd/etcd.conf.yml
echo "initial-cluster-token: 'etcd-cluster-01'" >> /etc/etcd/etcd.conf.yml
echo "initial-cluster: controller=http://${SET_IP}:2380" >> /etc/etcd/etcd.conf.yml
echo "initial-advertise-peer-urls: http://${SET_IP}:2380" >> /etc/etcd/etcd.conf.yml
echo "advertise-client-urls: http://${SET_IP}:2379" >> /etc/etcd/etcd.conf.yml
echo "listen-peer-urls: http://0.0.0.0:2380" >> /etc/etcd/etcd.conf.yml
echo "listen-client-urls: http://${SET_IP}:2379" >> /etc/etcd/etcd.conf.yml
touch /lib/systemd/system/etcd.service
echo "[Unit]" >> /lib/systemd/system/etcd.service
echo "Description=etcd - highly-available key value store">> /lib/systemd/system/etcd.service
echo "Documentation=https://github.com/coreos/etcd" >> /lib/systemd/system/etcd.service
echo "Documentation=man:etcd" >> /lib/systemd/system/etcd.service
echo "After=network.target" >> /lib/systemd/system/etcd.service
echo "Wants=network-online.target" >> /lib/systemd/system/etcd.service
echo " " >> /lib/systemd/system/etcd.service
echo "[Service]" >> /lib/systemd/system/etcd.service
echo "Environment=DAEMON_ARGS=" >> /lib/systemd/system/etcd.service
echo "Environment=ETCD_NAME=%H" >> /lib/systemd/system/etcd.service
echo "Environment=ETCD_DATA_DIR=/vara/lib/etcd/default" >> /lib/systemd/system/etcd.service
echo "Environment=\"ETCD_UNSUPPORTED_ARCH=arm64\"" >> /lib/systemd/system/etcd.service
echo "EnvironmentFile=-/etc/default/%p" >> /lib/systemd/system/etcd.service
echo "Type=notify" >> /lib/systemd/system/etcd.service
echo "User=etcd" >> /lib/systemd/system/etcd.service
echo "PermissionsStartOnly=true" >> /lib/systemd/system/etcd.service
echo "ExecStart=/usr/bin/etcd --config-file /etc/etcd/etcd.conf.yml" >> /lib/systemd/system/etcd.service
echo "Restart=on-abnormal" >> /lib/systemd/system/etcd.service
echo "LimitNOFILE=65536" >> /lib/systemd/system/etcd.service
echo " " >> /lib/systemd/system/etcd.service
echo "[Install]" >> /lib/systemd/system/etcd.service
echo "WantedBy=multi-user.target" >> /lib/systemd/system/etcd.service
echo "Alias=etcd2.service" >> /lib/systemd/system/etcd.service
sync
sudo systemctl daemon-reload
sudo systemctl enable etcd
sudo systemctl restart etcd	
##################################
# Version Check
##################################
openstack --version
python --version
pip --version
service --status-all|grep +
##################################
# Keystone
##################################
echo "Keystone !!"
echo "Keystone CREATE DB ..."
mysql -e "CREATE DATABASE keystone;"
mysql -e "GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost' IDENTIFIED BY '${STACK_PASSWD}';"
mysql -e "GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' IDENTIFIED BY '${STACK_PASSWD}';"
mysql -e "FLUSH PRIVILEGES;"
echo "Keystone Install ..."
apt install -y keystone
crudini --set /etc/keystone/keystone.conf database connection mysql+pymysql://keystone:${STACK_PASSWD}@controller/keystone
crudini --set /etc/keystone/keystone.conf token provider fernet
echo "Keystone Reg DB ..."
su -s /bin/sh -c "keystone-manage db_sync" keystone
keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone
keystone-manage credential_setup --keystone-user keystone --keystone-group keystone
keystone-manage bootstrap --bootstrap-password ${STACK_PASSWD} \
  --bootstrap-admin-url http://controller:5000/v3/ \
  --bootstrap-internal-url http://controller:5000/v3/ \
  --bootstrap-public-url http://controller:5000/v3/ \
  --bootstrap-region-id RegionOne
echo "Keystone - Apache HTTP server ..."
echo "ServerName controller" >> /etc/apache2/apache2.conf
service apache2 restart
export OS_USERNAME=admin
export OS_PASSWORD=${STACK_PASSWD}
export OS_PROJECT_NAME=admin
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_DOMAIN_NAME=Default
export OS_AUTH_URL=http://controller:5000/v3
export OS_IDENTITY_API_VERSION=3
##################################
# admin-openrc
##################################
cat > admin-openrc << EOF
export OS_PROJECT_DOMAIN_NAME=Default
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_NAME=admin
export OS_USERNAME=admin
export OS_PASSWORD=stack
export OS_AUTH_URL=http://controller:5000/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2
EOF
cat > demo-openrc << EOF
export OS_PROJECT_DOMAIN_NAME=Default
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_NAME=myproject
export OS_USERNAME=myuser
export OS_PASSWORD=stack
export OS_AUTH_URL=http://controller:5000/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2
EOF
. admin-openrc
##################################
# Keystone 
##################################
echo "Keystone - domain, projects, users, and roles ..."
openstack domain create --description "An Example Domain" example
openstack project create --domain default \
  --description "Service Project" service
openstack project create --domain default \
  --description "Demo Project" myproject
openstack user create --domain default \
  --password ${STACK_PASSWD} myuser
openstack role create myrole
openstack role add --project myproject --user myuser myrole
echo "Keystone Verify operation ..."
. admin-openrc
openstack token issue
##################################
# Glance
##################################
echo "Glance !!"
echo "Glance CREATE DB ..."
mysql -e "CREATE DATABASE glance;"
mysql -e "GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'localhost' IDENTIFIED BY '${STACK_PASSWD}';"
mysql -e "GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'%' IDENTIFIED BY '${STACK_PASSWD}';"
mysql -e "FLUSH PRIVILEGES;"
echo "Glance CREATE SERVICE ..."
. admin-openrc
openstack user create --domain default --password ${STACK_PASSWD} glance
openstack role add --project service --user glance admin
openstack service create --name glance \
  --description "OpenStack Image" image
echo "Glance - Create the Image service API endpoints ..."
openstack endpoint create --region RegionOne \
  image public http://controller:9292
openstack endpoint create --region RegionOne \
  image internal http://controller:9292
openstack endpoint create --region RegionOne \
  image admin http://controller:9292
echo "Glance Install ..."
apt install -y glance
crudini --set /etc/glance/glance-api.conf database connection mysql+pymysql://glance:${STACK_PASSWD}@controller/glance
crudini --set /etc/glance/glance-api.conf keystone_authtoken www_authenticate_uri http://controller:5000
crudini --set /etc/glance/glance-api.conf keystone_authtoken auth_url http://controller:5000
crudini --set /etc/glance/glance-api.conf keystone_authtoken memcached_servers controller:11211
crudini --set /etc/glance/glance-api.conf keystone_authtoken auth_type password
crudini --set /etc/glance/glance-api.conf keystone_authtoken project_domain_name Default
crudini --set /etc/glance/glance-api.conf keystone_authtoken user_domain_name Default
crudini --set /etc/glance/glance-api.conf keystone_authtoken project_name service
crudini --set /etc/glance/glance-api.conf keystone_authtoken username glance
crudini --set /etc/glance/glance-api.conf keystone_authtoken password ${STACK_PASSWD}
crudini --set /etc/glance/glance-api.conf paste_deploy flavor keystone
crudini --set /etc/glance/glance-api.conf glance_store stores file,http
crudini --set /etc/glance/glance-api.conf glance_store default_store file
crudini --set /etc/glance/glance-api.conf glance_store filesystem_store_datadir /var/lib/glance/images/
echo "Glance Reg. DB ..."
su -s /bin/sh -c "glance-manage db_sync" glance
service glance-api restart
echo "Glance Verify operation ..."
sync
. admin-openrc
wget https://download.cirros-cloud.net/0.4.0/cirros-0.4.0-aarch64-disk.img
##################################
# Placement
##################################
echo "Placement !!"
mysql -e "CREATE DATABASE placement;"
mysql -e "GRANT ALL PRIVILEGES ON placement.* TO 'placement'@'localhost' IDENTIFIED BY '${STACK_PASSWD}';"
mysql -e "GRANT ALL PRIVILEGES ON placement.* TO 'placement'@'%' IDENTIFIED BY '${STACK_PASSWD}';"
mysql -e "FLUSH PRIVILEGES;"
echo "Placement CREATE DB ..."
openstack user create --domain default --password ${STACK_PASSWD} placement
openstack role add --project service --user placement admin
openstack service create --name placement \
  --description "Placement API" placement
openstack endpoint create --region RegionOne \
  placement public http://controller:8778
openstack endpoint create --region RegionOne \
  placement internal http://controller:8778
openstack endpoint create --region RegionOne \
  placement admin http://controller:8778
echo "Placement Install ..."
apt install -y placement-api
crudini --set /etc/placement/placement.conf placement_database connection mysql+pymysql://placement:${STACK_PASSWD}@controller/placement 
crudini --set /etc/placement/placement.conf api auth_strategy keystone
crudini --set /etc/placement/placement.conf keystone_authtoken auth_url http://controller:5000/v3
crudini --set /etc/placement/placement.conf keystone_authtoken memcached_servers controller:11211
crudini --set /etc/placement/placement.conf keystone_authtoken auth_type password
crudini --set /etc/placement/placement.conf keystone_authtoken project_domain_name Default
crudini --set /etc/placement/placement.conf keystone_authtoken user_domain_name Default
crudini --set /etc/placement/placement.conf keystone_authtoken project_name service
crudini --set /etc/placement/placement.conf keystone_authtoken username placement 
crudini --set /etc/placement/placement.conf keystone_authtoken password ${STACK_PASSWD}
echo "Placement - python (option)"
su -s /bin/sh -c "placement-manage db sync" placement
service apache2 restart
echo "Placement Verify operation ..."
. admin-openrc
placement-status upgrade check
pip3 install osc-placement
openstack --os-placement-api-version 1.2 resource class list --sort-column name
openstack --os-placement-api-version 1.6 trait list --sort-column name
##################################
# Nova
##################################
echo "NOVA !!"
echo "CREATE DB ..."
mysql -e "CREATE DATABASE nova_api;"
mysql -e "CREATE DATABASE nova;"
mysql -e "CREATE DATABASE nova_cell0;"
mysql -e "GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'localhost' IDENTIFIED BY '${STACK_PASSWD}';"
mysql -e "GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'%' IDENTIFIED BY '${STACK_PASSWD}';"
mysql -e "GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'localhost' IDENTIFIED BY '${STACK_PASSWD}';"
mysql -e "GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'%' IDENTIFIED BY '${STACK_PASSWD}';"
mysql -e "GRANT ALL PRIVILEGES ON nova_cell0.* TO 'nova'@'localhost' IDENTIFIED BY '${STACK_PASSWD}';"
mysql -e "GRANT ALL PRIVILEGES ON nova_cell0.* TO 'nova'@'%' IDENTIFIED BY '${STACK_PASSWD}';"
mysql -e "FLUSH PRIVILEGES;"
echo "NOVA CREATE SERVICE ..."
. admin-openrc
openstack user create --domain default --password ${STACK_PASSWD} nova
openstack role add --project service --user nova admin
openstack service create --name nova \
  --description "OpenStack Compute" compute
openstack endpoint create --region RegionOne \
  compute public http://controller:8774/v2.1
openstack endpoint create --region RegionOne \
  compute internal http://controller:8774/v2.1
openstack endpoint create --region RegionOne \
  compute admin http://controller:8774/v2.1
echo "NOVA Install ..."
apt install -y nova-api nova-conductor nova-novncproxy nova-scheduler 
crudini --set /etc/nova/nova.conf api_database connection mysql+pymysql://nova:${STACK_PASSWD}@controller/nova_api
crudini --set /etc/nova/nova.conf database connection mysql+pymysql://nova:${STACK_PASSWD}@controller/nova
crudini --set /etc/nova/nova.conf DEFAULT transport_url rabbit://openstack:${STACK_PASSWD}@controller:5672/
crudini --set /etc/nova/nova.conf DEFAULT my_ip ${SET_IP}
crudini --set /etc/nova/nova.conf api auth_strategy keystone
crudini --set /etc/nova/nova.conf keystone_authtoken www_authenticate_uri http://controller:5000/
crudini --set /etc/nova/nova.conf keystone_authtoken auth_url http://controller:5000/
crudini --set /etc/nova/nova.conf keystone_authtoken memcached_servers controller:11211
crudini --set /etc/nova/nova.conf keystone_authtoken auth_type password
crudini --set /etc/nova/nova.conf keystone_authtoken project_domain_name Default
crudini --set /etc/nova/nova.conf keystone_authtoken user_domain_name Default
crudini --set /etc/nova/nova.conf keystone_authtoken project_name service
crudini --set /etc/nova/nova.conf keystone_authtoken username nova
crudini --set /etc/nova/nova.conf keystone_authtoken password ${STACK_PASSWD}
crudini --set /etc/nova/nova.conf vnc enabled true
crudini --set /etc/nova/nova.conf vnc server_listen \$my_ip
crudini --set /etc/nova/nova.conf vnc server_proxyclient_address\$my_ip
crudini --set /etc/nova/nova.conf glance api_servers http://controller:9292
crudini --set /etc/nova/nova.conf oslo_concurrency lock_path /var/lib/nova/tmp
crudini --set /etc/nova/nova.conf placement region_name RegionOne
crudini --set /etc/nova/nova.conf placement project_domain_name Default
crudini --set /etc/nova/nova.conf placement project_name service
crudini --set /etc/nova/nova.conf placement auth_type password
crudini --set /etc/nova/nova.conf placement user_domain_name Default
crudini --set /etc/nova/nova.conf placement auth_url http://controller:5000/v3
crudini --set /etc/nova/nova.conf placement username placement
crudini --set /etc/nova/nova.conf placement password ${STACK_PASSWD}
echo "NOVA Reg. DB ..."
su -s /bin/sh -c "nova-manage api_db sync" nova
su -s /bin/sh -c "nova-manage cell_v2 map_cell0" nova
su -s /bin/sh -c "nova-manage cell_v2 create_cell --name=cell1 --verbose" nova
su -s /bin/sh -c "nova-manage db sync" nova
su -s /bin/sh -c "nova-manage cell_v2 list_cells" nova
echo "NOVA Verify operation ..."
service nova-api restart
service nova-scheduler restart
service nova-conductor restart
service nova-novncproxy restart
##################################
# nova check
##################################
sync
openstack compute service list --service nova-compute
su -s /bin/sh -c "nova-manage cell_v2 discover_hosts --verbose" nova
crudini --set /etc/nova/nova.conf scheduler discover_hosts_in_cells_interval 300
echo "NOVA Verify operation"
. admin-openrc
openstack compute service list
openstack catalog list
openstack image list
nova-status upgrade check
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
  network public http://controller:9696
openstack endpoint create --region RegionOne \
  network internal http://controller:9696
openstack endpoint create --region RegionOne \
  network admin http://controller:9696  
echo "Networking Option 2: Self-service networks"
apt install -y neutron-server neutron-plugin-ml2 \
  neutron-linuxbridge-agent neutron-l3-agent neutron-dhcp-agent \
  neutron-metadata-agent
crudini --set /etc/neutron/neutron.conf database connection mysql+pymysql://neutron:${STACK_PASSWD}@controller/neutron
crudini --set /etc/neutron/neutron.conf DEFAULT core_plugin ml2
crudini --set /etc/neutron/neutron.conf DEFAULT service_plugins router
crudini --set /etc/neutron/neutron.conf DEFAULT allow_overlapping_ips true
crudini --set /etc/neutron/neutron.conf DEFAULT transport_url rabbit://openstack:${STACK_PASSWD}@controller
crudini --set /etc/neutron/neutron.conf DEFAULT auth_strategy keystone
crudini --set /etc/neutron/neutron.conf DEFAULT notify_nova_on_port_status_changes true
crudini --set /etc/neutron/neutron.conf DEFAULT notify_nova_on_port_data_changes true
crudini --set /etc/neutron/neutron.conf keystone_authtoken www_authenticate_uri http://controller:5000
crudini --set /etc/neutron/neutron.conf keystone_authtoken auth_url http://controller:5000
crudini --set /etc/neutron/neutron.conf keystone_authtoken memcached_servers controller:11211
crudini --set /etc/neutron/neutron.conf keystone_authtoken auth_type password
crudini --set /etc/neutron/neutron.conf keystone_authtoken project_domain_name default
crudini --set /etc/neutron/neutron.conf keystone_authtoken user_domain_name default
crudini --set /etc/neutron/neutron.conf keystone_authtoken project_name service
crudini --set /etc/neutron/neutron.conf keystone_authtoken username neutron
crudini --set /etc/neutron/neutron.conf keystone_authtoken password ${STACK_PASSWD}
crudini --set /etc/neutron/neutron.conf nova auth_url http://controller:5000
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
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 mechanism_drivers linuxbridge,l2population
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 extension_drivers port_security
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2_type_flat flat_networks provider
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2_type_vxlan vni_ranges 1:1000
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini securitygroup enable_ipset true
crudini --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini linux_bridge physical_interface_mappings provider:${INTERFACE_NAME_}
crudini --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini vxlan enable_vxlan true
crudini --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini vxlan local_ip ${SET_IP}
crudini --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini vxlan l2_population true
crudini --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini securitygroup enable_security_group true
crudini --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini securitygroup firewall_driver neutron.agent.linux.iptables_firewall.IptablesFirewallDriver
sysctl net.bridge.bridge-nf-call-iptables
sysctl net.bridge.bridge-nf-call-ip6tables
echo "Configure the layer-3 agent"
crudini --set /etc/neutron/l3_agent.ini DEFAULT interface_driver linuxbridge
echo "DHCP agent config"
crudini --set /etc/neutron/dhcp_agent.ini DEFAULT interface_driver linuxbridge
crudini --set /etc/neutron/dhcp_agent.ini DEFAULT dhcp_driver neutron.agent.linux.dhcp.Dnsmasq
crudini --set /etc/neutron/dhcp_agent.ini DEFAULT enable_isolated_metadata true
echo "Configure the metadata agent"
crudini --set /etc/neutron/metadata_agent.ini DEFAULT nova_metadata_host controller
crudini --set /etc/neutron/metadata_agent.ini DEFAULT metadata_proxy_shared_secret ${STACK_PASSWD}
crudini --set /etc/nova/nova.conf neutron auth_url http://controller:5000
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
service neutron-linuxbridge-agent restart
service neutron-dhcp-agent restart
service neutron-metadata-agent restart
service neutron-l3-agent restart
##################################
# Horizon
##################################
apt install -y openstack-dashboard
cp /etc/openstack-dashboard/local_settings.py /etc/openstack-dashboard/local_settings.py.backup
sed -i "s/OPENSTACK_HOST = \"127.0.0.1\"/OPENSTACK_HOST = \"${SET_IP}\"/" /etc/openstack-dashboard/local_settings.py
sed -i "s/'LOCATION': '127.0.0.1:11211',/'LOCATION': '${SET_IP}:11211',/" /etc/openstack-dashboard/local_settings.py
sed -i 's/http:\/\/\%s\/identity\/v3/http:\/\/\%s:5000\/v3/' /etc/openstack-dashboard/local_settings.py
sed -i 's/TIME_ZONE = "UTC"/TIME_ZONE = "Asia\/Seoul"/' /etc/openstack-dashboard/local_settings.py
echo "SESSION_ENGINE = 'django.contrib.sessions.backends.cache'" >> /etc/openstack-dashboard/local_settings.py
systemctl reload apache2.service