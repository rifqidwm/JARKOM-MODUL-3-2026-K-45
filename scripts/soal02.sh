#!/bin/sh

if [ "$(hostname)" != "tengen" ]; then
  echo "Skrip ini dijalankan di tengen."
  exit 1
fi

apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y isc-dhcp-server

sed -i 's/^INTERFACESv4=.*/INTERFACESv4="eth0"/' /etc/default/isc-dhcp-server

cat > /etc/dhcp/dhcpd.conf <<'EOF'
authoritative;
default-lease-time 600;
max-lease-time 7200;

# Network 4 (lokal tengen), tanpa pool dinamis
subnet 10.86.4.0 netmask 255.255.255.0 {
}

# Network 2 (Divisi A), sementara, dipecah jadi 2 pool di soal 4
subnet 10.86.2.0 netmask 255.255.255.0 {
    range 10.86.2.10 10.86.2.35;
    option routers 10.86.2.1;
    option subnet-mask 255.255.255.0;
    option broadcast-address 10.86.2.255;
    option domain-name-servers 192.168.122.1;
}

# Network 3 (Divisi B), sementara, dipecah jadi short/long lease di soal 5
subnet 10.86.3.0 netmask 255.255.255.0 {
    range 10.86.3.10 10.86.3.89;
    option routers 10.86.3.1;
    option subnet-mask 255.255.255.0;
    option broadcast-address 10.86.3.255;
    option domain-name-servers 192.168.122.1;
}
EOF

service isc-dhcp-server stop
: > /var/lib/dhcp/dhcpd.leases
rm -f /var/lib/dhcp/dhcpd.leases~
grep INTERFACESv4 /etc/default/isc-dhcp-server
dhcpd -t -cf /etc/dhcp/dhcpd.conf

service isc-dhcp-server stop
timeout 3 dhcpd -4 -d -cf /etc/dhcp/dhcpd.conf eth0 2>&1 | grep -E "Listening|No subnet|Sending"
service isc-dhcp-server start
service isc-dhcp-server status
ss -ulnp | grep ':67'
