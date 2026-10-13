#!/bin/sh
# Jarkom Modul 3 K45 | Soal 04: Dua pool DHCP di Network 2 (class berdasarkan Client ID / MAC)
# tengen : sh /root/soal04.sh          (terapkan konfigurasi DHCP)
#          sh /root/soal04.sh leases   (tampilkan lease aktif beserta nama client)
# client : sh /root/soal04.sh mac      (cetak baris MAC untuk /root/macs.env di tengen)
#          sh /root/soal04.sh renew    (minta lease baru)

N=$(hostname)
MODE=$1

LEASES=${LEASES:-/var/lib/dhcp/dhcpd.leases}
MACS=${MACS:-/root/macs.env}

# lease aktif terakhir: ip mac tgl_mulai jam_mulai tgl_akhir jam_akhir
show_leases() {
  awk '
    $1=="lease"                  { ip=$2 }
    $1=="binding" && $2=="state" { st=$3; gsub(";","",st) }
    $1=="starts"                 { s=$3" "$4; gsub(";","",s) }
    $1=="ends"                   { e=$3" "$4; gsub(";","",e) }
    $1=="hardware"               { m=$3; gsub(";","",m) }
    $1=="}"                      { if (st=="active") L[ip]=m" "s" "e; else delete L[ip] }
    END { for (i in L) print i, L[i] }
  ' "$LEASES" | sort -t. -k3,3n -k4,4n
}

# nama client dari MAC, berdasarkan /root/macs.env
name_of() {
  grep -i "=$1\$" "$MACS" 2>/dev/null | cut -d= -f1 | sed 's/^M_//'
}

show_named() {
  show_leases | while read ip mac rest; do
    n=$(name_of "$mac")
    echo "$ip  $mac  ${n:-?}"
  done
  echo "(catatan: kugisaki memakai fixed-address 10.86.3.99, dhcpd TIDAK mencatat host reservasi di dhcpd.leases, buktikan dari client)"
}

client_mac() {
  NU=$(echo "$N" | tr 'a-z' 'A-Z')
  echo "M_$NU=$(cat /sys/class/net/eth0/address)"
}

client_renew() {
  ip addr flush dev eth0 2>/dev/null
  udhcpc -i eth0 -n -q -t 3 -T 2 2>&1 | grep -E "lease of|no lease"
  ip addr show dev eth0 | grep "inet "
  ip route | grep default
}

need() {
  eval "v=\$$1"
  if [ -z "$v" ]; then echo "ERROR: $1 kosong di $MACS"; exit 1; fi
}

apply_conf() {
  [ -f "$MACS" ] || { echo "ERROR: $MACS belum ada. Kumpulkan MAC client dulu (sh /root/soal04.sh mac di tiap client)"; exit 1; }
  . "$MACS"
  for v in "$@"; do need "$v"; done
  service isc-dhcp-server stop
  if [ "$RESET" = "1" ]; then : > "$LEASES"; rm -f "$LEASES~"; fi
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
  dhcpd -t -cf /etc/dhcp/dhcpd.conf || { echo "ERROR: dhcpd.conf tidak valid"; exit 1; }
  service isc-dhcp-server start
  service isc-dhcp-server status | head -5
}

case "$N" in
  tengen)
    case "$MODE" in
      leases) show_named ;;
      *)
        RESET=1
        apply_conf M_ITADORI M_FUSHIGURO M_ZENIN M_OKKOTSU
        echo
        echo "Selanjutnya: sh /root/soal04.sh renew di itadori, fushiguro, zenin, okkotsu. Lalu sh /root/soal04.sh leases di tengen."
        ;;
    esac
    ;;
  itadori|fushiguro|zenin|okkotsu|ino|kusakabe|miwa|kugisaki)
    case "$MODE" in
      mac)   client_mac ;;
      renew) client_renew ;;
      *)     echo "Pakai: sh /root/soal04.sh mac | renew" ;;
    esac
    ;;
  *) echo "[soal04] $N bukan target soal 04"; exit 0 ;;
esac
