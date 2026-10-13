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
