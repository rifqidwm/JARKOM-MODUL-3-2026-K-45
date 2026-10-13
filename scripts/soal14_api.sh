#!/bin/sh
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y nginx php-fpm php-mysql mariadb-client

mkdir -p /var/www/html/api
cat > /var/www/html/api/index.php << 'EOT'
<?php
header('Content-Type: application/json');
$host = '10.86.4.8';
$user = 'replicator';
$pass = 'k45pass';
$db   = 'db_shibuya_K01';

try {
    $conn = new mysqli($host, $user, $pass, $db);
    if (!$conn->connect_error) {
        $client_ip = $_SERVER['HTTP_X_REAL_IP'] ?? $_SERVER['REMOTE_ADDR'];
        $worker_host = gethostname();
        $sql = "INSERT INTO request_logs (client_ip, worker_node) VALUES ('$client_ip', '$worker_host')";
        @$conn->query($sql);
    }
} catch (Exception $e) {}

echo json_encode([
    "status" => "success",
    "worker" => gethostname(),
    "message" => "API request processed"
]);
?>
EOT

cat > /etc/nginx/sites-available/default << 'EOT'
server {
    listen 80;
    server_name _;
    root /var/www/html;
    index index.php index.html;

    location / {
        try_files $uri $uri/ /api/index.php?$query_string;
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
