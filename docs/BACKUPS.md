# 💾 Stratégie de Backup & Disaster Recovery

## Vue d'ensemble

Deux types de backups complémentaires :

1. **Backups légers quotidiens** : Configurations, scripts
2. **Backups complets hebdomadaires** : Données volumes

## Scripts de backup

### backup-homelab.sh (Quotidien)

Localisation : `~/backups/backup-homelab.sh`

**Contenu :**
- Docker Compose files
- Scripts
- Liste des containers et images
- Configurations légères

**Taille moyenne** : ~12K  
**Rétention** : 7 jours  
**Horaire** : 3h du matin
```bash
#!/bin/bash

BACKUP_DIR="${HOME}/backups"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="homelab_backup_${DATE}"

echo "🚀 Démarrage backup homelab..."

mkdir -p "${BACKUP_DIR}/${BACKUP_NAME}"

# Backup des docker-compose files
cp -r "${HOME}/docker" "${BACKUP_DIR}/${BACKUP_NAME}/"

# Backup des configs
tar -czf "${BACKUP_DIR}/${BACKUP_NAME}/configs.tar.gz" \
  /mnt/docker-volumes/prometheus/config \
  /mnt/docker-volumes/traefik \
  /mnt/docker-volumes/portainer/docker_config 2>/dev/null

# Liste des containers
docker ps -a > "${BACKUP_DIR}/${BACKUP_NAME}/containers.txt"
docker images > "${BACKUP_DIR}/${BACKUP_NAME}/images.txt"

# Compression
cd "${BACKUP_DIR}"
tar -czf "${BACKUP_NAME}.tar.gz" "${BACKUP_NAME}/"
rm -rf "${BACKUP_NAME}"

# Nettoyage (garde 7 derniers)
ls -t "${BACKUP_DIR}"/homelab_backup_*.tar.gz | tail -n +8 | xargs -r rm

echo "✅ Backup terminé : ${BACKUP_DIR}/${BACKUP_NAME}.tar.gz"
```

### backup-data.sh (Hebdomadaire)

**Contenu :**
- Tous les volumes Docker
- Données Grafana, Prometheus, Portainer
- Données CrowdSec

**Taille moyenne** : ~500MB  
**Rétention** : 3 semaines  
**Horaire** : Dimanche 4h
```bash
#!/bin/bash

BACKUP_DIR="${HOME}/backups"
DATE=$(date +%Y%m%d_%H%M%S)

echo "💾 Backup des données Docker..."
sudo tar -czf "${BACKUP_DIR}/data_backup_${DATE}.tar.gz" /mnt/docker-volumes/

# Nettoyage (garde 3 derniers)
ls -t "${BACKUP_DIR}"/data_backup_*.tar.gz | tail -n +4 | xargs -r sudo rm

echo "✅ Backup données terminé"
```

## Automatisation cron
```bash
# Édite le crontab
crontab -e

# Ajoute ces lignes :
# Backup léger quotidien à 3h
0 3 * * * /home/samadmin/backups/backup-homelab.sh >> /home/samadmin/backups/backup.log 2>&1

# Backup complet hebdomadaire dimanche 4h
0 4 * * 0 /home/samadmin/backups/backup-data.sh >> /home/samadmin/backups/backup-data.log 2>&1
```

## Stockage des backups

**Local** : `~/backups/` (disque USB 3TB monté sur `/mnt/docker-volumes/`)

**Recommandation** : Copie vers NAS ou cloud
```bash
# Exemple : Sync vers NAS
rsync -avz ~/backups/ user@nas:/backups/homelab/

# Ou vers cloud (rclone)
rclone sync ~/backups/ remote:homelab-backups/
```

## Restauration

### Restauration config (backup léger)
```bash
# 1. Extrais le backup
cd ~/backups
tar -xzf homelab_backup_YYYYMMDD_HHMMSS.tar.gz
cd homelab_backup_YYYYMMDD_HHMMSS

# 2. Restaure les docker-compose
cp -r docker/* ~/docker/

# 3. Redéploie
cd ~/docker/monitoring && docker compose up -d
cd ~/docker/traefik && docker compose up -d
```

### Restauration données (backup complet)
```bash
# 1. Stop tous les containers
cd ~/docker/monitoring && docker compose down
cd ~/docker/traefik && docker compose down
cd ~/docker/crowdsec && docker compose down

# 2. Restaure les volumes
cd ~/backups
sudo tar -xzf data_backup_YYYYMMDD_HHMMSS.tar.gz -C /

# 3. Redémarre
cd ~/docker/monitoring && docker compose up -d
cd ~/docker/traefik && docker compose up -d
cd ~/docker/crowdsec && docker compose up -d
```

## Vérification des backups
```bash
# Liste les backups
ls -lh ~/backups/

# Vérifie l'intégrité
tar -tzf homelab_backup_YYYYMMDD_HHMMSS.tar.gz

# Vérifie les logs
tail -50 ~/backups/backup.log
tail -50 ~/backups/backup-data.log
```

## Disaster Recovery Plan

### Scénario 1 : Perte d'un container
```bash
# Redéploie juste ce service
cd ~/docker/monitoring
docker compose up -d grafana
```

### Scénario 2 : Corruption des données
```bash
# Restaure depuis le dernier backup data
# (voir section restauration ci-dessus)
```

### Scénario 3 : Perte complète du serveur

1. Réinstalle Ubuntu Server 24.04
2. Installe Docker
3. Clone le repo GitHub
4. Restaure le dernier backup data
5. Redéploie les services

**Temps de restauration estimé** : 1-2 heures

## Best practices

✅ **Teste régulièrement les restaurations**
✅ **Stocke les backups hors du serveur**
✅ **Vérifie les logs de backup**
✅ **Documente les procédures**
✅ **Garde plusieurs versions**

## Ressources

- [Docker backup best practices](https://docs.docker.com/storage/volumes/#back-up-restore-or-migrate-data-volumes)
- [rsync documentation](https://linux.die.net/man/1/rsync)
