#!/bin/bash

echo "[WORKER05] Estableciendo hostname..."
hostnamectl set-hostname worker05

echo "[WORKER05] Configurando IP estática con Netplan..."

cat <<EOF >/etc/netplan/01-netcfg.yaml
network:
  version: 2
  ethernets:
    enp0s3:
      dhcp4: no
      addresses:
        - 10.10.10.105/24
      nameservers:
        addresses: [8.8.8.8, 8.8.4.4]
      routes:
        - to: 0.0.0.0/0
          via: 10.10.10.1
          metric: 100

    enp0s8:
      dhcp4: no
      addresses:
        - 20.20.20.26/24
      routes:
        - to: 0.0.0.0/0
          via: 20.20.20.1
          metric: 200

    enp0s9:
      dhcp4: yes
EOF

echo "[WORKER05] Aplicando configuración de red..."
netplan apply

echo "[WORKER05] Instalando NFS Kernel Server..."
apt update
apt install -y nfs-kernel-server

echo "[WORKER05] Creando carpeta compartida para WordPress..."
mkdir -p /var/nfs/wordpress
chmod 777 /var/nfs/wordpress

echo "[WORKER05] Configurando archivo /etc/exports..."
cat <<EOF >/etc/exports
/var/nfs/wordpress 20.20.20.22(rw,sync,no_subtree_check) 20.20.20.23(rw,sync,no_subtree_check)
EOF

echo "[WORKER05] Exportando recursos NFS..."
exportfs -arv

echo "[WORKER05] Reiniciando y habilitando NFS Server..."
systemctl restart nfs-kernel-server
systemctl enable nfs-kernel-server

echo "[✔] WORKER05 configurado como servidor NFS correctamente 🟢"
