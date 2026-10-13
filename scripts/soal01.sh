#!/bin/sh

P=10.86
N=$(hostname)

case "$N" in
  utahime) IP=$P.1.2;  GW=$P.1.1 ;;
  shoko)   IP=$P.1.3;  GW=$P.1.1 ;;
  gojo)    IP=$P.1.4;  GW=$P.1.1 ;;
  geto)    IP=$P.4.2;  GW=$P.4.1 ;;
  maki)    IP=$P.4.3;  GW=$P.4.1 ;;
  panda)   IP=$P.4.4;  GW=$P.4.1 ;;
  nanami)  IP=$P.4.5;  GW=$P.4.1 ;;
  todo)    IP=$P.4.6;  GW=$P.4.1 ;;
  kirara)  IP=$P.4.7;  GW=$P.4.1 ;;
  yaga)    IP=$P.4.8;  GW=$P.4.1 ;;
  inumaki) IP=$P.4.9;  GW=$P.4.1 ;;
  tengen)  IP=$P.4.10; GW=$P.4.1 ;;
  jichi)   ;;
  *) echo "[soal01] $N bukan target soal 1 (client memakai DHCP, lihat soal 3)"; exit 0 ;;
esac

# ---- tulis /root/net.sh (dipanggil ulang tiap console dibuka, supaya IP kembali setelah restart)
if [ "$N" = "jichi" ]; then
cat > /root/net.sh <<'EOF'
#!/bin/sh
hostname jichi; echo jichi > /etc/hostname

# eth0 -> NAT1 (WAN, DHCP dari NAT GNS3)
grep -q "iface eth0" /etc/network/interfaces 2>/dev/null || printf 'auto eth0\niface eth0 inet dhcp\n' >> /etc/network/interfaces
ip link set eth0 up
if ! ip -4 addr show dev eth0 | grep -q "inet "; then
    ifup eth0 2>/dev/null || dhclient eth0 2>/dev/null || udhcpc -i eth0 -n -q 2>/dev/null
fi
echo "nameserver 192.168.122.1" > /etc/resolv.conf

# eth1-eth4 -> gateway Network 1-4
for i in 1 2 3 4; do
    ip addr add 10.86.$i.1/24 dev eth$i 2>/dev/null
    ip link set eth$i up
done

# IPv4 forwarding + source NAT
sysctl -w net.ipv4.ip_forward=1 >/dev/null
command -v iptables >/dev/null 2>&1 || { apt-get update -y >/dev/null 2>&1; apt-get install -y iptables >/dev/null 2>&1; }
iptables -t nat -C POSTROUTING -s 10.86.0.0/16 -o eth0 -j MASQUERADE 2>/dev/null || \
iptables -t nat -A POSTROUTING -s 10.86.0.0/16 -o eth0 -j MASQUERADE
EOF
else
cat > /root/net.sh <<EOF
#!/bin/sh
hostname $N; echo $N > /etc/hostname
ip addr add $IP/24 dev eth0 2>/dev/null
ip link set eth0 up
ip route replace default via $GW
echo "nameserver 192.168.122.1" > /etc/resolv.conf
EOF
fi

sh /root/net.sh
grep -q "sh /root/net.sh" /root/.bashrc 2>/dev/null || echo "sh /root/net.sh" >> /root/.bashrc

# ---- verifikasi
chk() { if ping -c 2 -W 2 "$2" >/dev/null 2>&1; then echo "OK   $1 ($2)"; else echo "FAIL $1 ($2)"; fi; }
echo "===== $N ====="
ip -br a
ip route
if [ "$N" = "jichi" ]; then
  sysctl net.ipv4.ip_forward
  iptables -t nat -L POSTROUTING -n -v
  chk "internet (IP)"   8.8.8.8
  chk "internet (nama)" google.com
else
  chk "gateway"         "$GW"
  chk "internet (IP)"   8.8.8.8
  chk "internet (nama)" google.com
fi
