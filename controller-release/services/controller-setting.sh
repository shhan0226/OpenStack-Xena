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
read -p "Do you want to set up? {yes|no|ENTER=yes} " CHECKER_NO_
if [ "$CHECKER_NO_" = "no" ]; then
    exit 100
else
    echo "Keep Going!!"
fi
##################################
# config /etc/hosts
##################################
sudo apt install net-tools -y
ifconfig
echo "Set IP ...."
sed -i "s/127.0.1.1/\#127.0.1.1/" /etc/hosts
echo "$SET_IP $CONTROLLER_HOST" >> /etc/hosts
echo "$SET_IP2 $COMPUTE_HOST" >> /etc/hosts
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
echo "server $CONTROLLER_HOST iburst" >> /etc/chrony/chrony.conf	
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
echo "name: ${CONTROLLER_HOST}" >> /etc/etcd/etcd.conf.yml
echo "data-dir: /var/lib/etcd" >> /etc/etcd/etcd.conf.yml
echo "initial-cluster-state: 'new'" >> /etc/etcd/etcd.conf.yml
echo "initial-cluster-token: 'etcd-cluster-01'" >> /etc/etcd/etcd.conf.yml
echo "initial-cluster: ${CONTROLLER_HOST}=http://${SET_IP}:2380" >> /etc/etcd/etcd.conf.yml
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
