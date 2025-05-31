#!/bin/bash

# Dirección IP del servidor NFS (worker05)
NFS_SERVER_IP="20.20.20.26"
NFS_REMOTE_PATH="/var/nfs/wordpress"
LOCAL_MOUNT_PATH="/var/www/html/wp-content/uploads"

# 1. Instalar NFS client
echo "[+] Instalando nfs-common..."
sudo apt update
sudo apt install -y nfs-common

# 2. Crear carpeta de montaje si no existe
echo "[+] Creando directorio de montaje en $LOCAL_MOUNT_PATH"
sudo mkdir -p "$LOCAL_MOUNT_PATH"

# 3. Montar el recurso NFS
echo "[+] Montando $NFS_REMOTE_PATH desde $NFS_SERVER_IP..."
sudo mount "$NFS_SERVER_IP:$NFS_REMOTE_PATH" "$LOCAL_MOUNT_PATH"

# 4. Agregar entrada a /etc/fstab para montaje persistente
echo "[+] Añadiendo entrada a /etc/fstab..."
NFS_LINE="$NFS_SERVER_IP:$NFS_REMOTE_PATH $LOCAL_MOUNT_PATH nfs defaults 0 0"
grep -qF "$NFS_LINE" /etc/fstab || echo "$NFS_LINE" | sudo tee -a /etc/fstab

# Verificar montaje
echo "[+] Verificando montaje..."
df -h | grep "$LOCAL_MOUNT_PATH"

echo "[✔] NFS montado correctamente en $LOCAL_MOUNT_PATH"  