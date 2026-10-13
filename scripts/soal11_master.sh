#!/bin/sh
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y bind9 bind9utils

# Konfigurasi named.conf.options (Forwarder)
cat > /etc/bind/named.conf.options << 'EOF'
options {
    directory "/var/cache/bind";
    forwarders {
        8.8.8.8;
        1.1.1.1;
    };
    dnssec-validation auto;
    listen-on { any; };
    allow-query { any; };
    allow-transfer { 10.86.4.x; }; # IP node shoko (slave)
};
EOF

# Konfigurasi named.conf.local
cat > /etc/bind/named.conf.local << 'EOF'
zone "jujutsu.k45.com" {
    type master;
    file "/etc/bind/jujutsu/jujutsu.k45.com";
    allow-transfer { 10.86.4.x; }; # IP shoko
};
EOF

mkdir -p /etc/bind/jujutsu
systemctl restart bind9
