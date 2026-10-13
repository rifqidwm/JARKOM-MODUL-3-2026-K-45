#!/bin/sh
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y nginx php-fpm

cat > /var/www/html/index.php << 'EOT'
<?php
echo "Frontend Worker Hostname: " . gethostname();
?>
EOT
rm -f /var/www/html/index.html

cat > /etc/nginx/sites-available/default << 'EOT'
server {
    listen 80;
    server_name _;
    root /var/www/html;
    index index.php index.html;

    location / {
        try_files $uri $uri/ =404;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php8.4-fpm.sock;
    }
}
EOT

pkill -9 nginx || true
pkill -9 php-fpm || true
/usr/sbin/php-fpm8.4 -D
nginx

