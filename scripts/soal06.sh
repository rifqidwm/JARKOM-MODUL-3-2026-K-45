#!/bin/sh
# Jarkom Modul 3 K45 | Soal 06: Static lease (fixed address) untuk kugisaki
# tengen : sh /root/soal06.sh          (terapkan konfigurasi DHCP)
#          sh /root/soal06.sh leases   (tampilkan lease aktif beserta nama client)
# client : sh /root/soal06.sh mac      (cetak baris MAC untuk /root/macs.env di tengen)
#          sh /root/soal06.sh renew    (minta lease baru)

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
  dhcpd -t -cf /etc/dhcp/dhcpd.conf || { echo "ERROR: dhcpd.conf tidak valid"; exit 1; }
  service isc-dhcp-server start
  service isc-dhcp-server status | head -5
}

case "$N" in
  tengen)
    case "$MODE" in
      leases) show_named ;;
      *)
        RESET=0
        apply_conf M_ITADORI M_FUSHIGURO M_ZENIN M_OKKOTSU M_INO M_KUSAKABE M_MIWA M_KUGISAKI
        echo
        echo "Selanjutnya: sh /root/soal06.sh renew di kugisaki, harus dapat 10.86.3.99. Lalu sh /root/soal06.sh leases di tengen."
        ;;
    esac
    ;;
  itadori|fushiguro|zenin|okkotsu|ino|kusakabe|miwa|kugisaki)
    case "$MODE" in
      mac)   client_mac ;;
      renew) client_renew ;;
      *)     echo "Pakai: sh /root/soal06.sh mac | renew" ;;
    esac
    ;;
  *) echo "[soal06] $N bukan target soal 06"; exit 0 ;;
esac
