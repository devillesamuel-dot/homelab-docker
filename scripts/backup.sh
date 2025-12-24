#!/bin/bash

###############################################################################
# Script de Backup Automatique - Homelab Docker
# 
# Ce script sauvegarde :
# - Les volumes Docker (portainer, grafana, prometheus)
# - Les configurations (docker-compose.yml, prometheus.yml)
# 
# Usage: ./backup.sh
# Cron: 0 2 * * * /chemin/vers/backup.sh
###############################################################################

# Configuration
BACKUP_DIR="/mnt/docker-volumes/backups"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_PATH="$BACKUP_DIR/$DATE"
RETENTION_DAYS=7

# Couleurs pour l'affichage
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Homelab Docker - Backup Script${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "Date: $(date '+%Y-%m-%d %H:%M:%S')"
echo -e "Backup destination: $BACKUP_PATH"
echo ""

# Créer le dossier de backup
echo -e "${YELLOW}[1/5]${NC} Création du dossier de backup..."
mkdir -p "$BACKUP_PATH"

# Backup Portainer
echo -e "${YELLOW}[2/5]${NC} Backup de Portainer..."
if [ -d "/mnt/docker-volumes/portainer" ]; then
    tar -czf "$BACKUP_PATH/portainer.tar.gz" -C /mnt/docker-volumes portainer/
    echo -e "${GREEN}✓${NC} Portainer sauvegardé"
else
    echo -e "${RED}✗${NC} Dossier Portainer introuvable"
fi

# Backup Grafana
echo -e "${YELLOW}[3/5]${NC} Backup de Grafana..."
if [ -d "/mnt/docker-volumes/grafana" ]; then
    tar -czf "$BACKUP_PATH/grafana.tar.gz" -C /mnt/docker-volumes grafana/
    echo -e "${GREEN}✓${NC} Grafana sauvegardé"
else
    echo -e "${RED}✗${NC} Dossier Grafana introuvable"
fi

# Backup Prometheus
echo -e "${YELLOW}[4/5]${NC} Backup de Prometheus..."
if [ -d "/mnt/docker-volumes/prometheus" ]; then
    tar -czf "$BACKUP_PATH/prometheus.tar.gz" -C /mnt/docker-volumes prometheus/
    echo -e "${GREEN}✓${NC} Prometheus sauvegardé"
else
    echo -e "${RED}✗${NC} Dossier Prometheus introuvable"
fi

# Nettoyage des anciens backups
echo -e "${YELLOW}[5/5]${NC} Nettoyage des backups de plus de $RETENTION_DAYS jours..."
find "$BACKUP_DIR" -type d -mtime +$RETENTION_DAYS -exec rm -rf {} \; 2>/dev/null
echo -e "${GREEN}✓${NC} Nettoyage terminé"

# Statistiques
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Backup terminé avec succès !${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Taille du backup:"
du -sh "$BACKUP_PATH"
echo ""
echo "Backups disponibles:"
ls -lh "$BACKUP_DIR" | tail -n +2
echo ""
