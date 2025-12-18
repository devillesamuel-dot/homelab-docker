# 🏗️ Architecture Technique Détaillée

## Vue d'Ensemble

Cette infrastructure repose sur une architecture microservices containerisée utilisant Docker comme plateforme de containerisation et Traefik comme reverse proxy dynamique.

---

## Schéma d'Architecture
```
                    ┌─────────────────────────────────────┐
                    │         Internet / LAN              │
                    └────────────────┬────────────────────┘
                                     │
                                     ▼
                    ┌─────────────────────────────────────┐
                    │     TRAEFIK (Reverse Proxy)         │
                    │   - Service Discovery automatique   │
                    │   - Load Balancing                  │
                    │   - HTTP/HTTPS routing              │
                    │                                     │
                    │   Ports: 80 (HTTP)                  │
                    │          443 (HTTPS)                │
                    │          8080 (Dashboard)           │
                    └─────────────┬───────────────────────┘
                                  │
                ┌─────────────────┼─────────────────┐
                │                 │                 │
                ▼                 ▼                 ▼
        ┌──────────┐      ┌──────────┐    ┌──────────┐
        │Portainer │      │ Grafana  │    │  Whoami  │
        │  :9000   │      │  :3000   │    │   :80    │
        └──────────┘      └─────┬────┘    └──────────┘
                                │
                                ▼
                          ┌──────────┐
                          │Prometheus│
                          │  :9090   │
                          └────┬─────┘
                               │
                ┌──────────────┴──────────────┐
                │                             │
                ▼                             ▼
        ┌──────────┐                  ┌──────────┐
        │   Node   │                  │ cAdvisor │
        │ Exporter │                  │  :8080   │
        │  :9100   │                  │          │
        └──────────┘                  └──────────┘
             │                             │
             ▼                             ▼
        System Metrics              Docker Metrics
        (CPU, RAM, Disk)           (Containers)
```

---

## Composants Détaillés

### 1. Traefik (Reverse Proxy)

**Rôle :**
- Point d'entrée unique pour tous les services HTTP/HTTPS
- Routage dynamique basé sur les labels Docker
- Découverte automatique des services
- Load balancing
- Terminaison SSL (à configurer)

**Configuration :**
- Image : `traefik:latest`
- Réseaux : `traefik-net`
- Volumes :
  - `/var/run/docker.sock:ro` - Communication avec Docker
  - `/mnt/docker-volumes/traefik` - Certificats SSL

**Entrypoints :**
- `web` (port 80) - HTTP
- `websecure` (port 443) - HTTPS
- `traefik` (port 8080) - Dashboard

**Labels Docker utilisés :**
```yaml
traefik.enable=true                          # Active Traefik pour ce service
traefik.http.routers.NAME.rule=Host(`...`)   # Règle de routage
traefik.http.routers.NAME.entrypoints=web    # Point d'entrée HTTP
traefik.http.services.NAME.loadbalancer.server.port=PORT  # Port du service
traefik.docker.network=traefik-net           # Réseau à utiliser
```

---

### 2. Portainer (Gestion Docker)

**Rôle :**
- Interface web de gestion des containers
- Visualisation des stacks, networks, volumes
- Gestion des images et des registries
- Logs et console des containers

**Configuration :**
- Image : `portainer/portainer-ce:latest`
- Réseaux : `traefik-net`
- Ports internes : 9000 (HTTP), 9443 (HTTPS)
- Volume : `/mnt/docker-volumes/portainer` - Base de données

**Accès :**
- Via Traefik : http://portainer.lab.local
- Direct : http://192.168.10.52:9000

---

### 3. Prometheus (Métriques)

**Rôle :**
- Base de données time-series pour les métriques
- Scraping des endpoints de métriques
- Évaluation des règles d'alerte
- Rétention des données (30 jours)

**Configuration :**
- Image : `prom/prometheus:latest`
- Réseaux : `traefik-net`, `monitoring`
- Port : 9090
- Volumes :
  - `/mnt/docker-volumes/prometheus/data` - Données métriques
  - `/mnt/docker-volumes/prometheus/config` - Configuration

**Targets configurées :**
1. **prometheus** (localhost:9090) - Self-monitoring
2. **node-exporter** (node-exporter:9100) - Métriques système
3. **cadvisor** (cadvisor:8080) - Métriques Docker

**Scrape interval :** 15 secondes
**Retention :** 30 jours

---

### 4. Node Exporter (Métriques Système)

**Rôle :**
- Export des métriques système de l'hôte
- Collecte CPU, RAM, disque, réseau, processus

**Configuration :**
- Image : `prom/node-exporter:latest`
- Réseau : `monitoring` (pas besoin de Traefik)
- Port : 9100
- Volumes :
  - `/proc:/host/proc:ro` - Informations processus
  - `/sys:/host/sys:ro` - Informations système
  - `/:/host:ro` - Root filesystem

**Métriques exposées :**
- `node_cpu_seconds_total` - Utilisation CPU
- `node_memory_*` - Utilisation mémoire
- `node_filesystem_*` - Espace disque
- `node_network_*` - Trafic réseau
- Et 100+ autres métriques

---

### 5. cAdvisor (Métriques Docker)

**Rôle :**
- Monitoring des containers Docker
- Métriques de ressources par container
- Statistiques CPU, RAM, réseau, I/O

**Configuration :**
- Image : `gcr.io/cadvisor/cadvisor:latest`
- Réseau : `monitoring`
- Port : 8080
- Mode : `privileged` (nécessaire pour accéder aux métriques)

**Métriques exposées :**
- `container_cpu_usage_seconds_total` - CPU par container
- `container_memory_usage_bytes` - RAM par container
- `container_network_*` - Réseau par container
- `container_fs_*` - I/O disque par container

---

### 6. Grafana (Visualisation)

**Rôle :**
- Dashboards de visualisation
- Requêtes PromQL vers Prometheus
- Alerting (à configurer)
- Gestion des datasources

**Configuration :**
- Image : `grafana/grafana:latest`
- Réseaux : `traefik-net`
- Port : 3000
- User : 472:472 (user système grafana)
- Volume : `/mnt/docker-volumes/grafana` - Base de données et configs

**Datasources :**
- Prometheus : `http://prometheus:9090`

**Dashboards importés :**
- Node Exporter Full (ID: 1860)

---

### 7. Whoami (Service de Test)

**Rôle :**
- Service de test pour valider le routage Traefik
- Affiche les headers HTTP reçus

**Configuration :**
- Image : `traefik/whoami`
- Réseau : `traefik-net`
- Port : 80

---

## Réseaux Docker

### traefik-net (172.18.0.0/16)

**Rôle :** Communication entre Traefik et les services exposés

**Containers connectés :**
- traefik
- portainer
- grafana
- prometheus
- whoami

**Type :** Bridge

---

### monitoring (172.19.0.0/16)

**Rôle :** Communication interne entre services de monitoring

**Containers connectés :**
- prometheus
- node-exporter
- cadvisor

**Type :** Bridge

**Avantage :** Isolation réseau, les services de collecte ne sont pas exposés via Traefik

---

## Volumes et Persistence

### Structure des volumes
```
/mnt/docker-volumes/
├── traefik/              # Certificats SSL (Let's Encrypt)
├── portainer/            # Base de données Portainer
│   └── portainer.db      # SQLite
├── grafana/              # Dashboards, datasources, users
│   ├── grafana.db        # SQLite
│   └── plugins/          # Plugins Grafana
├── prometheus/
│   ├── config/
│   │   └── prometheus.yml  # Configuration scraping
│   └── data/             # Time-series database (30j de rétention)
└── backups/              # Backups automatiques
    └── YYYYMMDD_HHMMSS/
```

### Permissions

- **Portainer** : `samadmin:samadmin` (1000:1000)
- **Grafana** : `472:472` (user système grafana)
- **Prometheus** : `root:root` (nécessaire pour mmap)
- **Traefik** : `samadmin:samadmin`

---

## Flux de Données

### 1. Flux HTTP (Utilisateur → Service)
```
Utilisateur (navigateur)
    ↓
    http://service.lab.local
    ↓
DNS local (dnsmasq ou /etc/hosts)
    ↓
    192.168.10.52:80
    ↓
Traefik (analyse Host header)
    ↓
Routing vers le bon container
    ↓
Service (portainer, grafana, etc.)
    ↓
Réponse HTTP
```

### 2. Flux de Métriques (Collecte)
```
Système (CPU, RAM, disque)
    ↓
Node Exporter (:9100/metrics)
    ↓
    ← Prometheus (scrape toutes les 15s)
    ↓
Stockage TSDB (rétention 30j)
    ↓
    ← Grafana (requêtes PromQL)
    ↓
Visualisation (dashboards)
```

### 3. Flux Docker Metrics
```
Docker Engine
    ↓
cAdvisor (lit /var/lib/docker/)
    ↓
Métriques par container (:8080/metrics)
    ↓
    ← Prometheus (scrape toutes les 15s)
    ↓
Stockage TSDB
    ↓
    ← Grafana
    ↓
Dashboard Docker
```

---

## Sécurité

### Implémenté

- ✅ Isolation réseau (réseaux dédiés)
- ✅ Volumes en read-only quand possible (`/var/run/docker.sock:ro`)
- ✅ Pas de ports sensibles exposés publiquement
- ✅ User non-root pour Grafana
- ✅ Restart policies (`unless-stopped`)

### À Implémenter

- ⏳ HTTPS avec Let's Encrypt
- ⏳ Authentification centralisée (OAuth2 Proxy)
- ⏳ Secrets Docker pour les mots de passe
- ⏳ Scanning de vulnérabilités (Trivy)
- ⏳ Firewall restrictif (UFW)

---

## Performances

### Ressources Utilisées (moyenne)

| Service | CPU | RAM | Disque |
|---------|-----|-----|--------|
| Traefik | <1% | 50 MB | 10 MB |
| Portainer | <1% | 30 MB | 50 MB |
| Grafana | 2-5% | 150 MB | 500 MB |
| Prometheus | 5-10% | 500 MB | 5-10 GB (30j) |
| Node Exporter | <1% | 20 MB | 5 MB |
| cAdvisor | 2-3% | 100 MB | 10 MB |

**Total :** ~1 GB RAM, ~10-15 GB disque

---

## Scalabilité

### Extensions Possibles

1. **Ajout de services** : Simplement créer un nouveau service avec les labels Traefik
2. **Multi-hôtes** : Déployer Prometheus sur plusieurs serveurs avec federation
3. **Alerting** : Ajouter Alertmanager pour les notifications
4. **Logging** : Stack ELK (Elasticsearch, Logstash, Kibana)
5. **Backup** : S3-compatible storage pour les backups distants

---

## Monitoring de la Stack

### Auto-monitoring

La stack se surveille elle-même :
- Prometheus collecte ses propres métriques
- Grafana affiche l'état de tous les services
- Traefik expose son dashboard pour le diagnostic

### Health Checks
```bash
# Vérifier tous les services
docker ps

# Vérifier les targets Prometheus
curl http://prometheus.lab.local/api/v1/targets

# Vérifier Traefik
curl http://192.168.10.52:8080/api/http/routers
```

---

## Conclusion

Cette architecture fournit :
- ✅ Infrastructure moderne et scalable
- ✅ Monitoring complet (système + applicatif)
- ✅ Gestion simplifiée des services
- ✅ Base solide pour extensions futures

**Documentation complète disponible dans les autres fichiers du repo.**
