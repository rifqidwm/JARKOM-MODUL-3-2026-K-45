#!/bin/sh

N=$(hostname)

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

check_client() {
  case "$N" in itadori|fushiguro|zenin|okkotsu) EN=2 ;; *) EN=3 ;; esac
  RESOLV=${RESOLV:-/etc/resolv.conf}
  ADDR=$(ip addr show dev eth0 | awk '/inet /{print $2}' | head -1)
  if [ -z "$ADDR" ]; then
    echo "ERROR: $N belum punya alamat IPv4 di eth0. Jalankan dulu: sh /root/soal06.sh renew"
    exit 1
  fi
  IPC=${ADDR%/*}; MASK=${ADDR#*/}
  BRD=$(ip addr show dev eth0 | awk '/inet /{for(i=1;i<=NF;i++) if($i=="brd") print $(i+1)}' | head -1)
  GWC=$(ip route | awk '/^default/{print $3}' | head -1)
  DNS=$(awk '/^nameserver/{printf "%s ", $2}' "$RESOLV")
  SRCH=$(awk '/^(search|domain)/{print $2}' "$RESOLV" | head -1)
  t() { if [ "$2" = "$3" ]; then echo "OK   $1: $2"; else echo "FAIL $1: dapat '$2', seharusnya '$3'"; fi; }
  echo "===== $N ====="
  echo "lease : $ADDR"
  t "network"       "$(echo "$IPC" | cut -d. -f1-3)" "10.86.$EN"
  t "netmask (/)"   "$MASK" "24"
  t "broadcast"     "$BRD"  "10.86.$EN.255"
  t "gateway"       "$GWC"  "10.86.$EN.1"
  t "dns"           "$(echo $DNS)" "10.86.1.2 10.86.1.3"
  t "domain-search" "$SRCH" "k45.com"
  echo "--- routing ---"
  ip route
}

check_server() {
  OUT=$(show_leases | while read ip mac d1 t1 d2 t2; do
    n=$(name_of "$mac"); [ -z "$n" ] && n="?"
    o3=$(echo "$ip" | cut -d. -f3); o4=$(echo "$ip" | cut -d. -f4)
    dur=$(( $(date -u -d "$d2 $t2" +%s) - $(date -u -d "$d1 $t1" +%s) ))
    case "$n" in
      ITADORI|FUSHIGURO) en=2; lo=10;  hi=35;  lt=any ;;
      ZENIN|OKKOTSU)     en=2; lo=70;  hi=95;  lt=any ;;
      INO|KUSAKABE)      en=3; lo=10;  hi=89;  lt=1800 ;;
      MIWA)              en=3; lo=100; hi=199; lt=43200 ;;
      KUGISAKI)          en=3; lo=99;  hi=99;  lt=any ;;
      *)                 en=0; lo=0;   hi=0;   lt=any ;;
    esac
    res=OK
    [ "$o3" = "$en" ] || res=FAIL
    { [ "$o4" -ge "$lo" ] && [ "$o4" -le "$hi" ]; } || res=FAIL
    [ "$lt" = any ] || [ "$dur" = "$lt" ] || res=FAIL
    printf "%-10s %-13s %-18s lease=%-6s %s\n" "$n" "$ip" "$mac" "$dur" "$res"
  done)
  echo "===== lease aktif di tengen vs kebijakan ====="
  echo "$OUT"
  echo
  if [ -z "$OUT" ]; then
    echo "Belum ada lease aktif. Jalankan renew di client dulu."
  elif echo "$OUT" | grep -q FAIL; then
    echo "HASIL: ADA PELANGGARAN kebijakan, cek baris FAIL"
  else
    echo "HASIL: semua lease sesuai kebijakan (pool, lease time, fixed address)"
  fi
  echo "Catatan: kugisaki (fixed-address 10.86.3.99) tidak tercatat di dhcpd.leases, itu normal. Buktikan dari client: sh /root/soal07.sh di kugisaki"
  DUP=$(show_leases | awk '{print $2}' | sort | uniq -d)
  [ -z "$DUP" ] && echo "MAC dengan lebih dari satu lease aktif: tidak ada" || echo "PERINGATAN, MAC memegang >1 lease aktif: $DUP"
  echo "Alamat di luar pool (Network 2: .36-.69, Network 3: .90-.98): tidak boleh muncul di tabel di atas"
}

case "$N" in
  tengen) check_server ;;
  itadori|fushiguro|zenin|okkotsu|ino|kusakabe|miwa|kugisaki) check_client ;;
  *) echo "[soal07] $N bukan target soal 7"; exit 0 ;;
esac
