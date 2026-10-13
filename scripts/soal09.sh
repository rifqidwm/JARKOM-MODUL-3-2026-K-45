#!/bin/sh

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
