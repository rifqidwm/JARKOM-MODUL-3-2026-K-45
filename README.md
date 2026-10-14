# JARKOM MODUL 3 2026 - K-45

## Anggota

| Nama                         | NRP        |
| ---------------------------- | ---------- |
| Abhista Athallah Dyfan       | 5027251006 |
| Rifqi Dwi Muslim             | 5027251077 |

---

**Daftar node:**

| Jumlah | Jenis node       | Node                                                                                        |
| ------ | ---------------- | ------------------------------------------------------------------------------------------- |
| 13     | Docker (debinet) | jichi, tengen, utahime, shoko, gojo, geto, maki, panda, nanami, todo, kirara, yaga, inumaki |
| 8      | Docker (alpinet) | itadori, fushiguro, zenin, okkotsu, ino, kusakabe, miwa, kugisaki                           |
| 10     | Ethernet switch  | Switch1 sampai Switch10                                                                     |
| 1      | NAT              | NAT1                                                                                        |


**TOPOLOGI JARINGAN:**



![](assets/topologi.png)


---

## Rancangan Pengalamatan IP

Prefix kelompok adalah **`10.86.x.x`** dengan domain **`k45.com`**. Router jichi terhubung ke empat jaringan, masing-masing satu subnet `/24`.

| Network                 | Subnet       | Gateway (jichi)  | Node                                                           |
| ----------------------- | ------------ | ---------------- | -------------------------------------------------------------- |
| Network 1 (DMZ)         | 10.86.1.0/24 | 10.86.1.1 (eth1) | utahime, shoko, gojo                                           |
| Network 2 (Divisi A)    | 10.86.2.0/24 | 10.86.2.1 (eth2) | itadori, fushiguro, zenin, okkotsu (DHCP)                      |
| Network 3 (Divisi B)    | 10.86.3.0/24 | 10.86.3.1 (eth3) | ino, kusakabe, miwa, kugisaki (DHCP)                           |
| Network 4 (Data Center) | 10.86.4.0/24 | 10.86.4.1 (eth4) | tengen, geto, maki, panda, nanami, todo, kirara, yaga, inumaki |

**Alamat IP statis node infrastruktur:**

| Node    | IP         | Gateway   | Peran                           |
| ------- | ---------- | --------- | ------------------------------- |
| jichi   | multi eth  | -         | Router utama, NAT, DHCP Relay   |
| utahime | 10.86.1.2  | 10.86.1.1 | DNS Master                      |
| shoko   | 10.86.1.3  | 10.86.1.1 | DNS Slave                       |
| gojo    | 10.86.1.4  | 10.86.1.1 | Public Reverse Proxy            |
| geto    | 10.86.4.2  | 10.86.4.1 | Internal Load Balancer          |
| maki    | 10.86.4.3  | 10.86.4.1 | Worker frontend                 |
| panda   | 10.86.4.4  | 10.86.4.1 | Worker frontend                 |
| nanami  | 10.86.4.5  | 10.86.4.1 | Worker API utama                |
| todo    | 10.86.4.6  | 10.86.4.1 | Worker API utama                |
| kirara  | 10.86.4.7  | 10.86.4.1 | Worker API cadangan             |
| yaga    | 10.86.4.8  | 10.86.4.1 | Database Master                 |
| inumaki | 10.86.4.9  | 10.86.4.1 | Database Slave                  |
| tengen  | 10.86.4.10 | 10.86.4.1 | DHCP Server                     |

Seluruh node memakai netmask `255.255.255.0`. Interface eth0 jichi memperoleh alamat `192.168.122.x` dari DHCP NAT.

**Kebijakan DHCP yang diterapkan (soal 4 sampai 6):**

| Client             | Network | Rentang / alamat            | Lease time    |
| ------------------ | ------- | --------------------------- | ------------- |
| itadori, fushiguro | 2       | 10.86.2.10 - 10.86.2.35     | 600 (default) |
| zenin, okkotsu     | 2       | 10.86.2.70 - 10.86.2.95     | 600 (default) |
| tidak dialokasikan | 2       | 10.86.2.36 - 10.86.2.69     | -             |
| ino, kusakabe      | 3       | 10.86.3.10 - 10.86.3.89     | 1800          |
| miwa               | 3       | 10.86.3.100 - 10.86.3.199   | 43200         |
| kugisaki           | 3       | 10.86.3.99 (fixed address)  | 600 (default) |

---

## Urutan Pengerjaan

1. NAT1 dan seluruh switch dijalankan lebih dulu. Switch yang belum berjalan tidak meneruskan frame.
2. Router jichi dikonfigurasi (WAN, gateway Network 1 sampai 4, forwarding, NAT) agar node lain memiliki jalur keluar untuk mengunduh paket.
3. Host infrastruktur diberi IP statis, gateway, dan resolver awal.
4. tengen memasang DHCP server, jichi memasang DHCP relay, lalu client meminta lease.
5. Kebijakan alokasi diterapkan bertahap: dua pool (soal 4), short lease, long lease, dan DNS (soal 5), lalu static lease (soal 6).
6. Validasi, packet capture, simulasi gangguan relay, dan pengujian setelah restart (soal 7 sampai 10).

---

### SOAL 1

**Diminta:** memulihkan konektivitas antarjaringan melalui jichi. Interface eth0 memperoleh WAN dari NAT, eth1 sampai eth4 menjadi gateway Network 1 sampai 4, IPv4 forwarding dan source NAT diaktifkan, host infrastruktur diberi IP statis, lalu dibuktikan setiap host dapat menjangkau gateway dan akses eksternal.

Sebelum mulai, NAT1 dan seluruh switch dipastikan sudah berjalan.

#### Konfigurasi jichi

Langkah 1, memeriksa alamat eth0. Image `debinet` sudah menjalankan `udhcpc` saat boot sehingga eth0 umumnya sudah memperoleh alamat `192.168.122.x`:

```sh
ip -br a
```

Apabila eth0 belum memiliki alamat, alamat diminta secara manual:

```sh
udhcpc -i eth0 -n -q
ip -br a
```

Langkah 2, resolver awal agar `apt` dapat mengunduh paket:

```sh
echo "nameserver 192.168.122.1" > /etc/resolv.conf
```

Langkah 3, alamat gateway untuk keempat jaringan:

```sh
ip addr replace 10.86.1.1/24 dev eth1 && ip link set eth1 up
ip addr replace 10.86.2.1/24 dev eth2 && ip link set eth2 up
ip addr replace 10.86.3.1/24 dev eth3 && ip link set eth3 up
ip addr replace 10.86.4.1/24 dev eth4 && ip link set eth4 up
```

Langkah 4, mengaktifkan IPv4 forwarding:

```sh
sysctl -w net.ipv4.ip_forward=1
```

Langkah 5, memasang iptables bila belum tersedia, lalu menambahkan aturan source NAT:

```sh
command -v iptables >/dev/null || (apt-get update && apt-get install -y iptables)
iptables -t nat -C POSTROUTING -s 10.86.0.0/16 -o eth0 -j MASQUERADE 2>/dev/null || iptables -t nat -A POSTROUTING -s 10.86.0.0/16 -o eth0 -j MASQUERADE
```

Arti aturan tersebut:

- `-t nat -A POSTROUTING` menerapkan aturan pada paket yang akan meninggalkan router.
- `-s 10.86.0.0/16` membatasi aturan pada paket dari subnet internal kelompok.
- `-o eth0` berarti paket keluar melalui interface yang terhubung ke NAT.
- `-j MASQUERADE` mengganti alamat sumber paket dengan alamat eth0 jichi.
- Bagian `-C ... ||` memeriksa aturan terlebih dahulu sehingga aturan tidak tercatat ganda apabila perintah dijalankan ulang.

Langkah 6, pemeriksaan hasil konfigurasi jichi:

```sh
ip -br a
ip route
```

#### Konfigurasi host infrastruktur

Setiap host menjalankan empat perintah yang sama dengan alamat dan gateway masing-masing.

**utahime**

```sh
ip addr replace 10.86.1.2/24 dev eth0
ip link set eth0 up
ip route replace default via 10.86.1.1
echo "nameserver 192.168.122.1" > /etc/resolv.conf
```

**shoko**

```sh
ip addr replace 10.86.1.3/24 dev eth0
ip link set eth0 up
ip route replace default via 10.86.1.1
echo "nameserver 192.168.122.1" > /etc/resolv.conf
```

**gojo**

```sh
ip addr replace 10.86.1.4/24 dev eth0
ip link set eth0 up
ip route replace default via 10.86.1.1
echo "nameserver 192.168.122.1" > /etc/resolv.conf
```

**geto**

```sh
ip addr replace 10.86.4.2/24 dev eth0
ip link set eth0 up
ip route replace default via 10.86.4.1
echo "nameserver 192.168.122.1" > /etc/resolv.conf
```

**maki**

```sh
ip addr replace 10.86.4.3/24 dev eth0
ip link set eth0 up
ip route replace default via 10.86.4.1
echo "nameserver 192.168.122.1" > /etc/resolv.conf
```

**panda**

```sh
ip addr replace 10.86.4.4/24 dev eth0
ip link set eth0 up
ip route replace default via 10.86.4.1
echo "nameserver 192.168.122.1" > /etc/resolv.conf
```

**nanami**

```sh
ip addr replace 10.86.4.5/24 dev eth0
ip link set eth0 up
ip route replace default via 10.86.4.1
echo "nameserver 192.168.122.1" > /etc/resolv.conf
```

**todo**

```sh
ip addr replace 10.86.4.6/24 dev eth0
ip link set eth0 up
ip route replace default via 10.86.4.1
echo "nameserver 192.168.122.1" > /etc/resolv.conf
```

**kirara**

```sh
ip addr replace 10.86.4.7/24 dev eth0
ip link set eth0 up
ip route replace default via 10.86.4.1
echo "nameserver 192.168.122.1" > /etc/resolv.conf
```

**yaga**

```sh
ip addr replace 10.86.4.8/24 dev eth0
ip link set eth0 up
ip route replace default via 10.86.4.1
echo "nameserver 192.168.122.1" > /etc/resolv.conf
```

**inumaki**

```sh
ip addr replace 10.86.4.9/24 dev eth0
ip link set eth0 up
ip route replace default via 10.86.4.1
echo "nameserver 192.168.122.1" > /etc/resolv.conf
```

**tengen**

```sh
ip addr replace 10.86.4.10/24 dev eth0
ip link set eth0 up
ip route replace default via 10.86.4.1
echo "nameserver 192.168.122.1" > /etc/resolv.conf
```

Perintah `ip addr replace` dipakai agar tidak muncul error apabila alamat sudah terpasang sebelumnya.

**Verifikasi di host Network 1** (utahime, shoko, gojo):

```sh
ip -br a
ping -c 2 10.86.1.1
ping -c 2 8.8.8.8
ping -c 2 google.com
```

**Verifikasi di host Network 4** (geto, maki, panda, nanami, todo, kirara, yaga, inumaki, tengen):

```sh
ip -br a
ping -c 2 10.86.4.1
ping -c 2 8.8.8.8
ping -c 2 google.com
```

**Verifikasi NAT di jichi**, dijalankan setelah host melakukan ping keluar:

```sh
sysctl net.ipv4.ip_forward
iptables -t nat -L POSTROUTING -n -v
ping -c 2 google.com
```

**Pemeriksaan seluruh host dari jichi:**

```sh
for h in 1.2 1.3 1.4 4.2 4.3 4.4 4.5 4.6 4.7 4.8 4.9 4.10; do
  ping -c1 -W1 10.86.$h >/dev/null && echo "OK   10.86.$h" || echo "FAIL 10.86.$h"
done
```

Konfigurasi di atas bersifat sementara dan hilang ketika node dijalankan ulang. Penyimpanan permanen untuk jichi dan tengen dikerjakan pada soal 10.

**Hasil:**

- eth0 jichi memperoleh `192.168.122.52/24` dengan `default via 192.168.122.1`, sedangkan eth1 sampai eth4 memegang `10.86.1.1` sampai `10.86.4.1`.
- `net.ipv4.ip_forward = 1` dan terdapat satu aturan `MASQUERADE` untuk `10.86.0.0/16`. Penghitung paket aturan tersebut bernilai 8 setelah host melakukan ping keluar, yang menunjukkan source NAT benar-benar dipakai.
- utahime berhasil menjangkau gateway sendiri (`10.86.1.1`), gateway jaringan lain (`10.86.4.1`), `8.8.8.8`, dan `google.com`.
- Pemeriksaan dari jichi menghasilkan `OK` untuk kedua belas host infrastruktur.


![](assets/soal1-jichi-ipa.png)



![](assets/soal1-jichi-nat.png)



![](assets/soal1-ping-gateway.png)



![](assets/soal1-ping-eksternal.png)



![](assets/soal1-cek-massal.png)

**Script:** `scripts/soal01.sh`, dijalankan di jichi dan dua belas host infrastruktur.

---

### SOAL 2

**Diminta:** mengonfigurasi `isc-dhcp-server` pada `10.86.4.10`, mendeklarasikan Network 4 sebagai subnet lokal tanpa pool dinamis, menyiapkan scope untuk Network 2 dan Network 3, lalu memastikan service berjalan tanpa galat `No subnet declaration`.

dhcpd menolak berjalan apabila interface yang didengarkan tidak memiliki deklarasi `subnet` yang sesuai. Karena eth0 tengen berada di `10.86.4.0/24`, subnet tersebut tetap dideklarasikan meskipun tanpa pool. Scope Network 2 dan Network 3 pada tahap ini masih sementara dan dipecah pada soal 4 dan 5.

Langkah 1, memasang paket:

```sh
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y isc-dhcp-server
```

Langkah 2, membatasi DHCP server agar hanya mendengarkan eth0:

```sh
sed -i 's/^INTERFACESv4=.*/INTERFACESv4="eth0"/' /etc/default/isc-dhcp-server
```

Langkah 3, menulis konfigurasi:

```sh
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
```

Langkah 4, mengosongkan lease lama lalu memvalidasi konfigurasi:

```sh
service isc-dhcp-server stop
: > /var/lib/dhcp/dhcpd.leases
rm -f /var/lib/dhcp/dhcpd.leases~
grep INTERFACESv4 /etc/default/isc-dhcp-server
dhcpd -t -cf /etc/dhcp/dhcpd.conf
```

Langkah 5, menjalankan dhcpd sebentar di foreground untuk memastikan tidak ada galat `No subnet declaration`, kemudian menjalankan service:

```sh
service isc-dhcp-server stop
timeout 3 dhcpd -4 -d -cf /etc/dhcp/dhcpd.conf eth0 2>&1 | grep -E "Listening|No subnet|Sending"
service isc-dhcp-server start
service isc-dhcp-server status
ss -ulnp | grep ':67'
```

**Hasil:**

- `INTERFACESv4="eth0"` dan `dhcpd -t` hanya menampilkan informasi versi serta lokasi berkas, tanpa galat.
- Mode foreground menampilkan `Listening on LPF/eth0/02:42:ad:e2:dc:00/10.86.4.0/24` dan tidak ada pesan `No subnet declaration`. Pesan `Terminated` muncul karena `timeout 3` menghentikan proses foreground tersebut.
- Service berstatus `dhcpd is running` dan port UDP `67` dipegang oleh proses `dhcpd`.

![](assets/soal2-dhcpd-t.png)



![](assets/soal2-status-listening.png)

**Script:** `scripts/soal02.sh`, dijalankan di tengen.

---

### SOAL 3

**Diminta:** mengonfigurasi jichi sebagai DHCP Relay menuju `10.86.4.10` dengan eth2 untuk Network 2 dan eth3 untuk Network 3, lalu membuktikan client kedua subnet memperoleh lease melalui relay.

Pesan DHCPDISCOVER berbentuk broadcast dan tidak diteruskan antar subnet oleh router. Relay menangkap broadcast tersebut pada eth2 atau eth3, mengirimkannya secara unicast ke tengen dengan field `giaddr` berisi alamat interface penerima, lalu mengembalikan balasan server ke client. Nilai `giaddr` juga dipakai tengen untuk memilih subnet yang dilayani. eth4 ikut didaftarkan karena merupakan jalur menuju server.

#### Konfigurasi jichi

Langkah 1, memasang paket:

```sh
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y isc-dhcp-relay
```

Langkah 2, menulis konfigurasi relay dan menjalankan ulang service:

```sh
cat > /etc/default/isc-dhcp-relay <<'EOF'
SERVERS="10.86.4.10"
INTERFACES="eth2 eth3 eth4"
OPTIONS=""
EOF
service isc-dhcp-relay restart
```

Langkah 3, pemeriksaan:

```sh
cat /etc/default/isc-dhcp-relay
ps aux | grep [d]hcrelay
sysctl net.ipv4.ip_forward
```

#### Client

Langkah 4, dijalankan di kedelapan client (itadori, fushiguro, zenin, okkotsu, ino, kusakabe, miwa, kugisaki):

```sh
ip link set eth0 up
ip addr flush dev eth0
udhcpc -i eth0 -n -q
ip addr show dev eth0
ip route
```

Client tidak perlu disimpan permanen karena lease cukup diminta ulang dengan `udhcpc` setelah node dijalankan ulang.

#### Pemeriksaan di tengen

Langkah 5, setelah kedelapan client selesai:

```sh
grep -E "^lease|hardware ethernet" /var/lib/dhcp/dhcpd.leases
```

**Hasil:**

- Proses relay berjalan sebagai `/usr/sbin/dhcrelay -q -i eth2 -i eth3 -i eth4 10.86.4.10` dengan forwarding bernilai `1`.
- itadori memperoleh `10.86.2.10` dan ino memperoleh `10.86.3.10`, keduanya `obtained from 10.86.4.10`, dengan default route masing-masing ke `10.86.2.1` dan `10.86.3.1`.
- `dhcpd.leases` mencatat delapan lease, yaitu `10.86.2.10` sampai `10.86.2.13` dan `10.86.3.10` sampai `10.86.3.13`, beserta MAC setiap client.

![](assets/soal3-relay-config.png)



![](assets/soal3-client-n2.png)



![](assets/soal3-client-n3.png)



![](assets/soal3-tengen-leases.png)

**Script:** `scripts/soal03.sh`, dijalankan di jichi dan kedelapan client.

---

### SOAL 4

**Diminta:** membuat dua pool pada Network 2. Pool 1 (`10.86.2.10` sampai `10.86.2.35`) untuk itadori dan fushiguro, Pool 2 (`10.86.2.70` sampai `10.86.2.95`) untuk zenin dan okkotsu. Rentang `10.86.2.36` sampai `10.86.2.69` tidak dialokasikan, dan pemisahan memakai DHCP class berdasarkan MAC Address atau Client ID.

Karena seluruh client berada pada subnet yang sama, pembeda yang dipakai adalah identitas client. Ekspresi `match pick-first-value (option dhcp-client-identifier, hardware)` memakai Client ID apabila ada dan memakai MAC apabila tidak. Setiap `pool` hanya menerima anggota class tertentu melalui `allow members of`. Rentang `.36` sampai `.69` tidak termasuk dalam `range` pool mana pun sehingga tidak pernah dialokasikan.

#### Pengumpulan MAC client

Langkah 1, dijalankan di setiap client untuk menampilkan MAC dalam bentuk baris perintah:

```sh
echo "echo M_$(hostname | tr a-z A-Z)=$(cat /sys/class/net/eth0/address) >> /root/macs.env"
```

Langkah 2, MAC seluruh client disimpan ke `/root/macs.env` di tengen. Berkas ini dipakai ulang pada soal 5 dan 6:

```sh
: > /root/macs.env
echo M_ITADORI=02:42:97:40:66:00 >> /root/macs.env
echo M_FUSHIGURO=02:42:c8:94:58:00 >> /root/macs.env
echo M_ZENIN=02:42:3b:86:61:00 >> /root/macs.env
echo M_OKKOTSU=02:42:27:fb:e9:00 >> /root/macs.env
echo M_INO=02:42:14:fc:9c:00 >> /root/macs.env
echo M_KUSAKABE=02:42:b9:59:6f:00 >> /root/macs.env
echo M_MIWA=02:42:4a:27:87:00 >> /root/macs.env
echo M_KUGISAKI=02:42:e7:23:fc:00 >> /root/macs.env
```

Langkah 3, pemeriksaan isi berkas:

```sh
cat /root/macs.env
```

#### Konfigurasi tengen

Langkah 4, mengosongkan lease sementara dari soal 3 agar tidak tertahan di pool yang salah:

```sh
service isc-dhcp-server stop
: > /var/lib/dhcp/dhcpd.leases
rm -f /var/lib/dhcp/dhcpd.leases~
```

Langkah 5, menulis konfigurasi soal 4. Heredoc ditulis tanpa tanda kutip agar variabel `$M_...` terisi dari `macs.env`:

```sh
. /root/macs.env
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
```

Langkah 6, validasi dan menjalankan service:

```sh
dhcpd -t -cf /etc/dhcp/dhcpd.conf
service isc-dhcp-server start
grep -nE "class|subclass|allow members|range" /etc/dhcp/dhcpd.conf
dhcpd -t -cf /etc/dhcp/dhcpd.conf
```

#### Client Divisi A

Langkah 7, dijalankan di itadori, fushiguro, zenin, dan okkotsu:

```sh
ip addr flush dev eth0
udhcpc -i eth0 -n -q
ip addr show dev eth0
ip route
```

#### Pemeriksaan di tengen

Langkah 8:

```sh
awk '/^lease/{ip=$2} /hardware ethernet/{gsub(";","",$3); print ip, $3}' /var/lib/dhcp/dhcpd.leases | sort -u
```

**Hasil:**

| Lease        | MAC                 | Client    | Pool   |
| ------------ | ------------------- | --------- | ------ |
| `10.86.2.10` | `02:42:97:40:66:00` | itadori   | Pool 1 |
| `10.86.2.11` | `02:42:c8:94:58:00` | fushiguro | Pool 1 |
| `10.86.2.70` | `02:42:3b:86:61:00` | zenin     | Pool 2 |
| `10.86.2.71` | `02:42:27:fb:e9:00` | okkotsu   | Pool 2 |

Keempat client memakai gateway `10.86.2.1`, dan tidak ada alamat pada rentang `10.86.2.36` sampai `10.86.2.69`.

![](assets/soal4-macs.png)



![](assets/soal4-conf.png)



![](assets/soal4-client-pool1.png)



![](assets/soal4-client-pool2.png)



![](assets/soal4-tengen-leases.png)

**Script:** `scripts/soal04.sh`, dijalankan di tengen untuk menerapkan konfigurasi dan di client untuk `mac` serta `renew`.

---

### SOAL 5

**Diminta:** memberikan short lease 1800 detik kepada ino dan kusakabe pada pool `10.86.3.10` sampai `10.86.3.89`, long lease 43200 detik kepada miwa pada pool `10.86.3.100` sampai `10.86.3.199`, menyesuaikan `default-lease-time` dan `max-lease-time` per kelas, serta memberikan DNS `10.86.1.2`, `10.86.1.3`, dan domain-search `k45.com`.

Lease time ditempatkan di dalam masing-masing `pool` sehingga otomatis berlaku bagi class yang diizinkan masuk pool tersebut. Nilai `max-lease-time` disamakan dengan `default-lease-time` agar durasi tetap 1800 dan 43200 detik walaupun client meminta waktu lebih lama. Opsi DNS dan domain ditempatkan pada bagian global karena juga dibutuhkan Network 2. Celah `10.86.3.90` sampai `10.86.3.99` sengaja tidak dimasukkan ke pool mana pun untuk static lease kugisaki di soal 6.

#### Konfigurasi tengen

Langkah 1, mengosongkan lease lalu menulis konfigurasi soal 5:

```sh
service isc-dhcp-server stop
: > /var/lib/dhcp/dhcpd.leases
rm -f /var/lib/dhcp/dhcpd.leases~
. /root/macs.env
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
```

Langkah 2, validasi dan menjalankan service:

```sh
dhcpd -t -cf /etc/dhcp/dhcpd.conf
service isc-dhcp-server start
grep -nE "domain|lease-time|range|class" /etc/dhcp/dhcpd.conf
dhcpd -t -cf /etc/dhcp/dhcpd.conf
```

#### Client Divisi B

Langkah 3, dijalankan di ino, kusakabe, dan miwa:

```sh
ip addr flush dev eth0
udhcpc -i eth0 -n -q
ip addr show dev eth0
ip route
```

Langkah 4, memeriksa DNS dan domain yang diterima client:

```sh
cat /etc/resolv.conf
```

**Hasil:**

- Konfigurasi memuat opsi DNS `10.86.1.2, 10.86.1.3`, `domain-search "k45.com"`, class `short-lease` dan `long-lease`, serta lease time `1800` dan `43200` pada pool masing-masing. `dhcpd -t` tidak menampilkan galat.
- ino memperoleh `10.86.3.10` dengan `lease time 1800`.
- miwa memperoleh `10.86.3.100` dengan `lease time 43200`.
- `/etc/resolv.conf` di client berisi `search k45.com`, `nameserver 10.86.1.2`, dan `nameserver 10.86.1.3`.
- kugisaki belum memperoleh alamat pada tahap ini karena belum termasuk class mana pun. Resolusi nama dari client juga belum berfungsi karena DNS `10.86.1.2` dan `10.86.1.3` baru dibangun pada soal berikutnya.

![](assets/soal5-conf.png)



![](assets/soal5-ino-1800.png)



![](assets/soal5-miwa-43200.png)



![](assets/soal5-resolv-conf.png)

**Script:** `scripts/soal05.sh`, dijalankan di tengen untuk menerapkan konfigurasi dan di client untuk `renew`.

---

### SOAL 6

**Diminta:** membuat static lease berdasarkan MAC kugisaki dengan fixed address `10.86.3.99` di luar seluruh pool dinamis, memvalidasi konfigurasi, melakukan renew lease di client, lalu membuktikan alamat yang diterima sesuai reservasi.

Blok `host` dengan `hardware ethernet` dan `fixed-address` memetakan satu MAC ke satu alamat tetap. Alamat `10.86.3.99` berada di luar pool short lease maupun long lease sehingga tidak dapat diberikan kepada client lain.

#### Konfigurasi tengen

Langkah 1, menulis konfigurasi soal 6, yaitu konfigurasi soal 5 ditambah blok `host`. Lease tidak dikosongkan pada tahap ini:

```sh
service isc-dhcp-server stop
. /root/macs.env
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
```

Langkah 2, menjalankan service dan menampilkan blok reservasi:

```sh
dhcpd -t -cf /etc/dhcp/dhcpd.conf
service isc-dhcp-server start
grep -B1 -A3 "host kugisaki" /etc/dhcp/dhcpd.conf
```

Langkah 3, validasi konfigurasi:

```sh
dhcpd -t -cf /etc/dhcp/dhcpd.conf
```

#### Client kugisaki

Langkah 4, renew lease dua kali untuk menunjukkan alamat tetap sama:

```sh
ip addr flush dev eth0
udhcpc -i eth0 -n -q
ip addr show dev eth0
ip addr flush dev eth0
udhcpc -i eth0 -n -q
ip addr show dev eth0
ip route
```

**Hasil:**

- Blok `host kugisaki` memuat `hardware ethernet 02:42:e7:23:fc:00` dan `fixed-address 10.86.3.99`, dan `dhcpd -t` tidak menampilkan galat.
- kugisaki memperoleh `10.86.3.99` dari `10.86.4.10` dengan gateway `10.86.3.1`.
- Alamat kugisaki tidak tercatat di `/var/lib/dhcp/dhcpd.leases`. Hal ini merupakan perilaku ISC dhcpd, karena host dengan `fixed-address` tidak disimpan sebagai lease dinamis. Pembuktian dilakukan dari sisi client.

![](assets/soal6-conf-host.png)


![](assets/soal6-dhcpd-t.png)


![](assets/soal6-kugisaki-ip.png)

**Script:** `scripts/soal06.sh`, dijalankan di tengen untuk menerapkan konfigurasi dan di kugisaki untuk `renew`.

---

### SOAL 7

**Diminta:** memastikan setiap client menerima subnet mask `/24`, gateway dan broadcast yang benar, DNS `10.86.1.2` dan `10.86.1.3`, serta domain-search yang ditentukan, memeriksa IP dan routing client Divisi A dan Divisi B, lalu mencocokkan lease dengan `/var/lib/dhcp/dhcpd.leases` tanpa ada alamat yang bertabrakan atau berada di luar kebijakan pool.

#### Client

Langkah 1, dijalankan di client Divisi A dan Divisi B:

```sh
ip addr flush dev eth0
udhcpc -i eth0 -n -q
ip addr show dev eth0
ip route
cat /etc/resolv.conf
```

Nilai yang harus sesuai:

| Network | Prefix | Gateway   | Broadcast   | DNS                  | Domain-search |
| ------- | ------ | --------- | ----------- | -------------------- | ------------- |
| 2       | /24    | 10.86.2.1 | 10.86.2.255 | 10.86.1.2, 10.86.1.3 | k45.com       |
| 3       | /24    | 10.86.3.1 | 10.86.3.255 | 10.86.1.2, 10.86.1.3 | k45.com       |

#### Pemeriksaan di tengen

Langkah 2:

```sh
grep -E "^lease|starts|ends|hardware ethernet" /var/lib/dhcp/dhcpd.leases | tail -40
```

**Hasil:**

- itadori (Network 2) memperoleh `10.86.2.10/24`, `brd 10.86.2.255`, `default via 10.86.2.1`, serta DNS dan domain-search sesuai tabel.
- ino (Network 3) memperoleh `10.86.3.10/24`, `brd 10.86.3.255`, `default via 10.86.3.1`, serta DNS dan domain-search sesuai tabel.
- Durasi lease di `dhcpd.leases` sesuai kebijakan. ino dan kusakabe berlaku 30 menit (contoh: `05:00:06` sampai `05:30:06`), miwa berlaku 12 jam (`05:00:26` sampai `17:00:26`), dan client Divisi A berlaku 10 menit.
- Setiap alamat hanya dipegang satu MAC, dan tidak ada alamat pada rentang `10.86.2.36` sampai `10.86.2.69` maupun `10.86.3.90` sampai `10.86.3.98`. kugisaki tidak tercantum karena memakai fixed address (lihat soal 6).
- Pada pengujian ini ino menampilkan `lease time 1426`. Nilai tersebut adalah sisa waktu lease yang masih aktif, karena tengen memberikan kembali lease yang sama. Durasi penuhnya tetap 1800 detik sebagaimana terlihat pada nilai `starts` dan `ends`.

![](assets/soal7-client-n2.png)



![](assets/soal7-client-n3.png)



![](assets/soal7-tengen-leases.png)

**Script:** `scripts/soal07.sh`, dijalankan di client terlebih dahulu, kemudian di tengen.

---

### SOAL 8

**Diminta:** melakukan packet capture menggunakan `tcpdump` saat client Network 2 atau Network 3 meminta lease baru untuk menunjukkan urutan DHCPDISCOVER, DHCPOFFER, DHCPREQUEST, dan DHCPACK, serta mengidentifikasi alamat server, alamat yang diberikan, lease time, dan field `giaddr`.

#### Capture di tengen

Langkah 1, memasang tcpdump:

```sh
apt-get install -y tcpdump
```

Langkah 2, menjalankan capture selama 40 detik:

```sh
timeout 40 tcpdump -ni eth0 -s0 -U -w /root/soal08-dora.pcap 'udp port 67 or udp port 68'
```

#### Permintaan lease dari itadori

Langkah 3, dijalankan selama capture masih berlangsung:

```sh
ip addr flush dev eth0
udhcpc -i eth0 -n -q
```

#### Pembacaan hasil di tengen

Langkah 4:

```sh
tcpdump -nvvv -r /root/soal08-dora.pcap | grep -E "BOOTP/DHCP|Gateway-IP|Your-IP|DHCP-Message|Server-ID|Lease-Time"
```

Langkah 5:

```sh
tcpdump -nvvv -r /root/soal08-dora.pcap | grep Gateway-IP | sort -u
```

**Hasil:**

Capture menangkap empat paket dengan `xid 0x7ac73e23` yang sama, sehingga keempatnya merupakan satu transaksi:

| Pesan    | Arah                           | Isi penting                                                              |
| -------- | ------------------------------ | ------------------------------------------------------------------------ |
| Discover | `10.86.4.1.67 > 10.86.4.10.67` | `Request from 02:42:97:40:66:00` (itadori), `Gateway-IP 10.86.2.1`       |
| Offer    | `10.86.4.10.67 > 10.86.2.1.67` | `Your-IP 10.86.2.10`, `Server-ID 10.86.4.10`, `Lease-Time 600`           |
| Request  | `10.86.4.1.67 > 10.86.4.10.67` | `Server-ID 10.86.4.10`, `Gateway-IP 10.86.2.1`                           |
| ACK      | `10.86.4.10.67 > 10.86.2.1.67` | `Your-IP 10.86.2.10`, `Server-ID 10.86.4.10`, `Lease-Time 600`           |

- Alamat server adalah `10.86.4.10` (tengen).
- Alamat yang diberikan adalah `10.86.2.10`.
- Lease time adalah `600` detik.
- Nilai `giaddr` adalah `10.86.2.1`, sesuai dengan eth2 jichi yang menerima request dari Network 2.
- Paket yang terlihat di tengen merupakan unicast antara relay dan server. Relay mengirim dari alamat eth4 (`10.86.4.1`), sedangkan balasan server ditujukan ke alamat `giaddr`.

![](assets/soal8-capture-jalan.png)



![](assets/soal8-capture-dora.png)



![](assets/soal8-giaddr.png)

**Script:** `scripts/soal08.sh`, dijalankan di tengen, kemudian di client selama capture berlangsung.

---

### SOAL 9

**Diminta:** menghentikan service DHCP Relay di jichi, memaksa client Network 2 atau Network 3 meminta lease baru dan mencatat gejalanya, memulihkan relay, lalu membuktikan client kembali memperoleh alamat dari pool yang benar dengan gateway semula. Pengujian memakai zenin.

Langkah 1, menghentikan relay di jichi:

```sh
service isc-dhcp-relay stop
ps aux | grep [d]hcrelay
```

Langkah 2, meminta lease di zenin:

```sh
ip addr flush dev eth0
udhcpc -i eth0 -n -q -t 3 -T 2
ip addr show dev eth0
ip route
```

Langkah 3, memulihkan relay di jichi:

```sh
service isc-dhcp-relay restart
ps aux | grep [d]hcrelay
```

Langkah 4, mengulangi permintaan lease di zenin:

```sh
ip addr flush dev eth0
udhcpc -i eth0 -n -q
ip addr show dev eth0
ip route
```

**Hasil:**

- Setelah relay dihentikan, proses lama tampil sebagai `[dhcrelay]` dengan status `Ds` dan memori `0`, yang menandakan proses sedang berakhir. Saat relay dijalankan ulang muncul pesan `failed to kill 490: No such process`, yang menegaskan proses tersebut sudah tidak ada.
- Selama relay mati, zenin mengirim tiga kali `broadcasting discover` lalu berakhir dengan `no lease, failing`. eth0 tidak memiliki alamat IPv4 dan tidak ada default route.
- Setelah relay dijalankan ulang dengan PID baru `525`, zenin memperoleh `10.86.2.70` dari `10.86.4.10`, yaitu alamat di Pool 2, dengan `default via 10.86.2.1` seperti semula.

![](assets/soal9-relay-stop.png)



![](assets/soal9-client-gagal.png)



![](assets/soal9-relay-start.png)



![](assets/soal9-client-pulih.png)

**Script:** `scripts/soal09.sh`, dijalankan di jichi dengan argumen `stop` dan `start`, serta di client tanpa argumen.

---

### SOAL 10

**Diminta:** mengaktifkan autostart DHCP Server di tengen dan DHCP Relay di jichi, menjalankan ulang kedua node, lalu memverifikasi status layanan, IP, gateway, lease, dan konektivitas client Network 2 dan 3 dengan kebijakan pool, short lease, long lease, dan fixed address yang tetap berlaku.

Container Docker di GNS3 tidak menjalankan init system secara lengkap, sehingga pendaftaran dengan `update-rc.d` belum cukup untuk menyalakan service ketika node dijalankan. Karena itu autostart dipasang dalam dua lapis, yaitu pendaftaran `update-rc.d` dan perintah `service ... start` di `/root/.bashrc`. Perintah tersebut dijalankan ketika console node dibuka, setelah `/root/net.sh` memulihkan konfigurasi jaringan.

#### Konfigurasi jichi

Langkah 1, menyimpan konfigurasi jaringan agar kembali setelah restart:

```sh
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
```

Langkah 2, autostart DHCP Relay:

```sh
update-rc.d isc-dhcp-relay defaults
update-rc.d isc-dhcp-relay enable
grep -q "isc-dhcp-relay start" /root/.bashrc || echo "service isc-dhcp-relay start >/dev/null 2>&1" >> /root/.bashrc
tail -5 /root/.bashrc
```

#### Konfigurasi tengen

Langkah 3, menyimpan konfigurasi jaringan:

```sh
cat > /root/net.sh <<'EOF'
#!/bin/sh
ip addr add 10.86.4.10/24 dev eth0 2>/dev/null
ip link set eth0 up
ip route replace default via 10.86.4.1
echo "nameserver 192.168.122.1" > /etc/resolv.conf
EOF
grep -q "sh /root/net.sh" /root/.bashrc || echo "sh /root/net.sh" >> /root/.bashrc
```

Langkah 4, autostart DHCP Server:

```sh
update-rc.d isc-dhcp-server defaults
update-rc.d isc-dhcp-server enable
grep -q "isc-dhcp-server start" /root/.bashrc || echo "service isc-dhcp-server start >/dev/null 2>&1" >> /root/.bashrc
tail -5 /root/.bashrc
```

#### Restart dan verifikasi

Langkah 5, jichi dan tengen dihentikan lalu dijalankan kembali melalui GNS3 (Stop, kemudian Start).

Langkah 6, console jichi dibuka terlebih dahulu, kemudian console tengen, agar `/root/.bashrc` dijalankan.

Langkah 7, verifikasi di jichi:

```sh
ip -br a
ip route
sysctl net.ipv4.ip_forward
iptables -t nat -L POSTROUTING -n -v
ps aux | grep [d]hcrelay
```

Langkah 8, verifikasi di tengen:

```sh
ip -br a
ip route
service isc-dhcp-server status
ss -ulnp | grep ':67'
```

Langkah 9, verifikasi di client Network 2 dan Network 3 (itadori, zenin, ino, miwa, kugisaki):

```sh
ip addr flush dev eth0
udhcpc -i eth0 -n -q
ip addr show dev eth0
ip route
```

**Hasil:**

- `/root/.bashrc` jichi memuat pemanggilan `/root/net.sh` dan `service isc-dhcp-relay start`.
- Setelah restart, jichi kembali memiliki eth0 `192.168.122.52`, eth1 sampai eth4 `10.86.x.1`, forwarding `1`, dan satu aturan `MASQUERADE` dengan penghitung kembali `0`. Proses `dhcrelay` berjalan dengan PID baru `103` tanpa dijalankan secara manual.
- tengen kembali memegang `10.86.4.10` dengan `default via 10.86.4.1`, `dhcpd is running` dengan PID baru `85`, dan port UDP `67` terbuka.
- itadori kembali memperoleh `10.86.2.10` (Pool 1) dan ino memperoleh `10.86.3.10` dengan `lease time 1800`, sehingga kebijakan alokasi tetap berlaku setelah restart.

![](assets/soal10-autostart.png)



![](assets/soal10-jichi-setelah-restart.png)



![](assets/soal10-tengen-setelah-restart.png)



![](assets/soal10-client-setelah-restart.png)

**Script:** `scripts/soal10.sh`, dijalankan tanpa argumen untuk mengaktifkan autostart dan dengan argumen `check` untuk verifikasi setelah restart.

---

## Kendala dan Penanganan

| Kendala | Penyebab | Penanganan |
| ------- | -------- | ---------- |
| eth0 jichi tidak memperoleh alamat dan `ping 192.168.122.1` menghasilkan `Destination Host Unreachable` | Node NAT1 tidak menjawab ARP | NAT1 dijalankan ulang, setelah itu eth0 memperoleh `192.168.122.52` dari DHCP NAT |
| utahime tidak dapat menjangkau gateway `10.86.1.1` meskipun IP dan route sudah benar | Switch1 belum berjalan sehingga frame tidak diteruskan | Switch1 dan seluruh node dijalankan ulang |
| Perintah `ifup eth0` menghasilkan `command not found` | Image `debinet` tidak menyertakan `ifupdown` | eth0 memakai alamat dari `udhcpc` yang dijalankan saat boot |
| `ip addr add` menampilkan `Address already assigned` | Alamat sudah terpasang sebelumnya | Diganti dengan `ip addr replace` |
| Client memperoleh lease time tidak wajar ketika langkah diulang | Lease dari tahap sebelumnya masih tersimpan | Lease dikosongkan pada soal 2, 4, dan 5 |
| kugisaki tidak muncul di `dhcpd.leases` | Host dengan `fixed-address` tidak disimpan sebagai lease dinamis | Pembuktian dilakukan dari sisi client |

---

### SOAL 11

Diminta: Mengonfigurasi arsitektur DNS Master-Slave menggunakan BIND9 untuk domain jujutsu.k45.com dengan utahime (10.86.1.2) sebagai DNS Master dan shoko (10.86.1.3) sebagai DNS Slave. Memastikan transfer zona otomatis berfungsi ketika nomor serial diperbarui, serta membuktikan bahwa client infrastruktur dapat melakukan query DNS ke kedua server dengan sukses.

Konsep dasar Master-Slave menempatkan utahime sebagai pusat data utama (buku induk) yang menyimpan berkas zona asli, sedangkan shoko bertindak sebagai salinan resmi (slave) yang secara otomatis menyinkronkan data zona dari Master menggunakan nomor serial (SOA) dan mekanisme notify.

Konfigurasi Utahime (DNS Master)
Langkah-langkah berikut dikerjakan pada node utahime untuk menyiapkan peran sebagai DNS Master.

Langkah 1, Menyiapkan Resolver dan Memasang BIND9:
Mengonfigurasi /etc/resolv.conf agar dapat mengakses internet, melakukan pembaruan paket, lalu memasang paket BIND9 beserta utilitas pendukungnya.

Bash
echo "nameserver 192.168.122.1" > /etc/resolv.conf
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y bind9 bind9utils dnsutils
Langkah 2, Mengonfigurasi Opsi dan Zona Master:
Mengatur /etc/bind/named.conf.options agar server mendengarkan seluruh interface dan mengizinkan query. Selanjutnya, mendefinisikan zona jujutsu.k45.com sebagai master pada /etc/bind/named.conf.local, lengkap dengan direktif allow-transfer dan also-notify yang mengarah ke IP Shoko (10.86.1.3).

Bash
```
cat > /etc/bind/named.conf.options <<'EOT'
options {
    directory "/var/cache/bind";
    listen-on { any; };
    allow-query { any; };
    allow-recursion { any; };
    dnssec-validation no;
};
EOT

mkdir -p /etc/bind/zones
cat > /etc/bind/named.conf.local <<'EOT'
zone "jujutsu.k45.com" {
    type master;
    file "/etc/bind/zones/db.jujutsu.k45.com";
    allow-transfer { 10.86.1.3; };
    also-notify { 10.86.1.3; };
    notify yes;
};
EOT
```

Langkah 3, Membuat Berkas Database Zona:
Membuat berkas zona db.jujutsu.k45.com yang mendefinisikan record SOA, NS untuk master (ns1) dan slave (ns2), serta pemetaan IP masing-masing.

Bash
```
cat > /etc/bind/zones/db.jujutsu.k45.com <<'EOT'
$TTL 604800
@   IN  SOA ns1.jujutsu.k45.com. admin.jujutsu.k45.com. (
            2026101301 ; Serial
            604800     ; Refresh
            86400      ; Retry
            2419200    ; Expire
            604800 )   ; Negative Cache TTL

@       IN  NS  ns1.jujutsu.k45.com.
@       IN  NS  ns2.jujutsu.k45.com.
ns1     IN  A   10.86.1.2
ns2     IN  A   10.86.1.3
EOT
```
Langkah 4, Memvalidasi Konfigurasi dan Menjalankan Service:
Memeriksa kesalahan sintaks pada konfigurasi dan zona, lalu memulai ulang service BIND9.

Bash
```
named-checkconf
named-checkzone jujutsu.k45.com /etc/bind/zones/db.jujutsu.k45.com
service named restart || service bind9 restart
```

Konfigurasi Shoko (DNS Slave)
Langkah-langkah berikut dikerjakan pada node shoko untuk menyiapkan peran sebagai DNS Slave.

Langkah 5, Mengonfigurasi Node Shoko sebagai Slave:
Memasang BIND9 di Shoko, lalu mengatur /etc/bind/named.conf.local dengan tipe slave serta menunjuk master ke IP 10.86.1.2. Direktif file diarahkan ke direktori /var/lib/bind/ agar slave memiliki hak tulis untuk menyimpan salinan zona.

Bash
```
echo "nameserver 192.168.122.1" > /etc/resolv.conf
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y bind9 bind9utils dnsutils

cat > /etc/bind/named.conf.options <<'EOT'
options {
    directory "/var/cache/bind";
    listen-on { any; };
    allow-query { any; };
    allow-recursion { any; };
    dnssec-validation no;
};
EOT

cat > /etc/bind/named.conf.local <<'EOT'
zone "jujutsu.k45.com" {
    type slave;
    masters { 10.86.1.2; };
    file "/var/lib/bind/db.jujutsu.k45.com";
};
EOT

mkdir -p /var/lib/bind && chown -R bind:bind /var/lib/bind
named-checkconf
service named restart || service bind9 restart
```

Verifikasi dan Pengujian

Langkah 6, Memeriksa Sinkronisasi Awal di Shoko:
Memeriksa apakah berkas zona berhasil tersalin secara otomatis oleh slave serta mengecek nomor serial SOA awal.

Bash
```
ls -l /var/lib/bind/
dig @10.86.1.3 jujutsu.k45.com SOA +short
```
<img width="585" height="76" alt="Screenshot 2026-10-13 at 21 49 25" src="https://github.com/user-attachments/assets/b74ca513-4733-4c39-8c9f-cdac5c465832" />

Langkah 7, Menguji Replikasi Otomatis (Perubahan Serial):
Mengubah nomor serial pada berkas zona di utahime, lalu melakukan reload dengan rndc. Setelah itu, memeriksa apakah shoko otomatis memperbarui nomor serialnya.

Bash
```
# Dijalankan di utahime:
sed -i 's/2026101301/2026101302/' /etc/bind/zones/db.jujutsu.k45.com
rndc reload

# Dijalankan di shoko (beberapa detik kemudian):
dig @10.86.1.3 jujutsu.k45.com SOA +short
```
<img width="589" height="31" alt="Screenshot 2026-10-13 at 21 51 00" src="https://github.com/user-attachments/assets/266086d2-ffa4-4bae-a9fe-ca08f4092b09" />

Langkah 8, Menguji Query dari Client (Itadori):
Melakukan pengujian query record SOA dan NS dari node client itadori ke kedua server DNS (Master dan Slave).

Bash
```
dig @10.86.1.2 jujutsu.k45.com SOA
dig @10.86.1.3 jujutsu.k45.com SOA
dig @10.86.1.2 jujutsu.k45.com NS +short
dig @10.86.1.3 jujutsu.k45.com NS +short
```
<img width="525" height="104" alt="Screenshot 2026-10-13 at 21 53 03" src="https://github.com/user-attachments/assets/27242dad-5194-4668-9817-2ef3560e2f42" />
<img width="503" height="93" alt="Screenshot 2026-10-13 at 21 53 28" src="https://github.com/user-attachments/assets/3845d965-1baa-4043-a1e1-e2ed1a1e20c9" />

Hasil:
utahime berhasil bertindak sebagai DNS Master dan shoko berhasil bertindak sebagai DNS Slave untuk domain jujutsu.k45.com.

Berkas zona berhasil ditransfer secara otomatis dari Master ke Slave saat service berjalan.

Perubahan nomor serial pada Master berhasil direplikasi secara instan ke Slave tanpa intervensi manual di sisi Slave.

Client berhasil melakukan query record SOA dan NS ke kedua server dengan hasil yang valid dan konsisten.

Script: scripts/soal11.sh, dijalankan di node utahime dan shoko.

---

### SOAL 12

Diminta: Mengonfigurasi pemetaan domain utama pada utahime dengan membuat record A untuk jujutsu.k45.com yang mengarah ke IP gojo (10.86.1.4) serta record CNAME untuk www. Membuat Reverse DNS (zona PTR) untuk melacak IP Gojo kembali ke domain resminya, serta mengaktifkan fitur DNS Forwarder pada BIND9 mengarah ke IP gateway internet (192.168.122.1). Terakhir, membuktikan fungsionalitasnya melalui dig (untuk CNAME dan PTR) serta ping ke domain internet seperti google.com dari sisi client.   

Langkah-Langkah Pengerjaan & Eksekusi ScriptScript otomatisasi ini dijalankan pada node utahime (10.86.1.2) untuk memperbarui konfigurasi BIND9, menambahkan zona reverse, serta mengaktifkan forwarder.

Langkah 1, Membuat dan Menjalankan Script Otomatisasi di Utahime

:Buat file script /root/soal12.sh di node utahime:

Bash
```
cat > /root/soal12.sh << 'EOF'
#!/bin/sh

# 1. Update named.conf.options dengan menambahkan forwarders ke 192.168.122.1
cat > /etc/bind/named.conf.options <<'EOT'
options {
    directory "/var/cache/bind";
    listen-on { any; };
    allow-query { any; };
    allow-recursion { any; };
    forwarders { 192.168.122.1; };
    dnssec-validation no;
};
EOT

# 2. Tambahkan zona reverse (PTR) ke named.conf.local jika belum ada
if ! grep -q "1.86.10.in-addr.arpa" /etc/bind/named.conf.local; then
    cat >> /etc/bind/named.conf.local <<'EOT'

zone "1.86.10.in-addr.arpa" {
    type master;
    file "/etc/bind/zones/db.10.86.1";
};
EOT
fi

# 3. Perbarui berkas zona utama dengan A record ke Gojo (10.86.1.4) dan CNAME www
cat > /etc/bind/zones/db.jujutsu.k45.com <<'EOT'
$TTL 604800
@   IN  SOA ns1.jujutsu.k45.com. admin.jujutsu.k45.com. (
            2026101303 ; Serial
            604800     ; Refresh
            86400      ; Retry
            2419200    ; Expire
            604800 )   ; Negative Cache TTL

@       IN  NS  ns1.jujutsu.k45.com.
@       IN  NS  ns2.jujutsu.k45.com.
ns1     IN  A   10.86.1.2
ns2     IN  A   10.86.1.3

@       IN  A   10.86.1.4
www     IN  CNAME jujutsu.k45.com.
EOT

# 4. Buat berkas database Reverse DNS (PTR) untuk IP Gojo (.4)
cat > /etc/bind/zones/db.10.86.1 <<'EOT'
$TTL 604800
@   IN  SOA ns1.jujutsu.k45.com. admin.jujutsu.k45.com. (
            2026101301 ; Serial
            604800     ; Refresh
            86400      ; Retry
            2419200    ; Expire
            604800 )   ; Negative Cache TTL

@       IN  NS  ns1.jujutsu.k45.com.
4       IN  PTR jujutsu.k45.com.
EOT

# 5. Validasi konfigurasi dan restart service bind9
named-checkconf
named-checkzone jujutsu.k45.com /etc/bind/zones/db.jujutsu.k45.com
named-checkzone 1.86.10.in-addr.arpa /etc/bind/zones/db.10.86.1
service named restart || service bind9 restart
EOF

sh /root/soal12.sh
```

Verifikasi dan Pengujian
Langkah 2, Menguji Resolusi Domain dan CNAME dari Client (Itadori):

Bash
```
dig jujutsu.k45.com +short
dig www.jujutsu.k45.com +short
```
<img width="274" height="77" alt="Screenshot 2026-10-13 at 22 29 51" src="https://github.com/user-attachments/assets/cb6aba1f-536c-4064-996a-97699c007f3f" />

Langkah 3, Menguji Reverse DNS (PTR Lookup):

Bash
```
dig -x 10.86.1.4 +short
```
<img width="262" height="34" alt="Screenshot 2026-10-13 at 22 30 24" src="https://github.com/user-attachments/assets/c3f82f88-90aa-4d56-a876-93d7db2dc3ce" />
  
Langkah 4, Menguji DNS Forwarder dan Akses Internet:
Bash
```
dig google.com +short
ping -c 2 google.com
```
<img width="609" height="225" alt="Screenshot 2026-10-13 at 22 30 59" src="https://github.com/user-attachments/assets/eb58361f-062b-4eb7-85c4-160ad90a6c89" />  

Hasil: 
- Domain jujutsu.k45.com berhasil dipetakan ke IP gojo (10.86.1.4) dan www berhasil menjadi alias (CNAME).
- Zona Reverse (PTR) berhasil mengonversi IP 10.86.1.4 kembali ke nama domain resminya.
- Fitur DNS Forwarder aktif dan berhasil meneruskan query domain eksternal ke 192.168.122.1, memungkinkan client mengakses internet dengan lancar.

  
Script: scripts/soal12.sh, dijalankan di node utahime (10.86.1.2).

---

### SOAL 13

Diminta: Mengonfigurasi MariaDB Master-Slave Replication antara node yaga (10.86.4.8, Master) dan inumaki (10.86.4.9, Slave) menggunakan Global Transaction Identifier (GTID) berbasis string (slave_pos) pada jaringan jujutsu.k45.com (Subnet 10.86.4.0/24). Serta membuktikan fungsionalitas replikasi secara real-time melalui status thread I/O dan SQL slave.

Langkah-Langkah Pengerjaan & Eksekusi Script
Script otomatisasi ini dibagi menjadi dua berkas terpisah karena dijalankan pada dua node yang berbeda: scripts/soal13_master.sh di node yaga dan scripts/soal13_slave.sh di node inumaki.

Langkah 1, Membuat dan Menjalankan Script Otomatisasi di Master (yaga):
Buat file script /root/soal13_master.sh di node yaga:

Bash
```
cat > /root/soal13_master.sh << 'EOF'
#!/bin/sh

# 1. Konfigurasi master untuk binary log dan GTID
cat > /etc/mysql/mariadb.conf.d/99-replication.cnf <<'EOT'
[mysqld]
server-id = 1
log-bin = mysql-bin
binlog-format = ROW
gtid-domain-id = 1
EOT

# 2. Restart layanan MariaDB dan buat user replicator
systemctl restart mariadb || (pkill mysqld; mysqld --user=mysql &)
sleep 3

mysql -u root <<'EOT'
CREATE USER 'replicator'@'%' IDENTIFIED BY 'k45pass';
GRANT REPLICATION SLAVE ON *.* TO 'replicator'@'%';
FLUSH PRIVILEGES;
EOT
EOF

sh /root/soal13_master.sh
```

Langkah 2, Membuat dan Menjalankan Script Otomatisasi di Slave (inumaki):
Buat file script /root/soal13_slave.sh di node inumaki:

Bash
```
cat > /root/soal13_slave.sh << 'EOF'
#!/bin/sh

# 1. Pastikan konfigurasi jaringan interface aktif
ip addr replace 10.86.4.9/24 dev eth0
ip link set eth0 up
ip route replace default via 10.86.4.1

# 2. Buat direktori socket dan konfigurasi slave
mkdir -p /run/mysqld /etc/mysql/mariadb.conf.d/
chown mysql:mysql /run/mysqld

cat > /etc/mysql/mariadb.conf.d/99-replication.cnf <<'EOT'
[mysqld]
bind-address = 0.0.0.0
server-id = 2
relay-log = mysql-relay-bin
EOT

# 3. Jalankan daemon MariaDB
mysqld --user=mysql &
sleep 3

# 4. Hubungkan Slave ke Master menggunakan GTID slave_pos
mysql -u root <<'EOT'
STOP SLAVE;
RESET SLAVE ALL;
CHANGE MASTER TO
MASTER_HOST='10.86.4.8',
MASTER_USER='replicator',
MASTER_PASSWORD='k45pass',
MASTER_USE_GTID=slave_pos;
START SLAVE;
EOT
EOF

sh /root/soal13_slave.sh
```

Verifikasi dan Pengujian Langkah 3, Menguji Status Replikasi dari Slave (inumaki):

Bash
```
mysql -u root -e "SHOW SLAVE STATUS\G"
```
Hasil:

<img width="432" height="607" alt="Screenshot 2026-10-13 at 23 45 35" src="https://github.com/user-attachments/assets/89038e90-2c7a-48ac-92fa-950364f4e148" />

Master (yaga) berhasil mengaktifkan binary log dan membuat akun replicator dengan aman.

Slave (inumaki) berhasil terhubung ke master menggunakan GTID slave_pos.

Parameter Slave_IO_Running dan Slave_SQL_Running bernilai Yes, serta Seconds_Behind_Master bernilai 0 yang menandakan sinkronisasi data berjalan secara real-time tanpa kendala.

Script: scripts/soal13_master.sh, dijalankan di node yaga (10.86.4.8) dan scripts/soal13_slave.sh, dijalankan di node inumaki (10.86.4.9).

### SOAL 14
Diminta: Mengonfigurasi worker frontend (maki dan panda) menggunakan Nginx dan PHP-FPM untuk menyajikan halaman web yang menampilkan hostname masing-masing. Pada worker backend (nanami, todo, dan kirara), siapkan layanan API yang mencatat log request ke database yaga (10.86.4.8). Konfigurasikan virtual host agar worker merespons domain layanan, serta pastikan pembatasan akses langsung dari klien berjalan dengan benar.   

Langkah-Langkah Pengerjaan & Eksekusi ScriptScript otomatisasi ini dibagi menjadi dua berkas terpisah karena dijalankan pada node frontend dan backend yang berbeda di Data Center.

Langkah 1, Membuat dan Menjalankan Script Otomatisasi di Frontend Worker (maki dan panda):Buat file script /root/soal14_frontend.sh di node maki dan panda:

Bash
```
cat > /root/soal14_frontend.sh << 'EOF'
#!/bin/sh

# 1. Instalasi Nginx dan PHP-FPM
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y nginx php-fpm

# 2. Buat halaman web frontend yang menampilkan hostname masing-masing
cat > /var/www/html/index.php << 'EOT'
<?php
echo "Frontend Worker Hostname: " . gethostname();
?>
EOT

rm -f /var/www/html/index.html

# 3. Konfigurasi Nginx Virtual Host (PHP 8.4 socket)
cat > /etc/nginx/sites-available/default << 'EOT'
server {
    listen 80;
    server_name _;

    root /var/www/html;
    index index.php index.html index.htm;

    location / {
        try_files $uri $uri/ =404;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php8.4-fpm.sock;
    }
}
EOT

# 4. Bersihkan proses lama dan jalankan daemon manual (Non-systemd container)
pkill -9 nginx || true
pkill -9 php-fpm || true
/usr/sbin/php-fpm8.4 -D
nginx
EOF

sh /root/soal14_frontend.sh
```

Langkah 2, Membuat dan Menjalankan Script Otomatisasi di API Worker (nanami, todo, dan kirara):
Buat file script /root/soal14_api.sh di node nanami, todo, dan kirara:

Bash
```
cat > /root/soal14_api.sh << 'EOF'
#!/bin/sh

# 1. Instalasi Nginx, PHP, dan MariaDB Client
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y nginx php-fpm php-mysql mariadb-client

# 2. Buat endpoint API yang mencatat log request ke database yaga (10.86.4.8)
mkdir -p /var/www/html/api
cat > /var/www/html/api/index.php << 'EOT'
<?php
header('Content-Type: application/json');
$host = '10.86.4.8';
$user = 'replicator';
$pass = 'k45pass';
$db   = 'db_shibuya_K01'; // Sesuaikan nama kelompok

try {
    $conn = new mysqli($host, $user, $pass, $db);
    if (!$conn->connect_error) {
        $client_ip = $_SERVER['HTTP_X_REAL_IP'] ?? $_SERVER['REMOTE_ADDR'];
        $worker_host = gethostname();
        $sql = "INSERT INTO request_logs (client_ip, worker_node) VALUES ('$client_ip', '$worker_host')";
        @$conn->query($sql);
    }
} catch (Exception $e) {
    // Lanjutkan eksekusi agar JSON tetap terkirim
}

echo json_encode([
    "status" => "success",
    "worker" => gethostname(),
    "message" => "API request processed"
]);
?>
EOT

# 3. Konfigurasi Nginx Virtual Host API (PHP 8.4 socket)
cat > /etc/nginx/sites-available/default << 'EOT'
server {
    listen 80;
    server_name _;

    root /var/www/html;
    index index.php index.html;

    location / {
        try_files $uri $uri/ /api/index.php?$query_string;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php8.4-fpm.sock;
    }
}
EOT

# 4. Bersihkan proses lama dan jalankan daemon manual
pkill -9 nginx || true
pkill -9 php-fpm || true
/usr/sbin/php-fpm8.4 -D
nginx
EOF

sh /root/soal14_api.sh
```

Verifikasi dan Pengujian 

Langkah 3, Menguji Akses Web dan API Worker:
Bash
```
curl http://localhost
curl http://localhost/api/
```

Bukti Pengujian & Screenshot yang Diperlukan:

Uji Frontend Worker (maki / panda):

Jalankan: curl http://localhostPastikan output menampilkan: Frontend Worker Hostname: maki (atau panda).
<img width="304" height="33" alt="Screenshot 2026-10-14 at 00 26 21" src="https://github.com/user-attachments/assets/85a68426-d7ce-4a4c-bcf4-206273218e2c" />

Uji API Worker (nanami / todo / kirara):

Jalankan: curl http://localhost/api/ Pastikan output menampilkan respon JSON yang sukses.
<img width="366" height="21" alt="Screenshot 2026-10-14 at 00 28 37" src="https://github.com/user-attachments/assets/6aaebd38-6f49-4206-be19-22b29fe40513" />

Log Database di yaga:
Jalankan di yaga: mysql -u root -e "SELECT * FROM db_shibuya_K01.request_logs;
"Pastikan catatan request dari masing-masing worker masuk secara real-time.

Script: scripts/soal14_db.sh, dijalankan di node yaga (10.86.4.8), scripts/soal14_frontend.sh, dijalankan di node maki dan panda, dan scripts/soal14_api.sh, dijalankan di node nanami, todo, dan kirara.

### SOAL 15

Diminta: Mengonfigurasi Load Balancer pada node geto menggunakan Nginx dengan metode Weighted Round Robin (rasio 3:1 untuk nanami dan todo) untuk mendistribusikan trafik secara proporsional ke layanan API backend.

Langkah-Langkah Pengerjaan & Eksekusi Script
Script otomatisasi ini dijalankan pada node Load Balancer (geto) di Data Center.

Langkah 1, Membuat dan Menjalankan Script Otomatisasi di Load Balancer Worker (geto):
Buat file script /root/soal15_geto.sh di node geto:

Bash
```
cat > /root/soal15_geto.sh << 'EOF'
#!/bin/sh

#1. Instalasi Nginx

apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y nginx

#2. Konfigurasi Nginx Load Balancer dengan Weighted Round Robin (3:1)

cat > /etc/nginx/sites-available/default << 'EOT'
upstream api_cluster {
server 10.86.4.5 weight=3; # nanami
server 10.86.4.6 weight=1; # todo
}

server {
listen 80;
server_name _;

location / {
    proxy_pass http://api_cluster;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
}


}
EOT

#3. Bersihkan proses lama dan jalankan daemon Nginx

pkill -9 nginx || true
nginx
EOF

sh /root/soal15_geto.sh
```

Verifikasi dan Pengujian Langkah 2, Menguji Pembagian Beban (Load Balancing):
Bash

for i in {1..8}; do curl -s http://localhost/api/; echo; done

Bukti Pengujian & Screenshot yang Diperlukan:

Screenshot Uji Load Balancer di geto:

Jalankan: for i in {1..8}; do curl -s http://localhost/api/; echo; done

Pastikan output menampilkan respon dari nanami dan todo secara proporsional (rasio 3:1).

<img width="385" height="88" alt="Screenshot 2026-10-14 at 00 53 48" src="https://github.com/user-attachments/assets/cb93c979-cca7-4a00-9b8f-b11127b06d15" />

Screenshot Verifikasi Log Request di Database yaga:

Jalankan di yaga: mysql -u root -e "SELECT * FROM db_shibuya_K01.request_logs;"

Pastikan catatan request dari masing-masing worker tercatat dengan benar.

<img width="450" height="156" alt="Screenshot 2026-10-14 at 00 54 34" src="https://github.com/user-attachments/assets/1d65f589-063e-4136-baad-1f2ffadd9b3b" />

soal15_geto.sh dijalankan di node geto.

### SOAL 16

**Diminta:** Mengonfigurasi Nginx pada node Gojo (`10.86.1.4`) sebagai *reverse proxy* untuk domain `jujutsu.k45.com` dan `www.jujutsu.k45.com`. Request ke path utama (`/`) diteruskan ke frontend Maki (`10.86.4.3`) dan Panda (`10.86.4.4`) menggunakan metode *Round Robin*. Sementara itu, request ke path `/api` diteruskan ke Geto (`10.86.4.2`), yang berfungsi sebagai *load balancer* untuk API worker Nanami (`10.86.4.5`) dan Todo (`10.86.4.6`). Fungsionalitas konfigurasi dibuktikan melalui pengujian dari client Itadori.

### Langkah-Langkah Pengerjaan & Pengujian

Konfigurasi Nginx dilakukan pada node Gojo (`10.86.1.4`) untuk meneruskan request frontend ke Maki dan Panda serta request API ke Geto. Setelah konfigurasi diterapkan, pengujian dilakukan dari client Itadori.

**Langkah 1, Mengonfigurasi Nginx sebagai Reverse Proxy pada Gojo**

Konfigurasi Nginx pada Gojo diatur dengan dua jalur utama, yaitu `/` untuk frontend dan `/api` untuk API. Jalur frontend menggunakan metode *Round Robin* melalui upstream `frontend_cluster`, sedangkan jalur API diarahkan ke Geto.

Konfigurasi yang digunakan:

```
nginx
upstream frontend_cluster {
    server 10.86.4.3;
    server 10.86.4.4;
}

server {
    listen 80;
    server_name jujutsu.k45.com www.jujutsu.k45.com;

    location /api {
        proxy_pass http://10.86.4.2;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }

    location / {
        proxy_pass http://frontend_cluster;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

Konfigurasi tersebut diterapkan pada `/etc/nginx/sites-available/default` di node Gojo, kemudian divalidasi menggunakan `nginx -t` dan Nginx dijalankan kembali.

**Screenshot 1 — Konfigurasi dan Validasi Nginx**
<img width="484" height="50" alt="Screenshot 2026-10-14 at 23 15 50" src="https://github.com/user-attachments/assets/c5150fde-2ae3-4227-b2be-07b5b4c98a17" />

**Langkah 2, Menguji Resolusi Domain dari Client (Itadori)**

Pengujian dilakukan untuk memastikan domain utama dan domain `www` dapat diresolusikan ke alamat IP Gojo (`10.86.1.4`).

Jalankan perintah berikut pada client Itadori:

```bash
getent hosts jujutsu.k45.com
getent hosts www.jujutsu.k45.com
```

Hasil yang diharapkan adalah kedua domain mengarah ke IP `10.86.1.4`, sehingga request client dapat diteruskan ke Nginx pada Gojo.

**Screenshot 2 — Pengujian Resolusi Domain**
<img width="510" height="63" alt="Screenshot 2026-10-14 at 23 16 28" src="https://github.com/user-attachments/assets/d1350be8-b40e-46d7-bb9b-bf2025c72506" />

**Langkah 3, Menguji Reverse Proxy Frontend**

Pengujian dilakukan untuk memastikan request ke domain utama diteruskan oleh Gojo ke frontend Maki dan Panda.

Jalankan perintah berikut pada client Itadori:

```bash
curl -i http://jujutsu.k45.com/
```

Untuk menguji pembagian request ke kedua frontend, jalankan beberapa request secara berurutan:

```bash
for i in 1 2 3 4; do
    curl -s http://jujutsu.k45.com/
    echo
done
```

Hasil yang diharapkan adalah respons HTTP `200 OK`. Respons dari beberapa request memperlihatkan hostname `maki` dan `panda`, yang membuktikan bahwa request didistribusikan ke kedua frontend menggunakan metode *Round Robin*.

**Screenshot 3 — Pengujian Frontend dan Round Robin**
<img width="441" height="258" alt="Screenshot 2026-10-14 at 23 17 10" src="https://github.com/user-attachments/assets/2e03beb5-2af3-4f2e-9bf6-d2cf60db0d61" />

**Langkah 4, Menguji Reverse Proxy API melalui Geto**

Pengujian dilakukan untuk memastikan request ke path `/api` diteruskan oleh Gojo ke Geto (`10.86.4.2`), kemudian diproses oleh API worker Nanami atau Todo sesuai konfigurasi *load balancing* pada Soal 15.

Jalankan perintah berikut pada client Itadori:

```bash
curl -i http://jujutsu.k45.com/api/
```

Hasil yang diharapkan adalah respons HTTP `200 OK` dengan keluaran JSON yang menunjukkan request berhasil diproses oleh worker API.

**Screenshot 4 — Pengujian API**
<img width="347" height="227" alt="Screenshot 2026-10-14 at 23 17 43" src="https://github.com/user-attachments/assets/c8566587-4674-4d3f-ac7d-977a9dbc3acc" />

### Hasil

- Nginx pada Gojo berhasil dikonfigurasi sebagai *reverse proxy* untuk domain `jujutsu.k45.com` dan `www.jujutsu.k45.com`.
- Request ke path `/` berhasil diteruskan ke frontend Maki (`10.86.4.3`) dan Panda (`10.86.4.4`) menggunakan metode *Round Robin*.
- Request ke path `/api` berhasil diteruskan ke Geto (`10.86.4.2`), yang kemudian mendistribusikan request ke API worker Nanami atau Todo.
- Pengujian dari client Itadori membuktikan bahwa resolusi domain, jalur frontend, dan jalur API berfungsi sesuai konfigurasi.

Script: `scripts/soal16_gojo.sh`, dijalankan di node Gojo (`10.86.1.4`).

# SOAL 17

**Diminta:** Mengonfigurasi penerusan IP asli client melalui reverse proxy Gojo (`10.86.1.4`) dan load balancer Geto (`10.86.4.2`) menuju worker API Nanami (`10.86.4.5`) atau Todo (`10.86.4.6`). Konfigurasi harus memastikan bahwa header IP client hanya dipercaya dari proxy yang tepercaya, kemudian IP asli client dicatat ke database `db_shibuya_K45` pada node Yaga (`10.86.4.8`). Pengujian dilakukan dari client Itadori dan Ino untuk memastikan IP yang dicatat bukan IP milik Geto.

## Langkah-Langkah Pengerjaan & Eksekusi Script

Script konfigurasi dijalankan pada node yang bersangkutan: Gojo untuk reverse proxy, Geto untuk trusted proxy dan load balancer, serta Nanami dan Todo untuk validasi IP pada aplikasi API. Itadori dan Ino digunakan untuk pengujian, sedangkan Yaga digunakan untuk memeriksa hasil pencatatan database.

### Langkah 1, Membuat dan Menjalankan Script pada Gojo

Script ini dijalankan pada node **Gojo (`10.86.1.4`)** untuk memastikan request API diteruskan ke Geto dengan membawa IP asli client melalui header `X-Real-IP`.

Buat file `/root/soal17_gojo.sh`:

**Bash**

```bash
cat > /root/soal17_gojo.sh <<'EOF'
#!/bin/bash
set -e

# 1. Backup konfigurasi awal jika backup belum tersedia
if [ -f /etc/nginx/sites-available/default ] && \
   [ ! -f /etc/nginx/sites-available/default.bak.soal17 ]; then
    cp /etc/nginx/sites-available/default \
       /etc/nginx/sites-available/default.bak.soal17
fi

# 2. Pastikan lokasi /api diteruskan ke Geto
# Pertahankan konfigurasi lokasi lain yang sudah ada.
CONFIG=/etc/nginx/sites-available/default

if ! grep -q 'location /api' "$CONFIG"; then
    echo "ERROR: location /api belum ditemukan."
    echo "Tambahkan konfigurasi API secara manual ke server block yang benar."
    exit 1
fi

echo "Periksa konfigurasi API:"
grep -A 8 'location /api' "$CONFIG"

# 3. Validasi konfigurasi
nginx -t

# 4. Muat ulang Nginx
systemctl reload nginx

echo "Verifikasi konfigurasi Gojo selesai."
EOF

chmod +x /root/soal17_gojo.sh
bash /root/soal17_gojo.sh
```

Pastikan konfigurasi `location /api` pada Gojo memiliki pengaturan berikut:

```nginx
location /api {
    proxy_pass http://10.86.4.2;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
}
```

**Catatan:** Script Gojo di atas memeriksa konfigurasi yang sudah ada dan tidak menambahkan ulang blok `location /api`. Jika konfigurasi belum sesuai, perbaiki blok tersebut terlebih dahulu, lalu jalankan `nginx -t` dan `systemctl reload nginx`.

### Langkah 2, Membuat dan Menjalankan Script pada Geto

Script ini dijalankan pada node **Geto (`10.86.4.2`)** untuk mengonfigurasi trusted proxy dari Gojo dan load balancing ke Nanami serta Todo.

Buat file `/root/soal17_geto.sh`:

**Bash**

```bash
cat > /root/soal17_geto.sh <<'EOF'
#!/bin/bash
set -e

# 1. Memastikan Nginx tersedia
if ! command -v nginx >/dev/null 2>&1; then
    apt-get update
    apt-get install -y nginx
fi

# 2. Backup konfigurasi awal
if [ -f /etc/nginx/sites-available/default ] && \
   [ ! -f /etc/nginx/sites-available/default.bak.soal17 ]; then
    cp /etc/nginx/sites-available/default \
       /etc/nginx/sites-available/default.bak.soal17
fi

# 3. Hanya mempercayai header dari Gojo
cat > /etc/nginx/conf.d/soal17-trusted-proxy.conf <<'EOT'
map $remote_addr $verified_client_ip {
    default $remote_addr;
    10.86.1.4 $http_x_real_ip;
}
EOT

# 4. Mengonfigurasi load balancer API
cat > /etc/nginx/sites-available/default <<'EOT'
upstream api_cluster {
    server 10.86.4.5:80 weight=3;
    server 10.86.4.6:80 weight=1;
}

server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name jujutsu.k45.com www.jujutsu.k45.com _;

    location / {
        proxy_pass http://api_cluster;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $verified_client_ip;
        proxy_set_header X-Forwarded-For $verified_client_ip;
    }
}
EOT

# 5. Validasi dan reload Nginx
nginx -t

if systemctl is-active --quiet nginx; then
    systemctl reload nginx
else
    systemctl enable --now nginx
fi

echo "Konfigurasi Geto selesai."
EOF

chmod +x /root/soal17_geto.sh
bash /root/soal17_geto.sh
```

### Langkah 3, Memastikan Validasi IP Client pada Nanami

Script ini dijalankan pada node **Nanami (`10.86.4.5`)**. Sebelum mengubah aplikasi, periksa dahulu kode API yang sudah tersedia dan pastikan aplikasi hanya menerima header `X-Real-IP` dari Geto.

Buat file pemeriksaan `/root/soal17_nanami.sh`:

**Bash**

```bash
cat > /root/soal17_nanami.sh <<'EOF'
#!/bin/bash
set -e

echo "Alamat IP Nanami:"
ip -br addr

echo
echo "Mencari validasi IP pada aplikasi API:"
grep -RniE 'HTTP_X_REAL_IP|REMOTE_ADDR|FILTER_VALIDATE_IP' \
    /var/www/html --include='*.php' || true

echo
echo "Pastikan aplikasi hanya menerima X-Real-IP jika REMOTE_ADDR adalah Geto."
EOF

chmod +x /root/soal17_nanami.sh
bash /root/soal17_nanami.sh
```

Kode PHP pada endpoint API harus menerapkan logika validasi seperti berikut:

```php
$remote = $_SERVER['REMOTE_ADDR'] ?? '';
$forwarded = $_SERVER['HTTP_X_REAL_IP'] ?? '';

$client = (
    $remote === '10.86.4.2' &&
    filter_var($forwarded, FILTER_VALIDATE_IP)
)
    ? $forwarded
    : $remote;
```

Variabel `$client` harus digunakan sebagai nilai `client_ip` saat menyimpan log request ke database. Jika kode aplikasi belum menerapkan logika tersebut, perbaiki file PHP endpoint yang benar sebelum pengujian. Script pemeriksaan di atas tidak mengubah kode aplikasi secara otomatis.

### Langkah 4, Memastikan Validasi IP Client pada Todo

Script ini dijalankan pada node **Todo (`10.86.4.6`)** untuk memeriksa agar worker kedua menggunakan mekanisme validasi IP yang sama dengan Nanami.

Buat file `/root/soal17_todo.sh`:

**Bash**

```bash
cat > /root/soal17_todo.sh <<'EOF'
#!/bin/bash
set -e

echo "Alamat IP Todo:"
ip -br addr

echo
echo "Mencari validasi IP pada aplikasi API:"
grep -RniE 'HTTP_X_REAL_IP|REMOTE_ADDR|FILTER_VALIDATE_IP' \
    /var/www/html --include='*.php' || true

echo
echo "Pastikan aplikasi hanya menerima X-Real-IP jika REMOTE_ADDR adalah Geto."
EOF

chmod +x /root/soal17_todo.sh
bash /root/soal17_todo.sh
```

Jika Todo memiliki kode endpoint API sendiri, pastikan kode tersebut juga menerapkan validasi IP seperti pada Langkah 3.

### Langkah 5, Menguji IP Asli Client dari Itadori

Pengujian dijalankan pada node **Itadori (`10.86.2.10`)** untuk memastikan IP client Network 2 diteruskan sampai API.

**Bash**

```bash
curl -i --max-time 10 http://jujutsu.k45.com/api/
```

Periksa respons API. Nilai `client_ip` yang diharapkan adalah `10.86.2.10`, bukan `10.86.4.2`.

### Langkah 6, Menguji IP Asli Client dari Ino

Pengujian dijalankan pada node **Ino** untuk memeriksa penerusan IP client dari Network 3.

**Bash**

```bash
ip -br addr
curl -i --max-time 10 http://jujutsu.k45.com/api/
```

Cocokkan nilai `client_ip` pada respons API dengan alamat IP Ino yang terlihat pada hasil `ip -br addr`.

### Langkah 7, Memverifikasi Log Database pada Yaga

Verifikasi dijalankan pada node **Yaga (`10.86.4.8`)** untuk memastikan request dari client tercatat dengan IP asli dan nama worker API yang memprosesnya.

**Bash**

```bash
mariadb -u root db_shibuya_K45 -e "
SELECT id, client_ip, worker_node, created_at
FROM request_logs
ORDER BY id DESC
LIMIT 10;"
```

Periksa entri terbaru setelah pengujian dari Itadori dan Ino. IP pada kolom `client_ip` harus sesuai dengan IP client yang mengirim request, bukan IP Geto.

## Hasil

- Gojo meneruskan request API ke Geto dengan membawa header `X-Real-IP`.
- Geto dikonfigurasi sebagai load balancer menuju Nanami dan Todo dengan bobot masing-masing `3` dan `1`.
- Nanami dan Todo harus memvalidasi bahwa header IP client hanya dipercaya jika request berasal dari Geto.
- Itadori dan Ino digunakan untuk menguji penerusan IP client dari dua network berbeda.
- Yaga digunakan untuk memverifikasi bahwa IP asli client dan worker pemroses request tercatat pada database `db_shibuya_K45`.

**Script:**
- `scripts/soal17_gojo.sh`, dijalankan di node Gojo (`10.86.1.4`).
- `scripts/soal17_geto.sh`, dijalankan di node Geto (`10.86.4.2`).
- `scripts/soal17_nanami.sh`, dijalankan di node Nanami (`10.86.4.5`).
- `scripts/soal17_todo.sh`, dijalankan di node Todo (`10.86.4.6`).

Script pemeriksaan Nanami dan Todo hanya membantu memeriksa kode yang ada; keduanya tidak otomatis mengubah aplikasi. Pengujian dari Itadori dan Ino serta query database pada Yaga dijalankan secara manual untuk membuktikan hasil konfigurasi.

### SOAL 18

#### Diminta
Mengonfigurasi load balancer Nginx pada Geto dengan Nanami dan Todo sebagai worker utama serta Kirara sebagai backup server. Menambahkan mekanisme passive health check dan menguji failover agar request API tetap berhasil ketika worker utama mengalami kegagalan.

#### Langkah-Langkah Pengerjaan & Pengujian

**1. Konfigurasi API Worker Nanami**

**Node:** Nanami (`10.86.4.5`)

Memastikan endpoint API tersedia dan dapat memberikan respons JSON. Endpoint `/api/` digunakan untuk memverifikasi worker yang memproses request.

Script: `/root/soal18_nanami.sh`

```
#!/bin/bash
set -e

mkdir -p /var/www/html/api

cat > /var/www/html/api/index.php <<'PHP'
<?php
header('Content-Type: application/json');

$host = '10.86.4.8';
$user = 'replicator';
$pass = 'k45pass';
$db   = 'db_shibuya_K45';

$worker = gethostname();
$remote = $_SERVER['REMOTE_ADDR'] ?? '';
$realIP = $_SERVER['HTTP_X_REAL_IP'] ?? '';

if ($remote === '10.86.4.2' &&
    filter_var($realIP, FILTER_VALIDATE_IP)) {
    $clientIP = $realIP;
} else {
    $clientIP = $remote;
}

try {
    $conn = new mysqli($host, $user, $pass, $db);

    if (!$conn->connect_error) {
        $stmt = $conn->prepare(
            'INSERT INTO request_logs (client_ip, worker_node)
             VALUES (?, ?)'
        );

        if ($stmt) {
            $stmt->bind_param('ss', $clientIP, $worker);
            $stmt->execute();
            $stmt->close();
        }

        $conn->close();
    }
} catch (Throwable $e) {
    error_log('Soal 18 Nanami: ' . $e->getMessage());
}

echo json_encode([
    'status' => 'success',
    'worker' => $worker,
    'client_ip' => $clientIP,
    'message' => 'API request processed'
]);
?>
PHP

php -l /var/www/html/api/index.php
nginx -t
```

Jalankan pada node Nanami:

```
chmod +x /root/soal18_nanami.sh
/root/soal18_nanami.sh
```

**2. Konfigurasi API Worker Todo**

**Node:** Todo (`10.86.4.6`)

Memastikan Todo menyediakan endpoint API yang dapat menerima request dari load balancer Geto dan mengembalikan respons JSON.

Script: `/root/soal18_todo.sh`

```
#!/bin/bash
set -e

mkdir -p /var/www/html/api

cat > /var/www/html/api/index.php <<'PHP'
<?php
header('Content-Type: application/json');

$host = '10.86.4.8';
$user = 'replicator';
$pass = 'k45pass';
$db   = 'db_shibuya_K45';

$worker = gethostname();
$remote = $_SERVER['REMOTE_ADDR'] ?? '';
$realIP = $_SERVER['HTTP_X_REAL_IP'] ?? '';

if ($remote === '10.86.4.2' &&
    filter_var($realIP, FILTER_VALIDATE_IP)) {
    $clientIP = $realIP;
} else {
    $clientIP = $remote;
}

try {
    $conn = new mysqli($host, $user, $pass, $db);

    if (!$conn->connect_error) {
        $stmt = $conn->prepare(
            'INSERT INTO request_logs (client_ip, worker_node)
             VALUES (?, ?)'
        );

        if ($stmt) {
            $stmt->bind_param('ss', $clientIP, $worker);
            $stmt->execute();
            $stmt->close();
        }

        $conn->close();
    }
} catch (Throwable $e) {
    error_log('Soal 18 Todo: ' . $e->getMessage());
}

echo json_encode([
    'status' => 'success',
    'worker' => $worker,
    'client_ip' => $clientIP,
    'message' => 'API request processed'
]);
?>
PHP

php -l /var/www/html/api/index.php
nginx -t
```

Jalankan pada node Todo:

```
chmod +x /root/soal18_todo.sh
/root/soal18_todo.sh
```

**3. Konfigurasi Backup API Worker Kirara**

**Node:** Kirara (`10.86.4.7`)

Memasang Nginx, PHP-FPM, dan PHP MySQL agar Kirara dapat menjalankan endpoint `/api/`. Mengonfigurasi document root dan PHP-FPM, kemudian memvalidasi konfigurasi menggunakan `nginx -t`.

Script: /root/soal18_kirara.sh

```
#!/bin/bash
set -e

apt-get update
apt-get install -y nginx php-fpm php-mysql curl

PHP_VERSION="$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')"
PHP_SOCKET="/run/php/php${PHP_VERSION}-fpm.sock"

mkdir -p /var/www/html/api

cat > /var/www/html/api/index.php <<'PHP'
<?php
header('Content-Type: application/json');

$host = '10.86.4.8';
$user = 'replicator';
$pass = 'k45pass';
$db   = 'db_shibuya_K45';

$worker = gethostname();
$remote = $_SERVER['REMOTE_ADDR'] ?? '';
$realIP = $_SERVER['HTTP_X_REAL_IP'] ?? '';

if ($remote === '10.86.4.2' &&
    filter_var($realIP, FILTER_VALIDATE_IP)) {
    $clientIP = $realIP;
} else {
    $clientIP = $remote;
}

try {
    $conn = new mysqli($host, $user, $pass, $db);

    if (!$conn->connect_error) {
        $stmt = $conn->prepare(
            'INSERT INTO request_logs (client_ip, worker_node)
             VALUES (?, ?)'
        );

        if ($stmt) {
            $stmt->bind_param('ss', $clientIP, $worker);
            $stmt->execute();
            $stmt->close();
        }

        $conn->close();
    }
} catch (Throwable $e) {
    error_log('Soal 18 Kirara: ' . $e->getMessage());
}

echo json_encode([
    'status' => 'success',
    'worker' => $worker,
    'client_ip' => $clientIP,
    'message' => 'API request processed'
]);
?>
PHP

cat > /etc/nginx/sites-available/default <<NGINX
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;
    root /var/www/html;
    index index.php index.html;

    location / {
        try_files \$uri \$uri/ =404;
    }

    location /api/ {
        index index.php;
        try_files \$uri \$uri/ /api/index.php?\$query_string;
    }

    location ~ \\.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:\${PHP_SOCKET};
    }

    location ~ /\\.ht {
        deny all;
    }
}
NGINX

php -l /var/www/html/api/index.php
php-fpm${PHP_VERSION} -D
nginx -t
nginx
curl -i http://127.0.0.1/api/
```

Jalankan pada node Kirara:

```
chmod +x /root/soal18_kirara.sh
/root/soal18_kirara.sh
```

Pengujian endpoint lokal:

```bash
curl -i http://127.0.0.1/api/
```

Respons yang diharapkan berupa `HTTP 200 OK` dengan `"worker":"kirara"`.

Script: `/root/soal18_kirara.sh`

**4. Konfigurasi Load Balancer Geto**

**Node:** Geto (`10.86.4.2`)

Menyimpan konfigurasi lama sebelum mengubah konfigurasi Nginx:

```bash
cp -n /etc/nginx/sites-available/default \
/etc/nginx/sites-available/default.bak.soal18
```

Mengonfigurasi upstream API dengan dua worker utama dan satu backup:

```nginx
upstream api_cluster {
    server 10.86.4.5:80 weight=3 max_fails=2 fail_timeout=5s;
    server 10.86.4.6:80 weight=1 max_fails=2 fail_timeout=5s;
    server 10.86.4.7:80 backup;
}

server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;

    location / {
        proxy_pass http://api_cluster;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $http_x_real_ip;
        proxy_set_header X-Forwarded-For $http_x_forwarded_for;

        proxy_connect_timeout 2s;
        proxy_read_timeout 5s;
        proxy_next_upstream error timeout http_502 http_503 http_504;
        proxy_next_upstream_tries 3;
    }
}
```

Memvalidasi dan menjalankan Nginx:

```bash
nginx -t
nginx
```

Script: `/root/soal18_geto.sh`

```
#!/bin/bash
set -e

CONFIG="/etc/nginx/sites-available/default"

if [ ! -f "${CONFIG}.bak.soal18" ]; then
    cp "$CONFIG" "${CONFIG}.bak.soal18"
fi

cat > "$CONFIG" <<'NGINX'
upstream api_cluster {
    server 10.86.4.5:80 weight=3 max_fails=2 fail_timeout=5s;
    server 10.86.4.6:80 weight=1 max_fails=2 fail_timeout=5s;
    server 10.86.4.7:80 backup;
}

server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;

    location / {
        proxy_pass http://api_cluster;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $http_x_real_ip;
        proxy_set_header X-Forwarded-For $http_x_forwarded_for;

        proxy_connect_timeout 2s;
        proxy_read_timeout 5s;
        proxy_next_upstream error timeout http_502 http_503 http_504;
        proxy_next_upstream_tries 3;
    }
}
NGINX

nginx -t

if pgrep -x nginx >/dev/null; then
    nginx -s reload
else
    nginx
fi

curl -i --max-time 10 http://127.0.0.1/api/
```


**5. Pengujian Failover ke Todo**

**Node:** Nanami dan Geto

Menghentikan Nginx pada Nanami:

```bash
nginx -s quit
```

Mengirim request API melalui Geto:

```bash
curl -i --max-time 10 http://127.0.0.1/api/
```

Hasil pengujian menunjukkan `HTTP 200 OK` dengan `"worker":"todo"`, sehingga request tetap berhasil ketika Nanami tidak tersedia.

**6. Pengujian Failover ke Kirara**

**Node:** Todo dan Geto

Setelah Nanami tidak tersedia, menghentikan Nginx pada Todo:

```bash
nginx -s quit
```

Mengirim kembali request melalui Geto:

```bash
curl -i --max-time 10 http://127.0.0.1/api/
```

Hasil pengujian menunjukkan `HTTP 200 OK` dengan `"worker":"kirara"`. Hal ini membuktikan bahwa Kirara dapat menangani request ketika kedua worker utama tidak tersedia.

**7. Pemulihan Worker Utama**

**Node:** Nanami dan Todo

Menjalankan kembali Nginx pada kedua node:

```bash
nginx
```

Kemudian menguji kembali request dari Geto:

```bash
curl -i --max-time 10 http://127.0.0.1/api/
```

Hasil pengujian menunjukkan `HTTP 200 OK` dengan `"worker":"nanami"`, sehingga layanan utama kembali dapat memproses request.

#### Hasil

Konfigurasi load balancer berhasil diuji dalam tiga kondisi utama: request dialihkan ke Todo ketika Nanami tidak tersedia, dialihkan ke Kirara ketika kedua worker utama tidak tersedia, dan kembali diproses oleh Nanami setelah layanan utama dipulihkan. Seluruh pengujian tersebut menghasilkan `HTTP 200 OK`.

#### Script

- `/root/soal18_nanami.sh` — konfigurasi API worker Nanami.
- `/root/soal18_todo.sh` — konfigurasi API worker Todo.
- `/root/soal18_kirara.sh` — konfigurasi backup API worker Kirara.
- `/root/soal18_geto.sh` — konfigurasi load balancer dan failover pada Geto.

### SOAL 19 

#### Diminta

Mengonfigurasi Nginx pada Gojo untuk mengoptimalkan layanan frontend menggunakan Proxy Caching dengan masa berlaku 10 menit, menambahkan header `X-Cache-Status`, serta menerapkan rate limiting pada endpoint `/api` dengan batas 10 request per detik per IP klien. Membuktikan bahwa cache menghasilkan status `MISS` pada akses pertama dan `HIT` pada akses berikutnya, serta menguji respons ketika batas request terlampaui.

#### Langkah-Langkah Pengerjaan & Pengujian

**1. Backup Konfigurasi Nginx**

**Node:** Gojo (`10.86.1.4`)

Membuat backup konfigurasi virtual host sebelum melakukan perubahan agar konfigurasi sebelumnya dapat dipulihkan apabila terjadi kesalahan.

Keterangan Script soal19_gojo.sh

Script dijalankan pada node Gojo sebagai root untuk mengonfigurasi Nginx Proxy Cache dan Rate Limiting.

1. Inisialisasi dan Backup Konfigurasi
```
set -Eeuo pipefail

CONF="/etc/nginx/sites-available/default"
ZONE="/etc/nginx/conf.d/soal19-cache-limit.conf"
BACKUP="/root/backup-soal19-final-$(date +%Y%m%d-%H%M%S)"

mkdir -p "$BACKUP"
cp -a "$CONF" "$BACKUP/default"
```

Keterangan: Mengaktifkan penanganan error pada Bash, menentukan lokasi konfigurasi Nginx, dan membuat backup virtual host sebelum perubahan dilakukan agar konfigurasi sebelumnya dapat dipulihkan.

2. Menyiapkan Direktori Cache

mkdir -p /var/cache/nginx/proxy_cache

Keterangan: Membuat direktori penyimpanan file cache yang digunakan Nginx untuk menyimpan respons frontend.

3. Membuat Cache Zone dan Rate Limit Zone
```
proxy_cache_path /var/cache/nginx/proxy_cache
    levels=1:2
    keys_zone=frontend_cache:10m
    max_size=100m
    inactive=10m
    use_temp_path=off;

limit_req_zone $binary_remote_addr
    zone=api_limit:10m
    rate=10r/s;
```

Keterangan:

proxy_cache_path: menentukan lokasi penyimpanan cache.

levels=1:2: mengatur struktur direktori cache.

keys_zone=frontend_cache:10m: menyediakan shared memory sebesar 10 MB untuk metadata cache.

max_size=100m: membatasi ukuran cache hingga 100 MB.

inactive=10m: menghapus cache yang tidak digunakan selama 10 menit.

use_temp_path=off: menyimpan file cache pada direktori cache tanpa direktori sementara terpisah.

limit_req_zone: membuat zona pembatasan request berdasarkan alamat IP klien.

rate=10r/s: menetapkan batas rata-rata 10 request per detik per IP.

4. Memvalidasi Struktur Virtual Host
```
grep -qE '^[[:space:]]*location[[:space:]]+/[[:space:]]*\{' "$CONF"

grep -qE '^[[:space:]]*location[[:space:]]+/api[[:space:]]*\{' "$CONF"
```


Keterangan: Memastikan blok location / dan location /api tersedia sebelum directive cache dan rate limiting ditambahkan.

5. Memperbaiki URL Proxy
```
sed -i \
    -e 's|\[http://10\.86\.4\.2\](http://10\.86\.4\.2)|http://10.86.4.2|g' \
    -e 's|http\\://frontend_cluster|http://frontend_cluster|g' \
    "$CONF"
```

Keterangan: Memperbaiki format URL yang mungkin tersalin dari Markdown agar directive proxy_pass menggunakan alamat yang dikenali Nginx.

6. Menerapkan Proxy Cache pada Frontend
```
proxy_cache frontend_cache;
proxy_cache_valid 200 10m;
proxy_cache_methods GET HEAD;
proxy_cache_bypass $http_authorization;
proxy_no_cache $http_authorization;
add_header X-Cache-Status $upstream_cache_status always;
```

Keterangan:

proxy_cache frontend_cache: mengaktifkan cache pada halaman frontend.

proxy_cache_valid 200 10m: menyimpan respons HTTP 200 selama 10 menit.

proxy_cache_methods GET HEAD: mengizinkan metode GET dan HEAD untuk cache.

proxy_cache_bypass $http_authorization: melewati cache jika request memiliki header Authorization.

proxy_no_cache $http_authorization: mencegah respons request terautentikasi disimpan ke cache.

add_header X-Cache-Status: menampilkan status cache pada header respons agar dapat diverifikasi menggunakan curl.

7. Menerapkan Rate Limiting pada API
```
limit_req zone=api_limit burst=10 nodelay;
limit_req_status 429;
```

Keterangan:

limit_req zone=api_limit: menerapkan pembatasan request menggunakan zona yang sudah dibuat.

burst=10: mengizinkan hingga 10 request tambahan dalam antrean burst.

nodelay: tidak menunda request yang masih berada dalam batas burst.

limit_req_status 429: menggunakan HTTP 429 Too Many Requests untuk request yang ditolak akibat batas rate limiting.

8. Validasi dan Reload Nginx
```
nginx -t
nginx -s reload
```

Keterangan: Memeriksa sintaks konfigurasi sebelum memuat ulang Nginx. Reload menerapkan konfigurasi baru tanpa menghentikan layanan secara penuh.

9. Verifikasi Konfigurasi
```
nginx -T 2>&1 | grep -n -E \
'proxy_cache_path|keys_zone=frontend_cache|rate=10r/s|proxy_cache frontend_cache|proxy_cache_valid 200 10m|X-Cache-Status|limit_req zone=api_limit|limit_req_status 429'
```

Keterangan: Menampilkan baris konfigurasi aktif yang berkaitan dengan cache, header status, dan rate limiting untuk memastikan directive sudah dimuat oleh Nginx.

Keterangan Pengujian

Pengujian Cache
```
curl -s -o /dev/null -D - \
  -H 'Host: jujutsu.k45.com' http://127.0.0.1/ \
  | grep -iE 'HTTP/|X-Cache-Status'
```

Perintah mengirim request ke halaman frontend melalui Gojo dan menampilkan status HTTP beserta header cache. Hasil pengujian menunjukkan MISS pada akses pertama dan HIT pada akses berikutnya.

Pengujian Rate Limiting
```
for i in $(seq 1 30); do
  curl -s -o /dev/null \
    --max-time 3 \
    -w "Request $i: HTTP %{http_code}\n" \
    -H 'Host: jujutsu.k45.com' \
    http://127.0.0.1/api
done
```

Perintah mengirim 30 request secara beruntun ke endpoint /api. Hasil pengujian memperlihatkan respons HTTP 301 dari upstream dan HTTP 429 ketika rate limiting menolak request berlebih.

Script membuat direktori backup berdasarkan tanggal dan waktu eksekusi:
```bash
BACKUP="/root/backup-soal19-final-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP"
cp -a /etc/nginx/sites-available/default "$BACKUP/default"
```

**2. Konfigurasi Proxy Cache dan Rate Limit Zone**

**Node:** Gojo (`10.86.1.4`)

Membuat direktori penyimpanan cache dan file `/etc/nginx/conf.d/soal19-cache-limit.conf` yang berisi konfigurasi cache serta rate limiting.

```nginx
proxy_cache_path /var/cache/nginx/proxy_cache
    levels=1:2
    keys_zone=frontend_cache:10m
    max_size=100m
    inactive=10m
    use_temp_path=off;

limit_req_zone $binary_remote_addr
    zone=api_limit:10m
    rate=10r/s;
```

Keterangan:
- `proxy_cache_path` menentukan lokasi penyimpanan cache.
- `levels=1:2` mengatur struktur direktori penyimpanan cache.
- `keys_zone=frontend_cache:10m` menyediakan shared memory sebesar 10 MB untuk metadata cache.
- `max_size=100m` menetapkan batas ukuran cache sebesar 100 MB.
- `inactive=10m` mengatur penghapusan cache yang tidak digunakan selama 10 menit.
- `limit_req_zone` membuat zona pembatasan request berdasarkan IP klien.
- `rate=10r/s` menetapkan batas rata-rata 10 request per detik per IP.

**3. Penerapan Proxy Cache pada Frontend**

**Node:** Gojo (`10.86.1.4`)

Mengaktifkan Proxy Cache pada `location /` yang meneruskan request ke upstream `frontend_cluster`, yaitu Maki (`10.86.4.3`) dan Panda (`10.86.4.4`).

```nginx
location / {
    proxy_cache frontend_cache;
    proxy_cache_valid 200 10m;
    proxy_cache_methods GET HEAD;
    proxy_cache_bypass $http_authorization;
    proxy_no_cache $http_authorization;
    add_header X-Cache-Status $upstream_cache_status always;

    proxy_pass http://frontend_cluster;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
}
```

Keterangan:
- `proxy_cache frontend_cache` mengaktifkan cache untuk halaman frontend.
- `proxy_cache_valid 200 10m` menyimpan respons HTTP 200 selama 10 menit.
- `proxy_cache_methods GET HEAD` menentukan metode request yang dapat menggunakan cache.
- `proxy_cache_bypass` dan `proxy_no_cache` mencegah penggunaan serta penyimpanan cache untuk request dengan header Authorization.
- `add_header X-Cache-Status` menampilkan status cache pada header respons.

**4. Penerapan Rate Limiting pada API**

**Node:** Gojo (`10.86.1.4`)

Menerapkan pembatasan request pada `location /api` yang meneruskan request ke Geto (`10.86.4.2`).

```nginx
location /api {
    limit_req zone=api_limit burst=10 nodelay;
    limit_req_status 429;

    proxy_pass http://10.86.4.2;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
}
```

Keterangan:
- `limit_req zone=api_limit` menerapkan pembatasan request berdasarkan zona yang telah dibuat.
- `burst=10` mengizinkan hingga 10 request tambahan dalam batas burst.
- `nodelay` memproses request yang masih berada dalam batas burst tanpa penundaan.
- `limit_req_status 429` menetapkan HTTP 429 Too Many Requests untuk request yang ditolak akibat rate limiting.
- `proxy_pass` meneruskan request API ke load balancer Geto.

**5. Validasi dan Reload Nginx**

**Node:** Gojo (`10.86.1.4`)

Memvalidasi konfigurasi setelah penambahan directive cache dan rate limiting.

```bash
nginx -t
nginx -s reload
```

Hasil pengujian menunjukkan:
```text
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
```

Nginx berhasil dimuat ulang sehingga konfigurasi baru dapat diterapkan.

**6. Pengujian Proxy Cache MISS dan HIT**

**Node:** Gojo (`10.86.1.4`)

Mengirim request ke halaman frontend melalui Gojo dengan header Host `jujutsu.k45.com`.

Perintah pengujian:
```bash
curl -s -o /dev/null -D - \
  -H 'Host: jujutsu.k45.com' http://127.0.0.1/ \
  | grep -iE 'HTTP/|X-Cache-Status'
```

Perintah dijalankan dua kali untuk membandingkan status cache.

Hasil akses pertama:
```text
HTTP/1.1 200 OK
X-Cache-Status: MISS
```

Hasil akses kedua:
```text
HTTP/1.1 200 OK
X-Cache-Status: HIT
```

Hasil tersebut membuktikan bahwa request pertama mengambil respons dari upstream, sedangkan request berikutnya menggunakan respons yang telah tersimpan dalam cache.

**7. Pengujian Rate Limiting pada API**

**Node:** Gojo (`10.86.1.4`)

Mengirim 30 request secara beruntun ke endpoint `/api` untuk menguji pembatasan request per IP klien.

```bash
for i in $(seq 1 30); do
  curl -s -o /dev/null \
    --max-time 3 \
    -w "Request $i: HTTP %{http_code}\n" \
    -H 'Host: jujutsu.k45.com' \
    http://127.0.0.1/api
done
```

Hasil pengujian menunjukkan respons HTTP 301 dan HTTP 429.

- **HTTP 301:** request mendapatkan respons pengalihan dari layanan upstream.
- **HTTP 429:** request ditolak karena batas rate limiting terlampaui.

Munculnya HTTP 429 membuktikan bahwa mekanisme pembatasan request telah aktif. Request yang memperoleh HTTP 301 tidak mengikuti pengalihan secara otomatis karena perintah `curl` tidak menggunakan opsi `-L`.

#### Hasil

Konfigurasi Nginx Proxy Cache dan Rate Limiting pada Gojo berhasil diterapkan dan diuji. Validasi konfigurasi menggunakan `nginx -t` berhasil, kemudian Nginx berhasil di-reload.

Pengujian frontend menghasilkan `X-Cache-Status: MISS` pada akses pertama dan `X-Cache-Status: HIT` pada akses berikutnya, dengan respons HTTP 200 OK. Pengujian rate limiting melalui 30 request beruntun menghasilkan HTTP 429 pada sejumlah request yang melampaui batas.

Dengan demikian, mekanisme caching frontend dan pembatasan request API telah berjalan sesuai tujuan praktikum.

<img width="552" height="59" alt="Screenshot 2026-10-15 at 01 17 23" src="https://github.com/user-attachments/assets/86c77dec-fe55-431d-8735-29ae66781ae7" />

<img width="407" height="90" alt="Screenshot 2026-10-15 at 01 21 39" src="https://github.com/user-attachments/assets/9366d272-0d54-4c17-bd13-24aaeed4291f" />

#### Script

- `/root/soal19_gojo.sh` — konfigurasi Proxy Cache, header `X-Cache-Status`, rate limiting API, validasi, dan reload Nginx.
- `/etc/nginx/conf.d/soal19-cache-limit.conf` — konfigurasi cache zone dan rate-limit zone.
