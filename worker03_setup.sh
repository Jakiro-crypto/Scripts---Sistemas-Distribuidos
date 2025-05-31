#!/bin/bash

echo "[WORKER03] Estableciendo hostname..."
hostnamectl set-hostname worker03

echo "[WORKER03] Configurando IP estática con Netplan..."

cat <<EOF >/etc/netplan/01-netcfg.yaml
network:
  version: 2
  ethernets:
    enp0s3:
      dhcp4: no
      addresses:
        - 10.10.10.103/24
      nameservers:
        addresses: [8.8.8.8, 8.8.4.4]
      routes:
        - to: 0.0.0.0/0
          via: 10.10.10.1
          metric: 100

    enp0s8:
      dhcp4: no
      addresses:
        - 20.20.20.24/24
      routes:
        - to: 0.0.0.0/0
          via: 20.20.20.1
          metric: 200

    enp0s9:
      dhcp4: yes
EOF

echo "[WORKER03] Aplicando configuración de red..."
netplan apply

echo "[WORKER03] Instalando MySQL Server..."
apt update
apt install -y mysql-server

echo "[WORKER03] Creando base de datos y usuario de WordPress..."
mysql -u root <<EOF
CREATE DATABASE wordpress;
CREATE USER 'wp_user'@'%' IDENTIFIED BY 'contra12345';
GRANT ALL PRIVILEGES ON wordpress.* TO 'wp_user'@'%';
FLUSH PRIVILEGES;
EOF

echo "[WORKER03] Configurando MySQL como MASTER..."
sed -i "s/^bind-address.*/bind-address = 20.20.20.24/" /etc/mysql/mysql.conf.d/mysqld.cnf
sed -i "s/^#server-id.*/server-id = 1/" /etc/mysql/mysql.conf.d/mysqld.cnf
sed -i "s|^#log_bin.*|log_bin = /var/log/mysql/mysql-bin.log|" /etc/mysql/mysql.conf.d/mysqld.cnf

echo "[WORKER03] Reiniciando servicio MySQL..."
systemctl restart mysql

echo "[WORKER03] Creando usuario para replicación..."
mysql -u root <<EOF
CREATE USER 'replica'@'%' IDENTIFIED WITH mysql_native_password BY 'contra12345';
GRANT REPLICATION SLAVE ON *.* TO 'replica'@'%';
FLUSH PRIVILEGES;
FLUSH TABLES WITH READ LOCK;
UNLOCK TABLES;
EOF

echo "[WORKER03] ✅ Configuración finalizada. Servidor MySQL MASTER listo para replicación."
