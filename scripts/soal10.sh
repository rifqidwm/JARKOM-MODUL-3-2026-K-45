#!/bin/sh

N=$(hostname)
MODE=$1

case "$N" in
  jichi)
    if [ "$MODE" = "check" ]; then
      ip -br a
      ip route
      sysctl net.ipv4.ip_forward
      iptables -t nat -L POSTROUTING -n -v
      ps aux | grep [d]hcrelay
    else
      cat > /root/net.sh <<'EOF'
#!/bin/sh
echo "nameserver 192.168.122.1" > /etc/resolv.conf
ip -4 addr show dev eth0 | grep -q "inet " || udhcpc -i eth0 -n -q
for i in 1 2 3 4; do
    ip addr add 10.86.$i.1/24 dev eth$i 2>/dev/null
    ip link set eth$i up
done
sysctl -w net.ipv4.ip_forward=1 >/dev/null
iptables -t nat -C POSTROUTING -s 10.86.0.0/16 -o eth0 -j MASQUERADE 2>/dev/null || iptables -t nat -A POSTROUTING -s 10.86.0.0/16 -o eth0 -j MASQUERADE
EOF
      grep -q "sh /root/net.sh" /root/.bashrc || echo "sh /root/net.sh" >> /root/.bashrc
      update-rc.d isc-dhcp-relay defaults
      update-rc.d isc-dhcp-relay enable
      grep -q "isc-dhcp-relay start" /root/.bashrc || echo "service isc-dhcp-relay start >/dev/null 2>&1" >> /root/.bashrc
      tail -5 /root/.bashrc
    fi
    ;;
  tengen)
    if [ "$MODE" = "check" ]; then
      ip -br a
      ip route
      service isc-dhcp-server status
      ss -ulnp | grep ':67'
    else
      cat > /root/net.sh <<'EOF'
#!/bin/sh
ip addr add 10.86.4.10/24 dev eth0 2>/dev/null
ip link set eth0 up
ip route replace default via 10.86.4.1
echo "nameserver 192.168.122.1" > /etc/resolv.conf
EOF
      grep -q "sh /root/net.sh" /root/.bashrc || echo "sh /root/net.sh" >> /root/.bashrc
      update-rc.d isc-dhcp-server defaults
      update-rc.d isc-dhcp-server enable
      grep -q "isc-dhcp-server start" /root/.bashrc || echo "service isc-dhcp-server start >/dev/null 2>&1" >> /root/.bashrc
      tail -5 /root/.bashrc
    fi
    ;;
  itadori|fushiguro|zenin|okkotsu|ino|kusakabe|miwa|kugisaki)
    ip addr flush dev eth0
    udhcpc -i eth0 -n -q
    ip addr show dev eth0
    ip route
    ;;
  *)
    echo "Node $N bukan bagian dari soal 10."
    ;;
esac
