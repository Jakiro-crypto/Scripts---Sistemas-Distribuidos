#!/bin/bash

echo "[MASTER] Estableciendo hostname..."
hostnamectl set-hostname master

echo "[MASTER] Configurando IP estática con Netplan..."

cat <<EOF >/etc/netplan/01-netcfg.yaml
network:
  version: 2
  ethernets:
    enp0s3:
      dhcp4: no
      addresses:
        - 10.10.10.100/24
      nameservers:
        addresses: [8.8.8.8, 8.8.4.4]
      routes:
        - to: 0.0.0.0/0
          via: 10.10.10.1
          metric: 100

    enp0s8:
      dhcp4: no
      addresses:
        - 20.20.20.21/24
      routes:
        - to: 0.0.0.0/0
          via: 20.20.20.1
          metric: 200

    enp0s9:
      dhcp4: yes
EOF

echo "[MASTER] Aplicando configuración de red..."
netplan apply

echo "[MASTER] Instalando Nginx..."
apt update && apt install -y nginx

echo "[MASTER] Configurando Nginx como balanceador de carga..."

cat <<EOF >/etc/nginx/sites-available/wordpress_lb
upstream wordpress {
    server 20.20.20.22;
    server 20.20.20.23;
}

server {
        listen 80;
        server_name _;

        location / {
                proxy_pass http://wordpress_servers;
                proxy_set_header Host $host;
                proxy_set_header X-Real-IP $remote_addr;
                proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                proxy_set_header X-Forwarded-Proto $scheme;          
        }
}
EOF

ln -s /etc/nginx/sites-available/wordpress_lb /etc/nginx/sites-enabled/wordpress_lb

echo "[MASTER] Eliminando configuración por defecto de Nginx..."
rm /etc/nginx/sites-enabled/default 2>/dev/null

echo "[MASTER] Reiniciando Nginx..."
systemctl restart nginx

echo "[MASTER] Configuración completada con éxito 🎉"
