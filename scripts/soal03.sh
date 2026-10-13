#!/bin/sh

N=$(hostname)

case "$N" in
  jichi)
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -y
    apt-get install -y isc-dhcp-relay
    cat > /etc/default/isc-dhcp-relay <<'EOF'
SERVERS="10.86.4.10"
INTERFACES="eth2 eth3 eth4"
OPTIONS=""
EOF
    service isc-dhcp-relay restart
    sleep 1
    echo "forwarding: $(sysctl -n net.ipv4.ip_forward)"
    ps aux | grep [d]hcrelay
    ;;
  itadori|fushiguro|zenin|okkotsu|ino|kusakabe|miwa|kugisaki)
    cat > /root/net.sh <<EOF
#!/bin/sh
hostname $N; echo $N > /etc/hostname
ip link set eth0 up
udhcpc -i eth0 -n -q -t 3 -T 2 >/dev/null 2>&1
EOF
    ip addr flush dev eth0 2>/dev/null
    sh /root/net.sh
    grep -q "sh /root/net.sh" /root/.bashrc 2>/dev/null || echo "sh /root/net.sh" >> /root/.bashrc
    echo "===== $N ====="
    ip addr show dev eth0 | grep "inet "
    ip route
    ;;
  *) echo "[soal03] $N bukan target soal 3"; exit 0 ;;
esac
