#!/bin/sh
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y bind9 bind9utils

cat > /etc/bind/named.conf.local << 'EOF'
zone "jujutsu.k45.com" {
    type slave;
    file "/var/cache/bind/jujutsu.k45.com";
    masters { 10.86.4.x; }; # IP utahime (master)
};
EOF

systemctl restart bind9
