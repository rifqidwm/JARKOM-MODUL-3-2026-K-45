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
