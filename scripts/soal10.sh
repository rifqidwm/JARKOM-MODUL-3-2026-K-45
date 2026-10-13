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
