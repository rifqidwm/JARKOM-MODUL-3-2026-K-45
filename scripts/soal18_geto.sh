
#!/bin/sh
set -eu

# SOAL 18 - Backup API dan Passive Health Check
# Node: Geto

apk add --no-cache nginx

mkdir -p /etc/nginx/conf.d

# Hapus konfigurasi lama dari soal sebelumnya agar
# tidak ada upstream api_cluster yang terdefinisi ganda.
rm -f /etc/nginx/conf.d/soal17-api.conf

CONFIG="/etc/nginx/conf.d/soal18-api-backup.conf"

if [ -f "$CONFIG" ]; then
    cp "$CONFIG" "$CONFIG.bak"
fi

cat > "$CONFIG" <<'EOF'
upstream api_cluster {
    server 10.86.4.5:80 max_fails=2 fail_timeout=5s;
    server 10.86.4.6:80 max_fails=2 fail_timeout=5s;
    server 10.86.4.7:80 backup;
}

server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://api_cluster;

        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

nginx -t
nginx -s reload 2>/dev/null || {
    pkill nginx 2>/dev/null || true
    nginx
}

echo "=== KONFIGURASI BACKUP ==="
nginx -T

