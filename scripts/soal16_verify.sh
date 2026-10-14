
#!/bin/sh

# SOAL 16 - Verifikasi Reverse Proxy

echo "=== TES HOMEPAGE ==="
curl -i --max-time 10 http://jujutsu.k45.com/

echo
echo "=== TES API ==="
curl -i --max-time 10 http://jujutsu.k45.com/api/

echo
echo "=== TES BERULANG UNTUK MELIHAT BACKEND ==="
for i in $(seq 1 10); do
    echo "--- Request $i ---"
    curl -sS --max-time 5 -i http://jujutsu.k45.com/ | head -n 10
done

