#!/bin/sh

N=$(hostname)

case "$N" in
  itadori|fushiguro|zenin|okkotsu|ino|kusakabe|miwa|kugisaki)
    ip addr flush dev eth0
    udhcpc -i eth0 -n -q
    ip addr show dev eth0
    ip route
    cat /etc/resolv.conf
    ;;
  tengen)
    grep -E "^lease|starts|ends|hardware ethernet" /var/lib/dhcp/dhcpd.leases | tail -40
    ;;
  *)
    echo "Node $N bukan bagian dari soal 7."
    ;;
esac
