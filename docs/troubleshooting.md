# 🔧 Guide de Dépannage

Ce guide documente les problèmes courants rencontrés et leurs solutions.

---

## Table des Matières

1. [Problèmes de Démarrage](#problèmes-de-démarrage)
2. [Prometheus](#prometheus)
3. [Traefik](#traefik)
4. [Grafana](#grafana)
5. [Portainer](#portainer)
6. [Réseau et DNS](#réseau-et-dns)
7. [Permissions](#permissions)

---

## Problèmes de Démarrage

### Les containers ne démarrent pas au boot

**Symptômes :**
- Après un redémarrage du serveur, les containers sont tous en état `Exited`
- `docker ps` ne montre aucun container actif

**Cause :**
Les stacks Docker ne sont pas configurées pour démarrer automatiquement.

**Solution :**

1. Vérifier que `restart: unless-stopped` est présent dans tous les services du docker-compose.yml

2. Créer des services systemd (voir [guide d'installation](installation.md#démarrage-automatique-au-boot))

3. Redémarrer manuellement en attendant :
```bash
cd ~/homelab-docker/traefik
docker compose up -d

cd ~/homelab-docker/monitoring
docker compose up -d
```

---

### Container en boucle de redémarrage (Restarting)

**Symptômes :**
- Un container affiche `Restarting (X)` dans `docker ps`
- Le container démarre puis crash immédiatement

**Diagnostic :**
```bash
# Voir les logs du container
docker logs [nom_du_container] --tail 50

# Voir les dernières tentatives de démarrage
docker inspect [nom_du_container] | grep -A 10 State
```

**Solutions courantes :**
- Problème de permissions sur les volumes
- Fichier de configuration manquant ou invalide
- Port déjà utilisé par un autre processus
- Conflit de réseau Docker

---

## Prometheus

### Prometheus - "No scrape pools found"

**Symptômes :**
- Page `/targets` de Prometheus vide
- Message "No scrape pools found"

**Cause :**
Le fichier `prometheus.yml` est manquant ou mal placé.

**Solution :**
```bash
# Vérifier l'emplacement du fichier
ls -la /mnt/docker-volumes/prometheus/config/prometheus.yml

# Si le fichier n'existe pas, le copier
cp ~/homelab-docker/monitoring/prometheus.yml /mnt/docker-volumes/prometheus/config/

# Vérifier les permissions
sudo chown samadmin:samadmin /mnt/docker-volumes/prometheus/config/prometheus.yml

# Redémarrer Prometheus
cd ~/homelab-docker/monitoring
docker compose restart prometheus

# Vérifier les logs
docker logs prometheus --tail 30
```

---

### Prometheus - "Error loading config: input/output error"

**Symptômes :**
```
level=ERROR msg="Error loading config (--config.file=/etc/prometheus/prometheus.yml)"
file=/etc/prometheus/prometheus.yml err="open /etc/prometheus/prometheus.yml: input/output error"
```

**Cause :**
- Fichier de configuration corrompu
- Problème de permissions
- Volume non monté correctement

**Solution :**
```bash
# Arrêter Prometheus
cd ~/homelab-docker/monitoring
docker compose stop prometheus

# Vérifier le volume
docker inspect prometheus | grep -A 10 Mounts

# Recréer la config
sudo nano /mnt/docker-volumes/prometheus/config/prometheus.yml
# (Copier le contenu depuis monitoring/prometheus.yml)

# Permissions
sudo chown samadmin:samadmin /mnt/docker-volumes/prometheus/config/prometheus.yml

# Redémarrer
docker compose up -d prometheus
```

---

### Prometheus - "permission denied" sur /prometheus/queries.active

**Symptômes :**
```
panic: Unable to create mmap-ed active query log
err="open /prometheus/queries.active: permission denied"
```

**Cause :**
Prometheus ne peut pas écrire dans le volume `/prometheus/`

**Solution :**
```bash
# Arrêter Prometheus
cd ~/homelab-docker/monitoring
docker compose stop prometheus

# Corriger les permissions
sudo chown -R samadmin:samadmin /mnt/docker-volumes/prometheus/data/

# OU lancer Prometheus en root (dans docker-compose.yml)
# Ajouter : user: "root"

# Redémarrer
docker compose up -d prometheus
```

---

## Traefik

### Traefik - Gateway Timeout (504)

**Symptômes :**
- Accès à `http://service.lab.local` → Erreur 504 Gateway Timeout
- Le service fonctionne en accès direct par IP:port

**Cause :**
Le container n'est pas sur le réseau `traefik-net` ou Traefik ne le détecte pas.

**Solution :**
```bash
# Vérifier que le container est sur traefik-net
docker network inspect traefik-net | grep [nom_du_container]

# Si absent, connecter manuellement
docker network connect traefik-net [nom_du_container]

# OU ajouter dans docker-compose.yml :
labels:
  - "traefik.docker.network=traefik-net"  # Force l'utilisation du bon réseau

# Redémarrer le service
docker compose restart [nom_du_service]

# Vérifier dans le dashboard Traefik
# http://192.168.10.52:8080 → HTTP → Routers
```

---

### Traefik - Service non détecté

**Symptômes :**
- Le service n'apparaît pas dans le dashboard Traefik
- Aucune route créée automatiquement

**Cause :**
Labels Traefik manquants ou incorrects.

**Solution :**

Vérifier les labels requis dans le docker-compose.yml :
```yaml
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.SERVICE.rule=Host(`service.lab.local`)"
  - "traefik.http.routers.SERVICE.entrypoints=web"
  - "traefik.http.services.SERVICE.loadbalancer.server.port=PORT"
  - "traefik.docker.network=traefik-net"  # Important si plusieurs réseaux
```

Redémarrer :
```bash
docker compose up -d --force-recreate [service]
```

---

## Grafana

### Grafana - "unable to open database file"

**Symptômes :**
```
Error ✗ unable to open database file: input/output error
```

**Cause :**
Base de données SQLite corrompue ou permissions incorrectes.

**Solution :**
```bash
# Arrêter Grafana
cd ~/homelab-docker/traefik
docker compose stop grafana

# Sauvegarder l'ancienne DB
sudo mv /mnt/docker-volumes/grafana/grafana.db /mnt/docker-volumes/grafana/grafana.db.backup

# Supprimer les données corrompues
sudo rm -rf /mnt/docker-volumes/grafana/*

# Recréer avec les bonnes permissions
sudo mkdir -p /mnt/docker-volumes/grafana
sudo chown -R 472:472 /mnt/docker-volumes/grafana/

# Redémarrer (va recréer une DB propre)
docker compose up -d grafana
```

**Note :** Vous devrez reconfigurer Grafana (datasources, dashboards).

---

### Grafana - Dashboard Node Exporter vide ("No data")

**Symptômes :**
- Dashboard importé mais tous les graphiques affichent "No data"
- Ou "N/A" dans les jauges

**Cause :**
- Prometheus non connecté comme datasource
- Filtres du dashboard incorrects
- Prometheus ne collecte pas les métriques

**Solution :**

1. **Vérifier la datasource Prometheus dans Grafana :**
   - Connections → Data sources → Prometheus
   - Tester la connexion : "Save & Test" → doit afficher "Data source is working"

2. **Vérifier les targets Prometheus :**
   - http://prometheus.lab.local/targets
   - node-exporter doit être UP

3. **Ajuster les filtres du dashboard :**
   - En haut du dashboard, dans les dropdowns :
   - Job : sélectionner "node-exporter"
   - Instance : sélectionner l'instance disponible

---

## Portainer

### Portainer - "failed opening store: open /data/portainer.db: input/output error"

**Symptômes :**
```
failed opening store: error="open /data/portainer.db: input/output error"
```

**Cause :**
Base de données SQLite corrompue.

**Solution :**
```bash
# Arrêter Portainer
cd ~/homelab-docker/traefik
docker compose stop portainer

# Sauvegarder
sudo mv /mnt/docker-volumes/portainer/portainer.db /mnt/docker-volumes/portainer/portainer.db.backup

# Nettoyer
sudo rm -rf /mnt/docker-volumes/portainer/*

# Permissions
sudo chown -R samadmin:samadmin /mnt/docker-volumes/portainer/

# Redémarrer
docker compose up -d portainer
```

**Note :** Vous devrez recréer le compte administrateur.

---

## Réseau et DNS

### Service accessible par IP mais pas par nom de domaine

**Symptômes :**
- http://192.168.10.52:8080 fonctionne
- http://service.lab.local ne fonctionne pas

**Cause :**
Problème de résolution DNS.

**Solution :**

**Sur votre machine cliente :**
```bash
# Vérifier la résolution DNS
ping service.lab.local

# Si échec, ajouter dans /etc/hosts
sudo nano /etc/hosts
# Ajouter :
192.168.10.52  service.lab.local

# OU configurer dnsmasq (voir installation.md)
```

---

### Conflits de réseau Docker

**Symptômes :**
- Erreur "network ... already exists"
- Containers ne peuvent pas communiquer entre eux

**Solution :**
```bash
# Lister les réseaux
docker network ls

# Supprimer et recréer
docker network rm traefik-net
docker network rm monitoring

docker network create traefik-net
docker network create monitoring

# Redémarrer les stacks
cd ~/homelab-docker/traefik && docker compose up -d
cd ~/homelab-docker/monitoring && docker compose up -d
```

---

## Permissions

### Problème général de permissions

**Symptômes :**
- Messages "permission denied" dans les logs
- Containers qui crashent au démarrage

**Solution générale :**
```bash
# Vérifier les permissions actuelles
ls -la /mnt/docker-volumes/

# Corriger pour tous les services
sudo chown -R samadmin:samadmin /mnt/docker-volumes/portainer/
sudo chown -R samadmin:samadmin /mnt/docker-volumes/prometheus/
sudo chown -R 472:472 /mnt/docker-volumes/grafana/  # User spécifique pour Grafana
sudo chown -R samadmin:samadmin /mnt/docker-volumes/traefik/
```

---

## Commandes Utiles de Diagnostic
```bash
# Voir l'état de tous les containers
docker ps -a

# Voir les logs d'un container
docker logs [container] --tail 50
docker logs [container] -f  # Suivre en temps réel

# Inspecter un container
docker inspect [container]

# Voir les réseaux d'un container
docker inspect [container] | grep -A 20 Networks

# Tester la connectivité entre containers
docker exec [container1] ping [container2]

# Voir l'utilisation des ressources
docker stats

# Redémarrer un service proprement
cd ~/homelab-docker/[service]
docker compose restart [service]

# Recréer un service
docker compose up -d --force-recreate [service]

# Supprimer et recréer complètement
docker compose down
docker compose up -d
```

---

## Obtenir de l'Aide

Si vous rencontrez un problème non documenté ici :

1. **Vérifier les logs** : `docker logs [container] --tail 100`
2. **Chercher l'erreur** : Copier le message d'erreur dans Google
3. **Ouvrir une issue** : Sur GitLab avec les logs et la description du problème

---

**💡 Astuce :** Gardez ce guide à portée de main ! La plupart des problèmes sont récurrents et ont des solutions connues.
