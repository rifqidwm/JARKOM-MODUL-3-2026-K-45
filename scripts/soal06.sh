#!/bin/sh

N=$(hostname)

case "$N" in
  tengen)
    service isc-dhcp-server stop
    . /root/macs.env
cat > /etc/dhcp/dhcpd.conf <<EOF
authoritative;
default-lease-time 600;
max-lease-time 7200;

# DNS dan domain untuk semua client (Network 2 dan 3)
option domain-name-servers 10.86.1.2, 10.86.1.3;
option domain-name "k45.com";
option domain-search "k45.com";

# Class Divisi A, dipisah berdasarkan Client ID (fallback MAC)
class "divisi-a-pool1" {
    match pick-first-value (option dhcp-client-identifier, hardware);
}
subclass "divisi-a-pool1" 1:$M_ITADORI;
subclass "divisi-a-pool1" 1:$M_FUSHIGURO;

class "divisi-a-pool2" {
    match pick-first-value (option dhcp-client-identifier, hardware);
}
subclass "divisi-a-pool2" 1:$M_ZENIN;
subclass "divisi-a-pool2" 1:$M_OKKOTSU;

# Class Divisi B
class "short-lease" {
    match pick-first-value (option dhcp-client-identifier, hardware);
}
subclass "short-lease" 1:$M_INO;
subclass "short-lease" 1:$M_KUSAKABE;

class "long-lease" {
    match pick-first-value (option dhcp-client-identifier, hardware);
}
subclass "long-lease" 1:$M_MIWA;

# Network 4 (lokal tengen), tanpa pool dinamis
subnet 10.86.4.0 netmask 255.255.255.0 {
}

# Network 2: dua pool
subnet 10.86.2.0 netmask 255.255.255.0 {
    option routers 10.86.2.1;
    option subnet-mask 255.255.255.0;
    option broadcast-address 10.86.2.255;

    pool {
        allow members of "divisi-a-pool1";
        range 10.86.2.10 10.86.2.35;
    }
    pool {
        allow members of "divisi-a-pool2";
        range 10.86.2.70 10.86.2.95;
    }
}

# Network 3: short lease dan long lease
subnet 10.86.3.0 netmask 255.255.255.0 {
    option routers 10.86.3.1;
    option subnet-mask 255.255.255.0;
    option broadcast-address 10.86.3.255;

    pool {
        allow members of "short-lease";
        range 10.86.3.10 10.86.3.89;
        default-lease-time 1800;
        max-lease-time 1800;
    }
    pool {
        allow members of "long-lease";
        range 10.86.3.100 10.86.3.199;
        default-lease-time 43200;
        max-lease-time 43200;
    }
}

# Static lease kugisaki (VIP), di luar semua pool
host kugisaki {
    hardware ethernet $M_KUGISAKI;
    fixed-address 10.86.3.99;
}
EOF
    dhcpd -t -cf /etc/dhcp/dhcpd.conf
    service isc-dhcp-server start
    grep -B1 -A3 "host kugisaki" /etc/dhcp/dhcpd.conf
    dhcpd -t -cf /etc/dhcp/dhcpd.conf
    ;;
  kugisaki)
    ip addr flush dev eth0
    udhcpc -i eth0 -n -q
    ip addr show dev eth0
    ip addr flush dev eth0
    udhcpc -i eth0 -n -q
    ip addr show dev eth0
    ip route
    ;;
  *)
    echo "Node $N bukan bagian dari soal 6."
    ;;
esac
