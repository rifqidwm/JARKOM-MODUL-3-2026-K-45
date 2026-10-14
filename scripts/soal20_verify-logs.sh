
#!/bin/sh

# SOAL 20 - Verifikasi Access Log
# Node: Gojo

LOG="/var/log/nginx/access.log"

if [ ! -f "$LOG" ]; then
    echo "Access log tidak ditemukan: $LOG"
    exit 1
fi

echo "=== JUMLAH STATUS HTTP KESELURUHAN ==="
awk '{print $9}' "$LOG" \
    | sort \
    | uniq -c \
    | sort -nr

echo
echo "=== STATUS DARI KUSAKABE (10.86.3.11) ==="
grep '10.86.3.11' "$LOG" \
    | awk '{print $9}' \
    | sort \
    | uniq -c

echo
echo "=== JUMLAH HTTP 429 DARI KUSAKABE ==="
grep '10.86.3.11' "$LOG" \
    | awk '$9 == 429 {count++} END {print count+0}'

echo
echo "=== 20 BARIS LOG TERAKHIR ==="
tail -n 20 "$LOG"

