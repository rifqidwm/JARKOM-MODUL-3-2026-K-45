
#!/bin/sh
set -eu

# SOAL 16 - Path-Based Reverse Proxy
# Node: Gojo

apk add --no-cache nginx

mkdir -p /etc/nginx/sites-available /etc/nginx/sites-enabled

CONFIG="/etc/nginx/sites-available/default"

if [ -f "$CONFIG" ]; then
    cp "$CONFIG" "$CONFIG.bak-soal16"
fi

cat > "$CONFIG" <<'EOF'
upstream frontend_cluster {
    server 10.86.4.3:80;
    server 10.86.4.4:80;
}

upstream api_cluster {
    server 10.86.4.2:80;
}

server {
    listen 80;
    server_name jujutsu.k45.com;

    location /api {
        proxy_pass http://api_cluster;

        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location / {
        proxy_pass http://frontend_cluster;

        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

ln -sf "$CONFIG" /etc/nginx/sites-enabled/default

nginx -t
nginx -s reload 2>/dev/null || {
    pkill nginx 2>/dev/null || true
    nginx
}

echo "=== KONFIGURASI GOJO ==="
nginx -T

