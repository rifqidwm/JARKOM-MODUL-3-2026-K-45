#!/bin/sh

[ "$(hostname)" = "tengen" ] || { echo "[soal02] jalankan di tengen"; exit 1; }

export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y isc-dhcp-server

# DHCP Server hanya mendengarkan eth0 (Network 4)
sed -i 's/^INTERFACESv4=.*/INTERFACESv4="eth0"/' /etc/default/isc-dhcp-server
grep INTERFACESv4 /etc/default/isc-dhcp-server

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

touch /var/lib/dhcp/dhcpd.leases
dhcpd -t -cf /etc/dhcp/dhcpd.conf || { echo "ERROR: dhcpd.conf tidak valid"; exit 1; }

# bukti: tidak ada pesan "No subnet declaration" (jalan di foreground 3 detik)
service isc-dhcp-server stop 2>/dev/null
echo "--- dhcpd foreground (3 detik) ---"
timeout 3 dhcpd -4 -d -cf /etc/dhcp/dhcpd.conf eth0 2>&1 | grep -E "Listening|No subnet|Sending"
echo "----------------------------------"

service isc-dhcp-server restart
service isc-dhcp-server status | head -5
ss -ulnp | grep ':67'
