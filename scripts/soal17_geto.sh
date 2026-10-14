
#!/bin/sh
set -eu

# SOAL 17 - Forwarded Client IP
# Node: Geto

apk add --no-cache nginx

mkdir -p /etc/nginx/conf.d

CONFIG="/etc/nginx/conf.d/soal17-api.conf"

if [ -f "$CONFIG" ]; then
    cp "$CONFIG" "$CONFIG.bak"
fi

cat > "$CONFIG" <<'EOF'
upstream api_cluster {
    server 10.86.4.5:80;
    server 10.86.4.6:80;
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

echo "=== VERIFIKASI GETO ==="
nginx -T

