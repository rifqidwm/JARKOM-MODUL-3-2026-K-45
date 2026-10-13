#!/bin/sh
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y mariadb-server

cat > /etc/mysql/mariadb.conf.d/replication.cnf << 'EOF'
[mysqld]
server-id = 2
relay-log = mysql-relay-bin
gtid-domain-id = 1
log-slave-updates = ON
read-only = ON
bind-address = 0.0.0.0
EOF

systemctl restart mariadb

# Hubungkan Slave ke Master Yaga
mysql -u root -e "
CHANGE MASTER TO
  MASTER_HOST='10.86.4.8',
  MASTER_USER='replicator',
  MASTER_PASSWORD='k45pass',
  MASTER_USE_GTID=slave_pos;
START SLAVE;
"
