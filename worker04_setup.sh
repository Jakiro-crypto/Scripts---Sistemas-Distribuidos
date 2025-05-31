#!/bin/bash

echo "[WORKER04] Estableciendo hostname..."
hostnamectl set-hostname worker04

echo "[WORKER04] Configurando IP estática con Netplan..."

cat <<EOF >/etc/netplan/01-netcfg.yaml
network:
  version: 2
  ethernets:
    enp0s3:
      dhcp4: no
      addresses:
        - 10.10.10.104/24
      nameservers:
        addresses: [8.8.8.8, 8.8.4.4]
      routes:
        - to: 0.0.0.0/0
          via: 10.10.10.1
          metric: 100

    enp0s8:
      dhcp4: no
      addresses:
        - 20.20.20.25/24
      routes:
        - to: 0.0.0.0/0
          via: 20.20.20.1
          metric: 200

    enp0s9:
      dhcp4: yes
EOF

echo "[WORKER04] Aplicando configuración de red..."
netplan apply

echo "[WORKER04] Instalando MySQL Server..."
apt update
apt install -y mysql-server

echo "[WORKER04] Configurando MySQL como SLAVE..."
sed -i "s/^bind-address.*/bind-address = 20.20.20.25/" /etc/mysql/mysql.conf.d/mysqld.cnf
sed -i "s/^#server-id.*/server-id = 2/" /etc/mysql/mysql.conf.d/mysqld.cnf
sed -i "s|^#log_bin.*|log_bin = /var/log/mysql/mysql-bin.log|" /etc/mysql/mysql.conf.d/mysqld.cnf

echo "[WORKER04] Reiniciando servicio MySQL..."
systemctl restart mysql

echo "[WORKER04] ✅ Configuración lista. Este nodo está preparado para conectarse como SLAVE al MASTER (worker03)."
