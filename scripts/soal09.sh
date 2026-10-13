#!/bin/sh

N=$(hostname)
MODE=$1

case "$N" in
  jichi)
    case "$MODE" in
      stop)
        service isc-dhcp-relay stop
        ps aux | grep [d]hcrelay
        ;;
      start)
        service isc-dhcp-relay restart
        ps aux | grep [d]hcrelay
        ;;
      *)
        echo "Argumen di jichi: stop atau start."
        ;;
    esac
    ;;
  itadori|fushiguro|zenin|okkotsu|ino|kusakabe|miwa|kugisaki)
    case "$MODE" in
      gagal)
        ip addr flush dev eth0
        udhcpc -i eth0 -n -q -t 3 -T 2
        ip addr show dev eth0
        ip route
        ;;
      pulih)
        ip addr flush dev eth0
        udhcpc -i eth0 -n -q
        ip addr show dev eth0
        ip route
        ;;
      *)
        echo "Argumen di client: gagal atau pulih."
        ;;
    esac
    ;;
  *)
    echo "Node $N bukan bagian dari soal 9."
    ;;
esac
