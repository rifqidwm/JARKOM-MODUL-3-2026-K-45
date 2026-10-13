# Script Penyelesaian Jarkom Modul 3 K45

Satu file per soal di folder `scripts/`. Semua script **hanya memakai `sh`** (POSIX), jadi bisa dijalankan di node Debian (`debinet`) maupun Alpine (`alpinet`). Isi script identik dengan command step by step di `README.md`, bedanya dikemas jadi satu file.

**Node dikenali otomatis dari hostname** (nama node di GNS3). Jadi script yang sama bisa di-paste di semua node tujuan, dan di node yang bukan targetnya script hanya mencetak pesan lalu berhenti. Karena itu **nama node di GNS3 harus persis** seperti glosarium soal (`shoko`, bukan `shako`).

---

## Cara pakai (3 langkah)

1. Buka console node tujuan (lihat tabel).
2. Copy **blok paste** soal tersebut dari bagian bawah dokumen ini, paste ke console. Blok ini membuat file `/root/soalNN.sh` (sesuai aturan praktikum: script di `/root`).
3. Jalankan:

```sh
sh /root/soalNN.sh
```

Contoh soal 2 di `tengen`: paste blok soal 2, lalu `sh /root/soal02.sh`.

> **Kalau paste panjang terpotong atau karakternya rusak** di console web GNS3, paste per blok lebih kecil, atau setelah repo di-push ke GitHub dan node punya internet (soal 1 selesai), ambil langsung:
> `wget -qO /root/soal02.sh https://raw.githubusercontent.com/<USER>/Jarkom-Modul-3-2026-K45/main/scripts/soal02.sh`
> (ganti `<USER>`, pastikan `wget` atau `curl` ada di node).

---

## Tabel script, node tujuan, dan hasil sukses

| Script | Fungsi | Dijalankan di | Argumen | Hasil sukses |
| ------ | ------ | ------------- | ------- | ------------ |
| `soal01.sh` | IP statis, gateway, forwarding, NAT | jichi, utahime, shoko, gojo, geto, maki, panda, nanami, todo, kirara, yaga, inumaki, tengen | (tanpa argumen) | `jichi`: eth0 dapat `192.168.122.x`, eth1 sampai eth4 `10.86.x.1`, forwarding `= 1`, ada 1 rule MASQUERADE. Host lain: baris `OK` untuk gateway, `8.8.8.8`, `google.com` |
| `soal02.sh` | DHCP Server isc-dhcp-server | tengen | (tanpa argumen) | `dhcpd -t` bersih, foreground menampilkan `Listening on LPF/eth0/.../10.86.4.0/24` tanpa `No subnet declaration`, service `running`, port 67 terbuka |
| `soal03.sh` | DHCP Relay dan client DHCP | jichi (relay), 8 client | (tanpa argumen) | `jichi`: proses `dhcrelay` jalan dengan `-i eth2 -i eth3 -i eth4 10.86.4.10`. Client: dapat `10.86.2.x` atau `10.86.3.x` dengan gateway `.1` |
| `soal04.sh` | Dua pool Network 2 (class MAC) | tengen, 8 client (untuk `mac`), 4 client Divisi A (untuk `renew`) | tengen: `(kosong)` / `leases`. client: `mac` / `renew` | `itadori`, `fushiguro` di `10.86.2.10-.35`. `zenin`, `okkotsu` di `10.86.2.70-.95`. Tidak ada alamat `.36-.69` |
| `soal05.sh` | Short lease, long lease, DNS, domain | tengen, ino, kusakabe, miwa (dan client Divisi A untuk cek ulang) | tengen: `(kosong)` / `leases`. client: `mac` / `renew` | `ino`, `kusakabe` lease `1800`. `miwa` lease `43200`. `resolv.conf` berisi `10.86.1.2`, `10.86.1.3`, `search k45.com` |
| `soal06.sh` | Static lease kugisaki | tengen, kugisaki | tengen: `(kosong)` / `leases`. client: `mac` / `renew` | `kugisaki` selalu dapat `10.86.3.99`. Catatan: tidak muncul di `dhcpd.leases` (normal untuk fixed-address) |
| `soal07.sh` | Validasi konfigurasi dan lease | 8 client lalu tengen | (tanpa argumen) | Client: semua baris `OK` (network, netmask, broadcast, gateway, dns, domain-search). tengen: `HASIL: semua lease sesuai kebijakan` |
| `soal08.sh` | Capture DORA via relay | tengen lalu itadori atau ino | (tanpa argumen) | Ringkasan memuat Discover, Offer, Request, ACK, `Server-ID`, `Your-IP`, `Lease-Time`, dan `Gateway-IP` = IP interface jichi |
| `soal09.sh` | Gangguan relay dan pemulihan | jichi, 1 client Divisi A atau B, tengen (opsional) | jichi: `stop` / `start`. tengen: `watch`. client: (kosong) | Saat relay mati: client `no lease, failing`, tanpa IP. Setelah relay hidup: client dapat IP pool yang benar dengan gateway semula |
| `soal10.sh` | Autostart dan uji restart | tengen dan jichi (enable, check), client (check) | `(kosong)` = aktifkan, `check` = verifikasi setelah restart | Setelah restart: service jalan, IP dan route kembali, client dapat lease, `soal07.sh` tetap semua `OK` |

---

## Urutan menjalankan (jangan dibalik)

| Tahap | Script | Node | Catatan |
| ----- | ------ | ---- | ------- |
| 0 | (GNS3) | semua | **Start NAT1 dan semua switch dulu** (ikon biru). Switch abu-abu = mati, ARP tidak lewat |
| 1 | `soal01.sh` | `jichi` dulu, lalu 12 host lain | Client dilewati |
| 2 | `soal02.sh` | `tengen` | Butuh internet dari soal 1 |
| 3 | `soal03.sh` | `jichi`, lalu 8 client | Relay di jichi dulu, baru client |
| 4a | `soal04.sh mac` | 8 client | Cetak baris MAC, kumpulkan ke `/root/macs.env` di tengen (lihat di bawah) |
| 4b | `soal04.sh` | `tengen` | Terapkan 2 pool Divisi A |
| 4c | `soal04.sh renew` | `itadori`, `fushiguro`, `zenin`, `okkotsu` | Lalu `soal04.sh leases` di tengen |
| 5 | `soal05.sh` | `tengen`, lalu `ino`, `kusakabe`, `miwa` | `renew` di client, `leases` di tengen |
| 6 | `soal06.sh` | `tengen`, lalu `kugisaki` | `renew` di kugisaki |
| 7 | `soal07.sh` | 8 client dulu, lalu `tengen` | Laporan validasi |
| 8 | `soal08.sh` | `tengen`, pindah ke `itadori` atau `ino` | Client dijalankan dalam 40 detik |
| 9 | `soal09.sh` | `jichi stop`, client, `jichi start`, client | Bandingkan hasilnya |
| 10 | `soal10.sh` | `tengen`, `jichi`, lalu restart, lalu `check` | Buka console setelah restart |

> **Soal 4, 5, dan 6 saling menggantikan konfigurasi `tengen`**: tiap script menulis ulang `/etc/dhcp/dhcpd.conf` lengkap untuk tahap itu. Jadi jangan menjalankan `soal05.sh` setelah `soal06.sh`, karena static lease kugisaki akan hilang. Kalau terlanjur, jalankan `soal06.sh` lagi.

---

## Mengisi `/root/macs.env` (untuk soal 4, 5, 6)

Class DHCP butuh MAC tiap client. Di **tiap 8 client**:

```sh
sh /root/soal04.sh mac
```

Tiap client mencetak satu baris, misalnya `M_ITADORI=02:42:ac:11:00:02`. Kumpulkan **kedelapan baris** itu, lalu di `tengen`:

```sh
cat > /root/macs.env <<'EOF'
M_ITADORI=...
M_FUSHIGURO=...
M_ZENIN=...
M_OKKOTSU=...
M_INO=...
M_KUSAKABE=...
M_MIWA=...
M_KUGISAKI=...
EOF
```

(tempel baris hasil client, tanpa spasi di sekitar `=`). MAC node GNS3 tetap selama node tidak dihapus lalu dibuat ulang.

---

## Blok paste per soal

Tiap blok membuat `/root/soalNN.sh`. Setelah paste, jalankan `sh /root/soalNN.sh` (plus argumen bila perlu).

### soal01: IP statis, gateway, forwarding, NAT

Node: jichi, utahime, shoko, gojo, geto, maki, panda, nanami, todo, kirara, yaga, inumaki, tengen. Argumen: (tanpa argumen).

```sh
cat > /root/soal01.sh <<'SOAL_END'
#!/bin/sh
# Jarkom Modul 3 K45 | Soal 1: IP statis, gateway, IPv4 forwarding, source NAT
# Jalankan di: jichi, utahime, shoko, gojo, geto, maki, panda, nanami, todo, kirara, yaga, inumaki, tengen
# Node dikenali otomatis dari hostname (= nama node di GNS3). Client TIDAK dijalankan di sini (lihat soal 3).
# Cara: sh /root/soal01.sh

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
SOAL_END
```

Jalankan: `sh /root/soal01.sh`

---

### soal02: DHCP Server isc-dhcp-server

Node: tengen. Argumen: (tanpa argumen).

```sh
cat > /root/soal02.sh <<'SOAL_END'
#!/bin/sh
# Jarkom Modul 3 K45 | Soal 2: DHCP Server (isc-dhcp-server) di tengen
# Jalankan di: tengen
# Cara: sh /root/soal02.sh

[ "$(hostname)" = "tengen" ] || { echo "[soal02] jalankan di tengen"; exit 1; }

export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y isc-dhcp-server

# DHCP Server hanya mendengarkan eth0 (Network 4)
sed -i 's/^INTERFACESv4=.*/INTERFACESv4="eth0"/' /etc/default/isc-dhcp-server
grep INTERFACESv4 /etc/default/isc-dhcp-server

cat > /etc/dhcp/dhcpd.conf <<'EOF'
authoritative;
default-lease-time 600;
max-lease-time 7200;

# Network 4 (lokal tengen), tanpa pool dinamis
subnet 10.86.4.0 netmask 255.255.255.0 {
}

# Network 2 (Divisi A), sementara, dipecah jadi 2 pool di soal 4
subnet 10.86.2.0 netmask 255.255.255.0 {
    range 10.86.2.10 10.86.2.35;
    option routers 10.86.2.1;
    option subnet-mask 255.255.255.0;
    option broadcast-address 10.86.2.255;
    option domain-name-servers 192.168.122.1;
}

# Network 3 (Divisi B), sementara, dipecah jadi short/long lease di soal 5
subnet 10.86.3.0 netmask 255.255.255.0 {
    range 10.86.3.10 10.86.3.89;
    option routers 10.86.3.1;
    option subnet-mask 255.255.255.0;
    option broadcast-address 10.86.3.255;
    option domain-name-servers 192.168.122.1;
}
EOF

touch /var/lib/dhcp/dhcpd.leases
dhcpd -t -cf /etc/dhcp/dhcpd.conf || { echo "ERROR: dhcpd.conf tidak valid"; exit 1; }

# bukti: tidak ada pesan "No subnet declaration" (jalan di foreground 3 detik)
service isc-dhcp-server stop 2>/dev/null
echo "--- dhcpd foreground (3 detik) ---"
timeout 3 dhcpd -4 -d -cf /etc/dhcp/dhcpd.conf eth0 2>&1 | grep -E "Listening|No subnet|Sending"
echo "----------------------------------"

service isc-dhcp-server restart
service isc-dhcp-server status | head -5
ss -ulnp | grep ':67'
SOAL_END
```

Jalankan: `sh /root/soal02.sh`

---

### soal03: DHCP Relay dan client DHCP

Node: jichi (relay), 8 client. Argumen: (tanpa argumen).

```sh
cat > /root/soal03.sh <<'SOAL_END'
#!/bin/sh
# Jarkom Modul 3 K45 | Soal 3: DHCP Relay di jichi, client memakai DHCP
# Jalankan di: jichi (relay) dan 8 client (itadori fushiguro zenin okkotsu ino kusakabe miwa kugisaki)
# Cara: sh /root/soal03.sh
# Urutan: soal02 di tengen dulu, lalu jichi, baru client.

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
SOAL_END
```

Jalankan: `sh /root/soal03.sh`

---

### soal04: Dua pool Network 2 (class MAC)

Node: tengen, 8 client (untuk `mac`), 4 client Divisi A (untuk `renew`). Argumen: tengen: `(kosong)` / `leases`. client: `mac` / `renew`.

```sh
cat > /root/soal04.sh <<'SOAL_END'
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
SOAL_END
```

Jalankan: `sh /root/soal04.sh`

---

### soal05: Short lease, long lease, DNS, domain

Node: tengen, ino, kusakabe, miwa (dan client Divisi A untuk cek ulang). Argumen: tengen: `(kosong)` / `leases`. client: `mac` / `renew`.

```sh
cat > /root/soal05.sh <<'SOAL_END'
#!/bin/sh
# Jarkom Modul 3 K45 | Soal 05: Short lease, long lease, dan DHCP options di Network 3
# tengen : sh /root/soal05.sh          (terapkan konfigurasi DHCP)
#          sh /root/soal05.sh leases   (tampilkan lease aktif beserta nama client)
# client : sh /root/soal05.sh mac      (cetak baris MAC untuk /root/macs.env di tengen)
#          sh /root/soal05.sh renew    (minta lease baru)

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
        apply_conf M_ITADORI M_FUSHIGURO M_ZENIN M_OKKOTSU M_INO M_KUSAKABE M_MIWA
        echo
        echo "Selanjutnya: sh /root/soal05.sh renew di ino, kusakabe, miwa (dan itadori/zenin untuk cek Network 2). Lalu sh /root/soal05.sh leases di tengen."
        ;;
    esac
    ;;
  itadori|fushiguro|zenin|okkotsu|ino|kusakabe|miwa|kugisaki)
    case "$MODE" in
      mac)   client_mac ;;
      renew) client_renew; echo '--- /etc/resolv.conf ---'; cat /etc/resolv.conf ;;
      *)     echo "Pakai: sh /root/soal05.sh mac | renew" ;;
    esac
    ;;
  *) echo "[soal05] $N bukan target soal 05"; exit 0 ;;
esac
SOAL_END
```

Jalankan: `sh /root/soal05.sh`

---

### soal06: Static lease kugisaki

Node: tengen, kugisaki. Argumen: tengen: `(kosong)` / `leases`. client: `mac` / `renew`.

```sh
cat > /root/soal06.sh <<'SOAL_END'
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
SOAL_END
```

Jalankan: `sh /root/soal06.sh`

---

### soal07: Validasi konfigurasi dan lease

Node: 8 client lalu tengen. Argumen: (tanpa argumen).

```sh
cat > /root/soal07.sh <<'SOAL_END'
#!/bin/sh
# Jarkom Modul 3 K45 | Soal 7: Validasi konfigurasi client dan lease terhadap kebijakan
# client : sh /root/soal07.sh   (laporan IP, mask, broadcast, gateway, DNS, domain-search)
# tengen : sh /root/soal07.sh   (cocokkan dhcpd.leases dengan kebijakan pool, lease time, fixed address)
# Jalankan client DULU (renew), baru tengen.

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
SOAL_END
```

Jalankan: `sh /root/soal07.sh`

---

### soal08: Capture DORA via relay

Node: tengen lalu itadori atau ino. Argumen: (tanpa argumen).

```sh
cat > /root/soal08.sh <<'SOAL_END'
#!/bin/sh
# Jarkom Modul 3 K45 | Soal 8: Packet capture proses DHCP (DORA) melalui relay
# tengen : sh /root/soal08.sh   (capture 40 detik, lalu tampilkan ringkasan)
# client : sh /root/soal08.sh   (paksa minta lease baru; jalankan SAAT capture di tengen berjalan)
# Urutan: jalankan di tengen dulu, pindah ke console itadori atau ino, jalankan di sana dalam 40 detik.

N=$(hostname)

case "$N" in
  tengen)
    command -v tcpdump >/dev/null 2>&1 || { apt-get update -y; apt-get install -y tcpdump; }
    PCAP=/root/soal08-dora.pcap
    echo ">>> Capture 40 detik di eth0. SEKARANG jalankan 'sh /root/soal08.sh' di itadori (Network 2) atau ino (Network 3)"
    timeout 40 tcpdump -ni eth0 -s0 -U -w "$PCAP" 'udp port 67 or udp port 68' 2>/dev/null
    echo
    echo "===== RINGKASAN DORA (file: $PCAP) ====="
    tcpdump -nvvv -r "$PCAP" 2>/dev/null | grep -E "BOOTP/DHCP|Gateway-IP|Your-IP|Client-Ethernet|DHCP-Message|Server-ID|Lease-Time|Requested-IP"
    echo
    echo "Isi field giaddr (Gateway-IP) yang tertangkap:"
    tcpdump -nvvv -r "$PCAP" 2>/dev/null | grep Gateway-IP | sort -u
    echo "Baca ulang kapan saja: tcpdump -nvvv -r $PCAP"
    ;;
  itadori|fushiguro|zenin|okkotsu|ino|kusakabe|miwa|kugisaki)
    ip addr flush dev eth0 2>/dev/null
    udhcpc -i eth0 -n -q -t 3 -T 2 2>&1 | grep -E "lease of|no lease|sending|received"
    ip addr show dev eth0 | grep "inet "
    ;;
  *) echo "[soal08] $N bukan target soal 8"; exit 0 ;;
esac
SOAL_END
```

Jalankan: `sh /root/soal08.sh`

---

### soal09: Gangguan relay dan pemulihan

Node: jichi, 1 client Divisi A atau B, tengen (opsional). Argumen: jichi: `stop` / `start`. tengen: `watch`. client: (kosong).

```sh
cat > /root/soal09.sh <<'SOAL_END'
#!/bin/sh
# Jarkom Modul 3 K45 | Soal 9: Simulasi gangguan DHCP Relay dan pemulihan
# jichi  : sh /root/soal09.sh stop    (hentikan relay)
#          sh /root/soal09.sh start   (pulihkan relay)
# client : sh /root/soal09.sh         (paksa minta lease baru, catat hasilnya)
# tengen : sh /root/soal09.sh watch   (opsional, lihat apakah DISCOVER sampai ke tengen, 15 detik)
# Urutan: stop di jichi, test di client (GAGAL), start di jichi, test di client lagi (BERHASIL).

N=$(hostname)
MODE=$1

case "$N" in
  jichi)
    case "$MODE" in
      stop)
        service isc-dhcp-relay stop
        sleep 1
        echo "--- status relay setelah stop ---"
        ps aux | grep [d]hcrelay || echo "(tidak ada proses dhcrelay: relay MATI)"
        ;;
      start)
        service isc-dhcp-relay restart
        sleep 1
        echo "--- status relay setelah start ---"
        ps aux | grep [d]hcrelay || echo "(relay GAGAL jalan, cek /etc/default/isc-dhcp-relay)"
        ;;
      *) echo "Pakai: sh /root/soal09.sh stop | start" ;;
    esac
    ;;
  tengen)
    command -v tcpdump >/dev/null 2>&1 || { apt-get update -y; apt-get install -y tcpdump; }
    echo ">>> Mengamati port 67/68 selama 15 detik, jalankan test di client sekarang"
    timeout 15 tcpdump -ni eth0 'udp port 67 or udp port 68' 2>/dev/null
    echo "(selesai)"
    ;;
  itadori|fushiguro|zenin|okkotsu|ino|kusakabe|miwa|kugisaki)
    echo "===== $N: minta lease baru ====="
    ip addr flush dev eth0 2>/dev/null
    udhcpc -i eth0 -n -q -t 3 -T 2 2>&1 | grep -E "sending|lease of|no lease"
    echo "--- alamat dan route sekarang ---"
    ip addr show dev eth0 | grep "inet " || echo "(tidak ada alamat IPv4 di eth0)"
    ip route | grep default || echo "(tidak ada default route)"
    ;;
  *) echo "[soal09] $N bukan target soal 9"; exit 0 ;;
esac
SOAL_END
```

Jalankan: `sh /root/soal09.sh`

---

### soal10: Autostart dan uji restart

Node: tengen dan jichi (enable, check), client (check). Argumen: `(kosong)` = aktifkan, `check` = verifikasi setelah restart.

```sh
cat > /root/soal10.sh <<'SOAL_END'
#!/bin/sh
# Jarkom Modul 3 K45 | Soal 10: Autostart DHCP Server (tengen) dan DHCP Relay (jichi), lalu uji setelah restart
# tengen / jichi : sh /root/soal10.sh          (aktifkan autostart)
#                  sh /root/soal10.sh check    (verifikasi, jalankan SETELAH node di-restart)
# client         : sh /root/soal10.sh check    (verifikasi lease setelah restart)
# Catatan: setelah restart, BUKA CONSOLE node (urutan: jichi, tengen, lalu client) supaya /root/.bashrc jalan.

N=$(hostname)
MODE=$1

enable_svc() {
  SVC=$1
  update-rc.d "$SVC" defaults >/dev/null 2>&1
  update-rc.d "$SVC" enable    >/dev/null 2>&1
  systemctl enable "$SVC"      >/dev/null 2>&1
  # container GNS3 tidak menjalankan init penuh, jadi service juga dipanggil dari .bashrc
  grep -q "service $SVC start" /root/.bashrc 2>/dev/null || echo "service $SVC start >/dev/null 2>&1" >> /root/.bashrc
  echo "--- autostart $SVC ---"
  ls /etc/rc2.d /etc/rc3.d 2>/dev/null | grep -i "$(echo $SVC | cut -c1-8)" || echo "(symlink rc.d tidak ada, hook .bashrc yang dipakai)"
  echo "--- isi /root/.bashrc ---"
  grep -v '^#' /root/.bashrc | grep -v '^$' | tail -5
}

case "$N" in
  tengen)
    case "$MODE" in
      check)
        echo "===== tengen setelah restart ====="
        ip -br a
        ip route
        service isc-dhcp-server status | head -5
        ss -ulnp | grep ':67'
        dhcpd -t -cf /etc/dhcp/dhcpd.conf 2>&1 | tail -1
        echo "lease tersimpan: $(grep -c '^lease' /var/lib/dhcp/dhcpd.leases)"
        echo "Lanjut: sh /root/soal07.sh di tengen untuk cek kebijakan pool/lease/fixed address"
        ;;
      *) enable_svc isc-dhcp-server ;;
    esac
    ;;
  jichi)
    case "$MODE" in
      check)
        echo "===== jichi setelah restart ====="
        ip -br a
        ip route
        echo "forwarding: $(sysctl -n net.ipv4.ip_forward)"
        iptables -t nat -L POSTROUTING -n -v
        service isc-dhcp-relay status | head -5
        ps aux | grep [d]hcrelay
        ;;
      *) enable_svc isc-dhcp-relay ;;
    esac
    ;;
  itadori|fushiguro|zenin|okkotsu|ino|kusakabe|miwa|kugisaki)
    echo "===== $N setelah restart ====="
    ip addr flush dev eth0 2>/dev/null
    udhcpc -i eth0 -n -q -t 3 -T 2 2>&1 | grep -E "lease of|no lease"
    ip addr show dev eth0 | grep "inet "
    ip route | grep default
    echo "Lanjut: sh /root/soal07.sh di client ini, lalu di tengen"
    ;;
  *) echo "[soal10] $N bukan target soal 10"; exit 0 ;;
esac
SOAL_END
```

Jalankan: `sh /root/soal10.sh`

---
