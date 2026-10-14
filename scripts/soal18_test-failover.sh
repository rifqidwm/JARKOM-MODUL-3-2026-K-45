
#!/bin/sh

# SOAL 18 - Pengujian Failover
# Jalankan dari client penguji.

echo "=== REQUEST SEBELUM FAILOVER ==="
for i in $(seq 1 10); do
    echo "--- Request $i ---"
    curl -sS -i --max-time 5 http://jujutsu.k45.com/api/ \
        | head -n 12 || true
done

echo
echo "Sekarang hentikan layanan API Nanami dan Todo"
echo "melalui node masing-masing, lalu jalankan tes ulang."

echo
echo "=== REQUEST SAAT BACKEND UTAMA GAGAL ==="
for i in $(seq 1 10); do
    echo "--- Request $i ---"
    curl -sS -i --max-time 5 http://jujutsu.k45.com/api/ \
        | head -n 12 || true
done

