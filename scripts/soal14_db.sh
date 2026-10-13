#!/bin/sh
mysql -u root -e "
CREATE DATABASE IF NOT EXISTS db_shibuya_K01;
CREATE TABLE IF NOT EXISTS db_shibuya_K01.request_logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    client_ip VARCHAR(45) NOT NULL,
    worker_node VARCHAR(50) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
GRANT ALL PRIVILEGES ON db_shibuya_K01.* TO 'replicator'@'%' IDENTIFIED BY 'k45pass';
FLUSH PRIVILEGES;
"
