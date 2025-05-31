#!/bin/bash

echo "[WORKER02] Estableciendo hostname..."
hostnamectl set-hostname worker02

echo "[WORKER02] Configurando IP estática con Netplan..."

cat <<EOF >/etc/netplan/01-netcfg.yaml
network:
  version: 2
  ethernets:
    enp0s3:
      dhcp4: no
      addresses:
        - 10.10.10.102/24
      nameservers:
        addresses: [8.8.8.8, 8.8.4.4]
      routes:
        - to: 0.0.0.0/0
          via: 10.10.10.1
          metric: 100

    enp0s8:
      dhcp4: no
      addresses:
        - 20.20.20.23/24
      routes:
        - to: 0.0.0.0/0
          via: 20.20.20.1
          metric: 200

    enp0s9:
      dhcp4: yes
EOF

echo "[WORKER02] Aplicando configuración de red..."
netplan apply

echo "[WORKER02] Instalando NGINX y PHP-FPM con extensiones necesarias..."
apt update
apt install -y nginx php-fpm php-mysql php-curl php-gd php-xml php-mbstring php-zip php-intl unzip curl

echo "[WORKER02] Descargando y desplegando WordPress..."
cd /tmp
curl -O https://wordpress.org/latest.zip
unzip latest.zip
mv wordpress /var/www/
chown -R www-data:www-data /var/www/wordpress

echo "[WORKER02] Configurando wp-config.php base..."
cd /var/www/wordpress
cp wp-config-sample.php wp-config.php

echo "[WORKER02] Configurando NGINX para WordPress..."
cat <<EOF >/etc/nginx/sites-available/wordpress
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    root /var/www/wordpress;
    index index.php index.html index.htm;

    server_name _;

    location / {
        try_files $uri $uri/ /index.php?$args;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php8.3-fpm.sock;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF

echo "[WORKER02] Activando configuración de NGINX..."
ln -s /etc/nginx/sites-available/wordpress /etc/nginx/sites-enabled/
rm /etc/nginx/sites-enabled/default

echo "[WORKER02] Reiniciando NGINX..."
systemctl restart nginx

echo "[WORKER02] Listo 🟢 WordPress está instalado y funcionando en NGINX"
