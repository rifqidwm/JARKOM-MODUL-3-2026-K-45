
#!/bin/sh
set -eu

# SOAL 19 - Proxy Cache dan Rate Limiting
# Node: Gojo

apk add --no-cache nginx

SITE="/etc/nginx/sites-available/default"
LIMIT_CONFIG="/etc/nginx/conf.d/soal19-cache-limit.conf"

mkdir -p /etc/nginx/sites-available /etc/nginx/sites-enabled
mkdir -p /var/cache/nginx/proxy_cache

if [ -f "$SITE" ]; then
    cp "$SITE" "$SITE.bak-soal19"
fi

if [ -f "$LIMIT_CONFIG" ]; then
    cp "$LIMIT_CONFIG" "$LIMIT_CONFIG.bak"
fi

cat > "$LIMIT_CONFIG" <<'EOF'
limit_req_zone $binary_remote_addr
    zone=api_limit:10m
    rate=10r/s;

proxy_cache_path /var/cache/nginx/proxy_cache
    levels=1:2
    keys_zone=frontend_cache:10m
    max_size=100m
    inactive=10m
    use_temp_path=off;
EOF

cat > "$SITE" <<'EOF'
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
        limit_req zone=api_limit burst=10 nodelay;
        limit_req_status 429;

        proxy_pass http://api_cluster;

        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location / {
        proxy_pass http://frontend_cluster;

        proxy_cache frontend_cache;
        proxy_cache_valid 200 10m;
        proxy_cache_key "$scheme$request_method$host$request_uri";

        add_header X-Cache-Status $upstream_cache_status always;

        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

ln -sf "$SITE" /etc/nginx/sites-enabled/default

nginx -t
nginx -s reload 2>/dev/null || {
    pkill nginx 2>/dev/null || true
    nginx
}

echo "=== SOAL 19: KONFIGURASI ==="
nginx -T

