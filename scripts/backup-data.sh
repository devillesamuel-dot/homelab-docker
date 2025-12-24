#!/bin/bash

BACKUP_DIR="${HOME}/backups"
DATE=$(date +%Y%m%d_%H%M%S)

echo "💾 Backup des données Docker..."
sudo tar -czf "${BACKUP_DIR}/data_backup_${DATE}.tar.gz" /mnt/docker-volumes/

echo "✅ Backup données terminé : ${BACKUP_DIR}/data_backup_${DATE}.tar.gz"
echo "📦 Taille : $(du -h "${BACKUP_DIR}/data_backup_${DATE}.tar.gz" | cut -f1)"

# Garde seulement les 3 derniers backups de data (ils sont gros)
ls -t "${BACKUP_DIR}"/data_backup_*.tar.gz 2>/dev/null | tail -n +4 | xargs -r sudo rm
