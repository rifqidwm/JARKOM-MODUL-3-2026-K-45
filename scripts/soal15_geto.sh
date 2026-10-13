#!/bin/sh
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y nginx

cat > /etc/nginx/sites-available/default << 'EOT'
upstream api_cluster {
    server 10.86.4.5 weight=3;    # nanami
    server 10.86.4.6 weight=1;    # todo
}

server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://api_cluster;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
EOT

pkill -9 nginx || true
nginx
