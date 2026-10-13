#!/bin/sh

N=$(hostname)
MODE=$1

case "$N" in
  tengen)
    case "$MODE" in
      macs)
        : > /root/macs.env
        echo M_ITADORI=02:42:97:40:66:00 >> /root/macs.env
        echo M_FUSHIGURO=02:42:c8:94:58:00 >> /root/macs.env
        echo M_ZENIN=02:42:3b:86:61:00 >> /root/macs.env
        echo M_OKKOTSU=02:42:27:fb:e9:00 >> /root/macs.env
        echo M_INO=02:42:14:fc:9c:00 >> /root/macs.env
        echo M_KUSAKABE=02:42:b9:59:6f:00 >> /root/macs.env
        echo M_MIWA=02:42:4a:27:87:00 >> /root/macs.env
        echo M_KUGISAKI=02:42:e7:23:fc:00 >> /root/macs.env
        cat /root/macs.env
        ;;
      leases)
        awk '/^lease/{ip=$2} /hardware ethernet/{gsub(";","",$3); print ip, $3}' /var/lib/dhcp/dhcpd.leases | sort -u
        ;;
      *)
        cat /root/macs.env
        service isc-dhcp-server stop
        : > /var/lib/dhcp/dhcpd.leases
        rm -f /var/lib/dhcp/dhcpd.leases~
        . /root/macs.env
cat > /etc/dhcp/dhcpd.conf <<EOF
authoritative;
default-lease-time 600;
max-lease-time 7200;

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

# Network 4 (lokal tengen), tanpa pool dinamis
subnet 10.86.4.0 netmask 255.255.255.0 {
}

# Network 2: dua pool
subnet 10.86.2.0 netmask 255.255.255.0 {
    option routers 10.86.2.1;
    option subnet-mask 255.255.255.0;
    option broadcast-address 10.86.2.255;
    option domain-name-servers 192.168.122.1;

    pool {
        allow members of "divisi-a-pool1";
        range 10.86.2.10 10.86.2.35;
    }
    pool {
        allow members of "divisi-a-pool2";
        range 10.86.2.70 10.86.2.95;
    }
}

# Network 3 (masih sementara, dipecah di soal 5)
subnet 10.86.3.0 netmask 255.255.255.0 {
    range 10.86.3.10 10.86.3.89;
    option routers 10.86.3.1;
    option subnet-mask 255.255.255.0;
    option broadcast-address 10.86.3.255;
    option domain-name-servers 192.168.122.1;
}
EOF
        dhcpd -t -cf /etc/dhcp/dhcpd.conf
        service isc-dhcp-server start
        grep -nE "class|subclass|allow members|range" /etc/dhcp/dhcpd.conf
        dhcpd -t -cf /etc/dhcp/dhcpd.conf
        ;;
    esac
    ;;
  itadori|fushiguro|zenin|okkotsu|ino|kusakabe|miwa|kugisaki)
    case "$MODE" in
      mac)
        echo "echo M_$(hostname | tr a-z A-Z)=$(cat /sys/class/net/eth0/address) >> /root/macs.env"
        ;;
      *)
        ip addr flush dev eth0
        udhcpc -i eth0 -n -q
        ip addr show dev eth0
        ip route
        ;;
    esac
    ;;
  *)
    echo "Node $N bukan bagian dari soal 4."
    ;;
esac
