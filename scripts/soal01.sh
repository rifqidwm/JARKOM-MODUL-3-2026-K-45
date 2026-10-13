#!/bin/sh

N=$(hostname)
MODE=$1

case "$N" in
  utahime) IP=10.86.1.2;  GW=10.86.1.1 ;;
  shoko)   IP=10.86.1.3;  GW=10.86.1.1 ;;
  gojo)    IP=10.86.1.4;  GW=10.86.1.1 ;;
  geto)    IP=10.86.4.2;  GW=10.86.4.1 ;;
  maki)    IP=10.86.4.3;  GW=10.86.4.1 ;;
  panda)   IP=10.86.4.4;  GW=10.86.4.1 ;;
  nanami)  IP=10.86.4.5;  GW=10.86.4.1 ;;
  todo)    IP=10.86.4.6;  GW=10.86.4.1 ;;
  kirara)  IP=10.86.4.7;  GW=10.86.4.1 ;;
  yaga)    IP=10.86.4.8;  GW=10.86.4.1 ;;
  inumaki) IP=10.86.4.9;  GW=10.86.4.1 ;;
  tengen)  IP=10.86.4.10; GW=10.86.4.1 ;;
esac

if [ "$N" = "jichi" ] && [ "$MODE" = "cek" ]; then
  sysctl net.ipv4.ip_forward
  iptables -t nat -L POSTROUTING -n -v
  ping -c 2 google.com
  for h in 1.2 1.3 1.4 4.2 4.3 4.4 4.5 4.6 4.7 4.8 4.9 4.10; do
    ping -c1 -W1 10.86.$h >/dev/null && echo "OK   10.86.$h" || echo "FAIL 10.86.$h"
  done
elif [ "$N" = "jichi" ]; then
  ip -br a
  ip -4 addr show dev eth0 | grep -q "inet " || udhcpc -i eth0 -n -q
  echo "nameserver 192.168.122.1" > /etc/resolv.conf
  ip addr replace 10.86.1.1/24 dev eth1 && ip link set eth1 up
  ip addr replace 10.86.2.1/24 dev eth2 && ip link set eth2 up
  ip addr replace 10.86.3.1/24 dev eth3 && ip link set eth3 up
  ip addr replace 10.86.4.1/24 dev eth4 && ip link set eth4 up
  sysctl -w net.ipv4.ip_forward=1
  command -v iptables >/dev/null || (apt-get update && apt-get install -y iptables)
  iptables -t nat -C POSTROUTING -s 10.86.0.0/16 -o eth0 -j MASQUERADE 2>/dev/null || iptables -t nat -A POSTROUTING -s 10.86.0.0/16 -o eth0 -j MASQUERADE
  ip -br a
  ip route
elif [ -n "$IP" ]; then
  ip addr replace $IP/24 dev eth0
  ip link set eth0 up
  ip route replace default via $GW
  echo "nameserver 192.168.122.1" > /etc/resolv.conf
  ip -br a
  ping -c 2 $GW
  ping -c 2 8.8.8.8
  ping -c 2 google.com
else
  echo "Node $N bukan bagian dari soal 1."
fi
