#!/bin/sh
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y mariadb-server

# Konfigurasi my.cnf untuk Master GTID
cat > /etc/mysql/mariadb.conf.d/replication.cnf << 'EOF'
[mysqld]
server-id = 1
log-bin = mysql-bin
gtid-domain-id = 1
log-slave-updates = ON
enforce-storage-engine = InnoDB
bind-address = 0.0.0.0
EOF

systemctl restart mariadb

# Buat User Replicator
mysql -u root -e "
CREATE USER 'replicator'@'%' IDENTIFIED BY 'k45pass';
GRANT REPLICATION SLAVE ON *.* TO 'replicator'@'%';
FLUSH PRIVILEGES;
"
