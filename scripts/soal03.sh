#!/bin/sh

N=$(hostname)

case "$N" in
  jichi)
    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y isc-dhcp-relay
    cat > /etc/default/isc-dhcp-relay <<'EOF'
SERVERS="10.86.4.10"
INTERFACES="eth2 eth3 eth4"
OPTIONS=""
EOF
    service isc-dhcp-relay restart
    cat /etc/default/isc-dhcp-relay
    ps aux | grep [d]hcrelay
    sysctl net.ipv4.ip_forward
    ;;
  itadori|fushiguro|zenin|okkotsu|ino|kusakabe|miwa|kugisaki)
    ip link set eth0 up
    ip addr flush dev eth0
    udhcpc -i eth0 -n -q
    ip addr show dev eth0
    ip route
    ;;
  tengen)
    grep -E "^lease|hardware ethernet" /var/lib/dhcp/dhcpd.leases
    ;;
  *)
    echo "Node $N bukan bagian dari soal 3."
    ;;
esac
