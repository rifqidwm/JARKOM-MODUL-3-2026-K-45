
#!/bin/sh

# SOAL 17 - Verifikasi Forwarded Client IP

echo "=== REQUEST MELALUI GOJO ==="
curl -i --max-time 10 http://jujutsu.k45.com/api/

echo
echo "=== REQUEST LANGSUNG KE GETO ==="
curl -i --max-time 10 http://10.86.4.2/

echo
echo "=== HEADER REQUEST ==="
curl -sS -D - -o /dev/null --max-time 10 \
    http://jujutsu.k45.com/api/

