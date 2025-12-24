# 🔍 Guide de Dépannage

## Problèmes courants et solutions

### Container ne démarre pas
```bash
# Vérifie les logs
docker logs nom-container

# Vérifie la config
docker inspect nom-container

# Redémarre
docker restart nom-container

# Ou recréé
cd ~/docker/service
docker compose down
docker compose up -d
```

### Service inaccessible via Traefik

**Symptôme** : 404 ou Gateway Timeout
```bash
# 1. Vérifie que le container est UP
docker ps | grep nom-service

# 2. Vérifie les labels Traefik
docker inspect nom-service | grep -A 10 Labels

# 3. Vérifie les réseaux
docker inspect nom-service | grep -A 5 Networks
# Le service doit être dans traefik-net

# 4. Connecte au réseau si besoin
docker network connect traefik-net nom-service

# 5. Vérifie les logs Traefik
docker logs traefik | grep nom-service

# 6. Teste l'accès direct (sans Traefik)
curl http://localhost:PORT
```

### Prometheus ne scrape pas une target

**Symptôme** : Target DOWN dans `/targets`
```bash
# 1. Vérifie la config Prometheus
cat /mnt/docker-volumes/prometheus/config/prometheus.yml

# 2. Vérifie que la target est accessible
docker exec prometheus curl http://target:port/metrics

# 3. Recharge la config
docker exec prometheus kill -HUP 1

# 4. Vérifie les logs
docker logs prometheus | grep -i error
```

### Grafana : Dashboards vides
```bash
# 1. Vérifie la data source
# Grafana UI → Configuration → Data Sources
# Test la connexion

# 2. Vérifie les queries
# Edit panel → Query inspector

# 3. Vérifie Prometheus
curl http://prometheus:9090/api/v1/query?query=up

# 4. Vérifie les métriques
curl http://prometheus:9090/api/v1/label/__name__/values
```

### CrowdSec ne détecte rien
```bash
# 1. Vérifie l'acquisition
docker exec crowdsec cat /etc/crowdsec/acquis.yaml

# 2. Vérifie que les logs sont lus
docker exec crowdsec cscli metrics

# 3. Vérifie les scénarios
docker exec crowdsec cscli scenarios list

# 4. Test manuel
docker exec crowdsec tail /var/log/traefik/access.log
```

### Espace disque plein
```bash
# Vérifie l'utilisation
df -h
docker system df

# Nettoie les images inutilisées
docker image prune -a

# Nettoie les volumes inutilisés
docker volume prune

# Nettoie tout (ATTENTION!)
docker system prune -a --volumes
```

### Problèmes de permissions
```bash
# Vérifie les propriétaires
ls -la /mnt/docker-volumes/

# Corrige les permissions
sudo chown -R samadmin:samadmin /mnt/docker-volumes/service/

# Pour Grafana (user 472)
sudo chown -R 472:472 /mnt/docker-volumes/grafana/
```

### Docker Compose échoue
```bash
# Vérifie la syntaxe YAML
docker compose config

# Vérifie les réseaux
docker network ls

# Recrée les réseaux si besoin
docker network create traefik-net
docker network create monitoring

# Force la recréation
docker compose up -d --force-recreate
```

### Backup échoue
```bash
# Vérifie les logs
cat ~/backups/backup.log
cat ~/backups/backup-data.log

# Vérifie l'espace disque
df -h ~/backups/

# Teste manuellement
bash ~/backups/backup-homelab.sh
```

## Commandes de diagnostic
```bash
# État général
docker ps -a
docker stats
df -h
free -h

# Logs
docker logs -f nom-container
journalctl -u docker -f

# Réseaux
docker network ls
docker network inspect traefik-net

# Volumes
docker volume ls
docker volume inspect nom-volume
```

## Réinitialisation complète

**En dernier recours :**
```bash
# 1. Backup d'abord!
bash ~/backups/backup-data.sh

# 2. Stop tout
cd ~/docker/monitoring && docker compose down
cd ~/docker/traefik && docker compose down
cd ~/docker/crowdsec && docker compose down

# 3. Nettoie tout (DESTRUCTIF!)
docker system prune -a --volumes

# 4. Redéploie
cd ~/docker/traefik && docker compose up -d
cd ~/docker/monitoring && docker compose up -d
cd ~/docker/crowdsec && docker compose up -d
```

## Obtenir de l'aide

- 📚 Documentation du projet
- 🐙 Issues GitHub
- 💬 Forums Docker
- 🔍 Stack Overflow
