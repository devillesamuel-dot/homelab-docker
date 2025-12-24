# 🔧 Configuration Traefik

## Vue d'ensemble

Traefik est un reverse proxy moderne qui découvre automatiquement les services Docker et les expose via des règles de routage configurables.

## Architecture
```
Internet/LAN (Port 80)
        ↓
   [Traefik]
        ↓
   Auto-discovery (labels Docker)
        ↓
   ┌────┬────┬────┬────┐
   │    │    │    │    │
   ▼    ▼    ▼    ▼    ▼
  Svc1 Svc2 Svc3 Svc4 ...
```

## Configuration

### Docker Compose

Le fichier `docker-compose.yml` de Traefik :
```yaml
services:
  traefik:
    image: traefik:latest
    container_name: traefik
    restart: unless-stopped
    security_opt:
      - no-new-privileges:true
    networks:
      - traefik-net
      - crowdsec-net
    ports:
      - "80:80"
      - "8080:8080"  # Dashboard
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - /mnt/docker-volumes/traefik:/etc/traefik
    command:
      - "--api.insecure=true"
      - "--api.dashboard=true"
      - "--providers.docker=true"
      - "--providers.docker.exposedbydefault=false"
      - "--providers.docker.network=traefik-net"
      - "--entrypoints.web.address=:80"
      - "--log.level=INFO"
      - "--accesslog=true"
      - "--accesslog.filepath=/etc/traefik/access.log"
      - "--providers.file.directory=/etc/traefik/dynamic"
      - "--providers.file.watch=true"
      # Plugin CrowdSec
      - "--experimental.plugins.bouncer.modulename=github.com/maxlerebourg/crowdsec-bouncer-traefik-plugin"
      - "--experimental.plugins.bouncer.version=v1.3.5"
```

## Exposition d'un service

Pour exposer un service Docker via Traefik, ajoute ces labels :
```yaml
services:
  mon-service:
    image: mon-image:latest
    labels:
      - "traefik.enable=true"
      - "traefik.docker.network=traefik-net"
      - "traefik.http.routers.mon-service.rule=Host(`mon-service.lab.local`)"
      - "traefik.http.routers.mon-service.entrypoints=web"
      - "traefik.http.services.mon-service.loadbalancer.server.port=8080"
      # Protection CrowdSec (optionnel)
      - "traefik.http.routers.mon-service.middlewares=crowdsec-bouncer@file"
    networks:
      - traefik-net
```

## Configuration dynamique

Le dossier `/etc/traefik/dynamic/` contient les configurations chargées à chaud.

### Exemple : Middleware CrowdSec

Fichier : `/mnt/docker-volumes/traefik/dynamic/crowdsec.yml`
```yaml
http:
  middlewares:
    crowdsec-bouncer:
      plugin:
        bouncer:
          enabled: true
          logLevel: INFO
          crowdsecMode: live
          crowdsecLapiKey: YOUR_API_KEY_HERE
          crowdsecLapiHost: crowdsec:8080
          crowdsecLapiScheme: http
```

## Dashboard Traefik

Le dashboard est accessible sur : `http://IP_SERVEUR:8080/dashboard/`

Il affiche :
- Les routers actifs
- Les services découverts
- Les middlewares appliqués
- Les entrypoints configurés

## Commandes utiles
```bash
# Voir les logs Traefik
docker logs traefik -f

# Recharger la configuration
docker restart traefik

# Vérifier les routes actives
curl http://localhost:8080/api/http/routers | jq

# Tester un service
curl -H "Host: mon-service.lab.local" http://localhost
```

## Troubleshooting

### Service non accessible
```bash
# 1. Vérifier que le container est dans traefik-net
docker inspect mon-service | grep -A 5 Networks

# 2. Vérifier les labels
docker inspect mon-service | grep -A 10 Labels

# 3. Vérifier les logs Traefik
docker logs traefik | grep mon-service
```

### Dashboard inaccessible
```bash
# Vérifier que le port 8080 est exposé
docker ps | grep traefik

# Tester localement
curl http://localhost:8080/api/overview
```

## Sécurité

### Production

Pour la production, désactive le dashboard insecure :
```yaml
command:
  - "--api.dashboard=true"
  # - "--api.insecure=true"  # ← Retire cette ligne
```

Et configure un authentification :
```yaml
labels:
  - "traefik.http.routers.api.middlewares=auth"
  - "traefik.http.middlewares.auth.basicauth.users=admin:$$apr1$$..."
```

## Ressources

- [Documentation Traefik](https://doc.traefik.io/traefik/)
- [Plugin CrowdSec](https://plugins.traefik.io/plugins/6335346ca4caa9ddeffda116/crowdsec-bouncer-traefik-plugin)
