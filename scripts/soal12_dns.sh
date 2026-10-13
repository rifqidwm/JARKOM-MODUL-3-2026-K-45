#!/bin/sh
cat > /etc/bind/jujutsu/jujutsu.k45.com << 'EOF'
$TTL    604800
@       IN      SOA     jujutsu.k45.com. root.jujutsu.k45.com. (
                              2         ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                         604800 )       ; Negative Cache TTL

@       IN      NS      utahime.jujutsu.k45.com.
@       IN      A       10.86.4.8       # IP Load Balancer / Geto / Gateway

utahime IN      A       10.86.4.x       # IP utahime
shoko   IN      A       10.86.4.x       # IP shoko
yaga    IN      A       10.86.4.8       # IP yaga (DB Master)
nanami  IN      A       10.86.4.5       # IP nanami
todo    IN      A       10.86.4.6       # IP todo
geto    IN      A       10.86.4.x       # IP geto (LB)
www     IN      CNAME   jujutsu.k45.com.
EOF

named-checkzone jujutsu.k45.com /etc/bind/jujutsu/jujutsu.k45.com
systemctl restart bind9
