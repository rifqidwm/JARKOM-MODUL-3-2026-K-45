
#!/bin/sh

# SOAL 19 - Pengujian Cache dan Rate Limit
# Jalankan dari client penguji.

TARGET="http://jujutsu.k45.com"

echo "=== TES CACHE PERTAMA ==="
curl -sS -D - -o /dev/null "$TARGET/"

echo
echo "=== TES CACHE KEDUA ==="
curl -sS -D - -o /dev/null "$TARGET/"

echo
echo "=== TES RATE LIMIT API ==="
for i in $(seq 1 30); do
    STATUS=$(curl -sS -o /dev/null \
        -w '%{http_code}' --max-time 5 "$TARGET/api" || true)

    echo "Request $i: HTTP $STATUS"
done

