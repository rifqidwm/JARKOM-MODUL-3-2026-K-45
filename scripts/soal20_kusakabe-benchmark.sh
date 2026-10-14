
#!/bin/sh
set -eu

# SOAL 20 - ApacheBench
# Node: Kusakabe

TARGET="http://jujutsu.k45.com"
OUTPUT="/root/soal20-results"

apk add --no-cache apache2-utils
mkdir -p "$OUTPUT"

echo "=== INFORMASI NODE ==="
hostname
ip -br addr
ip route

echo
echo "=== VERSI APACHEBENCH ==="
ab -V

echo
echo "=== BENCHMARK HOMEPAGE ==="
ab -n 600 -c 30 "$TARGET/" 2>&1 \
    | tee "$OUTPUT/homepage.txt"

echo
echo "=== BENCHMARK API DENGAN TRAILING SLASH ==="
ab -n 600 -c 30 "$TARGET/api/" 2>&1 \
    | tee "$OUTPUT/api-trailing-slash.txt"

echo
echo "=== BENCHMARK API TANPA TRAILING SLASH ==="
ab -n 600 -c 30 "$TARGET/api" 2>&1 \
    | tee "$OUTPUT/api.txt"

echo
echo "=== FILE HASIL ==="
ls -lh "$OUTPUT"

