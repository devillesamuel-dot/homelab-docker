#!/bin/bash

# Variables
BACKUP_DIR="${HOME}/backups"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="homelab_backup_${DATE}"

echo "🚀 Démarrage backup homelab..."

# Crée le dossier de backup
mkdir -p "${BACKUP_DIR}/${BACKUP_NAME}"

# 1. Backup des docker-compose files
echo "📁 Backup des compose files..."
cp -r "${HOME}/docker" "${BACKUP_DIR}/${BACKUP_NAME}/" 2>/dev/null || echo "⚠️ Pas de ~/docker"

# 2. Backup des configs (légères) - SANS sudo
echo "⚙️ Backup des configs..."
tar -czf "${BACKUP_DIR}/${BACKUP_NAME}/configs.tar.gz" \
  /mnt/docker-volumes/prometheus/config \
  /mnt/docker-volumes/traefik \
  /mnt/docker-volumes/portainer/docker_config 2>/dev/null || echo "⚠️ Certains dossiers inaccessibles"

# 3. Liste des containers et images
echo "🐳 Backup de la liste Docker..."
docker ps -a > "${BACKUP_DIR}/${BACKUP_NAME}/containers.txt"
docker images > "${BACKUP_DIR}/${BACKUP_NAME}/images.txt"

# 4. Compression finale
echo "🗜️ Compression..."
cd "${BACKUP_DIR}" || exit 1
tar -czf "${BACKUP_NAME}.tar.gz" "${BACKUP_NAME}/"
rm -rf "${BACKUP_NAME}"

# 5. Nettoyage (garde seulement les 7 derniers backups)
ls -t "${BACKUP_DIR}"/homelab_backup_*.tar.gz 2>/dev/null | tail -n +8 | xargs -r rm

echo "✅ Backup terminé : ${BACKUP_DIR}/${BACKUP_NAME}.tar.gz"
echo "📦 Taille : $(du -h "${BACKUP_DIR}/${BACKUP_NAME}.tar.gz" 2>/dev/null | cut -f1)"
