# Script Penyelesaian

Folder ini berisi satu skrip untuk setiap soal. Isi setiap skrip sama dengan perintah pada langkah-langkah di `README.md` utama, dengan urutan yang sama. Skrip ditulis untuk `sh` sehingga dapat dijalankan pada node `debinet` maupun `alpinet`.

Skrip mengenali node berdasarkan hostname, sehingga satu skrip yang sama dapat dijalankan di semua node tujuan soal tersebut. Pada node yang bukan tujuan, skrip hanya menampilkan pesan. Oleh karena itu nama node di GNS3 harus sesuai dengan glosarium soal.

## Cara Pemakaian

1. Buka console node tujuan.
2. Salin blok pada bagian **Isi Skrip** di bawah, lalu tempel ke console. Blok tersebut membuat berkas `/root/soalNN.sh`.
3. Jalankan skrip, beserta argumen apabila diperlukan:

```sh
sh /root/soalNN.sh
```

Apabila node sudah memiliki akses internet, skrip juga dapat diunduh langsung dari repository, misalnya:

```sh
wget -qO /root/soal02.sh https://raw.githubusercontent.com/<USER>/Jarkom-Modul-3-2026-K45/main/scripts/soal02.sh
```

## Daftar Skrip

| Skrip | Fungsi | Node | Argumen |
| ----- | ------ | ---- | ------- |
| `soal01.sh` | IP statis, gateway, forwarding, dan NAT | jichi, 12 host infrastruktur | jichi: `cek` |
| `soal02.sh` | DHCP Server | tengen | - |
| `soal03.sh` | DHCP Relay dan client DHCP | jichi, 8 client, tengen | - |
| `soal04.sh` | Dua pool Network 2 | tengen, 8 client | tengen: `macs`, `leases`. client: `mac` |
| `soal05.sh` | Short lease, long lease, DNS, dan domain | tengen, ino, kusakabe, miwa | - |
| `soal06.sh` | Static lease kugisaki | tengen, kugisaki | - |
| `soal07.sh` | Validasi konfigurasi dan lease | client, tengen | - |
| `soal08.sh` | Packet capture DORA | tengen, itadori atau ino | - |
| `soal09.sh` | Gangguan dan pemulihan relay | jichi, satu client | jichi: `stop`, `start`. client: `gagal`, `pulih` |
| `soal10.sh` | Autostart dan pengujian setelah restart | jichi, tengen, client | jichi dan tengen: `check` |

## Urutan Menjalankan

| Tahap | Perintah | Node |
| ----- | -------- | ---- |
| 1 | `sh /root/soal01.sh` | jichi, kemudian 12 host infrastruktur |
| 2 | `sh /root/soal01.sh cek` | jichi |
| 3 | `sh /root/soal02.sh` | tengen |
| 4 | `sh /root/soal03.sh` | jichi, 8 client, kemudian tengen |
| 5 | `sh /root/soal04.sh mac` | 8 client (menampilkan MAC) |
| 6 | `sh /root/soal04.sh macs` | tengen (mengisi `/root/macs.env`) |
| 7 | `sh /root/soal04.sh` | tengen, kemudian client Divisi A |
| 8 | `sh /root/soal04.sh leases` | tengen |
| 9 | `sh /root/soal05.sh` | tengen, kemudian ino, kusakabe, miwa |
| 10 | `sh /root/soal06.sh` | tengen, kemudian kugisaki |
| 11 | `sh /root/soal07.sh` | client, kemudian tengen |
| 12 | `sh /root/soal08.sh` | tengen, kemudian itadori atau ino dalam 40 detik |
| 13 | `sh /root/soal09.sh stop`, `gagal`, `start`, `pulih` | jichi, client, jichi, client |
| 14 | `sh /root/soal10.sh` | jichi dan tengen, kemudian restart kedua node |
| 15 | `sh /root/soal10.sh check` dan `sh /root/soal10.sh` | jichi dan tengen, kemudian client |

Skrip `soal04.sh`, `soal05.sh`, dan `soal06.sh` menulis ulang `/etc/dhcp/dhcpd.conf` secara utuh untuk tahap masing-masing. Apabila `soal05.sh` dijalankan setelah `soal06.sh`, static lease kugisaki ikut terhapus sehingga `soal06.sh` perlu dijalankan kembali.

Argumen `macs` pada `soal04.sh` menuliskan MAC client topologi kelompok ini. Apabila node dibuat ulang, MAC berubah dan baris-baris tersebut perlu disesuaikan dengan hasil `sh /root/soal04.sh mac` di setiap client.

## Isi Skrip

Setiap blok membuat `/root/soalNN.sh`.

### soal01.sh: IP statis, gateway, forwarding, dan NAT

Node: jichi, 12 host infrastruktur. Argumen: jichi: `cek`.

```sh
cat > /root/soal01.sh <<'SOAL_END'
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
SOAL_END
```

### soal02.sh: DHCP Server

Node: tengen. Argumen: -.

```sh
cat > /root/soal02.sh <<'SOAL_END'
#!/bin/sh

if [ "$(hostname)" != "tengen" ]; then
  echo "Skrip ini dijalankan di tengen."
  exit 1
fi

apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y isc-dhcp-server

sed -i 's/^INTERFACESv4=.*/INTERFACESv4="eth0"/' /etc/default/isc-dhcp-server

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

service isc-dhcp-server stop
: > /var/lib/dhcp/dhcpd.leases
rm -f /var/lib/dhcp/dhcpd.leases~
grep INTERFACESv4 /etc/default/isc-dhcp-server
dhcpd -t -cf /etc/dhcp/dhcpd.conf

service isc-dhcp-server stop
timeout 3 dhcpd -4 -d -cf /etc/dhcp/dhcpd.conf eth0 2>&1 | grep -E "Listening|No subnet|Sending"
service isc-dhcp-server start
service isc-dhcp-server status
ss -ulnp | grep ':67'
SOAL_END
```

### soal03.sh: DHCP Relay dan client DHCP

Node: jichi, 8 client, tengen. Argumen: -.

```sh
cat > /root/soal03.sh <<'SOAL_END'
#!/bin/sh

N=$(hostname)

case "$N" in
  jichi)
    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y isc-dhcp-relay
    cat > /etc/default/isc-dhcp-relay <<'EOF'
SERVERS="10.86.4.10"
INTERFACES="eth2 eth3 eth4"
OPTIONS=""
EOF
    service isc-dhcp-relay restart
    cat /etc/default/isc-dhcp-relay
    ps aux | grep [d]hcrelay
    sysctl net.ipv4.ip_forward
    ;;
  itadori|fushiguro|zenin|okkotsu|ino|kusakabe|miwa|kugisaki)
    ip link set eth0 up
    ip addr flush dev eth0
    udhcpc -i eth0 -n -q
    ip addr show dev eth0
    ip route
    ;;
  tengen)
    grep -E "^lease|hardware ethernet" /var/lib/dhcp/dhcpd.leases
    ;;
  *)
    echo "Node $N bukan bagian dari soal 3."
    ;;
esac
SOAL_END
```

### soal04.sh: Dua pool Network 2

Node: tengen, 8 client. Argumen: tengen: `macs`, `leases`. client: `mac`.

```sh
cat > /root/soal04.sh <<'SOAL_END'
#!/bin/sh

N=$(hostname)
MODE=$1

case "$N" in
  tengen)
    case "$MODE" in
      macs)
        : > /root/macs.env
        echo M_ITADORI=02:42:97:40:66:00 >> /root/macs.env
        echo M_FUSHIGURO=02:42:c8:94:58:00 >> /root/macs.env
        echo M_ZENIN=02:42:3b:86:61:00 >> /root/macs.env
        echo M_OKKOTSU=02:42:27:fb:e9:00 >> /root/macs.env
        echo M_INO=02:42:14:fc:9c:00 >> /root/macs.env
        echo M_KUSAKABE=02:42:b9:59:6f:00 >> /root/macs.env
        echo M_MIWA=02:42:4a:27:87:00 >> /root/macs.env
        echo M_KUGISAKI=02:42:e7:23:fc:00 >> /root/macs.env
        cat /root/macs.env
        ;;
      leases)
        awk '/^lease/{ip=$2} /hardware ethernet/{gsub(";","",$3); print ip, $3}' /var/lib/dhcp/dhcpd.leases | sort -u
        ;;
      *)
        cat /root/macs.env
        service isc-dhcp-server stop
        : > /var/lib/dhcp/dhcpd.leases
        rm -f /var/lib/dhcp/dhcpd.leases~
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
        dhcpd -t -cf /etc/dhcp/dhcpd.conf
        service isc-dhcp-server start
        grep -nE "class|subclass|allow members|range" /etc/dhcp/dhcpd.conf
        dhcpd -t -cf /etc/dhcp/dhcpd.conf
        ;;
    esac
    ;;
  itadori|fushiguro|zenin|okkotsu|ino|kusakabe|miwa|kugisaki)
    case "$MODE" in
      mac)
        echo "echo M_$(hostname | tr a-z A-Z)=$(cat /sys/class/net/eth0/address) >> /root/macs.env"
        ;;
      *)
        ip addr flush dev eth0
        udhcpc -i eth0 -n -q
        ip addr show dev eth0
        ip route
        ;;
    esac
    ;;
  *)
    echo "Node $N bukan bagian dari soal 4."
    ;;
esac
SOAL_END
```

### soal05.sh: Short lease, long lease, DNS, dan domain

Node: tengen, ino, kusakabe, miwa. Argumen: -.

```sh
cat > /root/soal05.sh <<'SOAL_END'
#!/bin/sh

N=$(hostname)

case "$N" in
  tengen)
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
    dhcpd -t -cf /etc/dhcp/dhcpd.conf
    service isc-dhcp-server start
    grep -nE "domain|lease-time|range|class" /etc/dhcp/dhcpd.conf
    dhcpd -t -cf /etc/dhcp/dhcpd.conf
    ;;
  itadori|fushiguro|zenin|okkotsu|ino|kusakabe|miwa|kugisaki)
    ip addr flush dev eth0
    udhcpc -i eth0 -n -q
    ip addr show dev eth0
    ip route
    cat /etc/resolv.conf
    ;;
  *)
    echo "Node $N bukan bagian dari soal 5."
    ;;
esac
SOAL_END
```

### soal06.sh: Static lease kugisaki

Node: tengen, kugisaki. Argumen: -.

```sh
cat > /root/soal06.sh <<'SOAL_END'
#!/bin/sh

N=$(hostname)

case "$N" in
  tengen)
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
    dhcpd -t -cf /etc/dhcp/dhcpd.conf
    service isc-dhcp-server start
    grep -B1 -A3 "host kugisaki" /etc/dhcp/dhcpd.conf
    dhcpd -t -cf /etc/dhcp/dhcpd.conf
    ;;
  kugisaki)
    ip addr flush dev eth0
    udhcpc -i eth0 -n -q
    ip addr show dev eth0
    ip addr flush dev eth0
    udhcpc -i eth0 -n -q
    ip addr show dev eth0
    ip route
    ;;
  *)
    echo "Node $N bukan bagian dari soal 6."
    ;;
esac
SOAL_END
```

### soal07.sh: Validasi konfigurasi dan lease

Node: client, tengen. Argumen: -.

```sh
cat > /root/soal07.sh <<'SOAL_END'
#!/bin/sh

N=$(hostname)

case "$N" in
  itadori|fushiguro|zenin|okkotsu|ino|kusakabe|miwa|kugisaki)
    ip addr flush dev eth0
    udhcpc -i eth0 -n -q
    ip addr show dev eth0
    ip route
    cat /etc/resolv.conf
    ;;
  tengen)
    grep -E "^lease|starts|ends|hardware ethernet" /var/lib/dhcp/dhcpd.leases | tail -40
    ;;
  *)
    echo "Node $N bukan bagian dari soal 7."
    ;;
esac
SOAL_END
```

### soal08.sh: Packet capture DORA

Node: tengen, itadori atau ino. Argumen: -.

```sh
cat > /root/soal08.sh <<'SOAL_END'
#!/bin/sh

N=$(hostname)

case "$N" in
  tengen)
    apt-get install -y tcpdump
    timeout 40 tcpdump -ni eth0 -s0 -U -w /root/soal08-dora.pcap 'udp port 67 or udp port 68'
    tcpdump -nvvv -r /root/soal08-dora.pcap | grep -E "BOOTP/DHCP|Gateway-IP|Your-IP|DHCP-Message|Server-ID|Lease-Time"
    tcpdump -nvvv -r /root/soal08-dora.pcap | grep Gateway-IP | sort -u
    ;;
  itadori|fushiguro|zenin|okkotsu|ino|kusakabe|miwa|kugisaki)
    ip addr flush dev eth0
    udhcpc -i eth0 -n -q
    ;;
  *)
    echo "Node $N bukan bagian dari soal 8."
    ;;
esac
SOAL_END
```

### soal09.sh: Gangguan dan pemulihan relay

Node: jichi, satu client. Argumen: jichi: `stop`, `start`. client: `gagal`, `pulih`.

```sh
cat > /root/soal09.sh <<'SOAL_END'
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
SOAL_END
```

### soal10.sh: Autostart dan pengujian setelah restart

Node: jichi, tengen, client. Argumen: jichi dan tengen: `check`.

```sh
cat > /root/soal10.sh <<'SOAL_END'
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
SOAL_END
```
