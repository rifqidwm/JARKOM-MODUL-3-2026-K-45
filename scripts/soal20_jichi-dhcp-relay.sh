
#!/bin/sh
set -eu

# SOAL 20 - DHCP Relay
# Node: Jichi
# Jalankan sebagai root.
# Proses sengaja berjalan di foreground.

apk add --no-cache dhcrelay

echo "=== INTERFACE JICHI ==="
ip -br addr

echo "=== ROUTING JICHI ==="
ip route

echo "=== MENJALANKAN DHCP RELAY ==="
exec dhcrelay -4 -d -id eth3 -iu eth4 10.86.4.10

