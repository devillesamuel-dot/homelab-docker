# 🛡️ CrowdSec - Configuration et Utilisation

## Vue d'ensemble

CrowdSec est un système de détection et de prévention d'intrusions (IDS/IPS) collaboratif qui protège l'infrastructure contre les attaques malveillantes.

## Architecture
```
┌─────────────┐
│   Traefik   │ → Génère access.log
└──────┬──────┘
       │
       ▼
┌─────────────┐
│  CrowdSec   │ → Analyse les logs
│   Engine    │   Détecte les patterns
└──────┬──────┘
       │
       ├─→ Local API (LAPI) → Décisions de ban
       │
       └─→ Community API (CAPI) → Partage threat intelligence
              ↓
       ┌─────────────┐
       │   Bouncer   │ → Bloque les IPs bannies
       │  (Traefik)  │
       └─────────────┘
```

## Installation

### 1. Déploiement du container
```bash
cd docker-compose/crowdsec
docker compose up -d
```

### 2. Configuration de l'acquisition

Le fichier `/etc/crowdsec/acquis.yaml` définit les logs à analyser :
```yaml
---
# Logs système
source: file
filenames:
  - /var/log/auth.log
  - /var/log/syslog
labels:
  type: syslog
---
# Logs Traefik
source: file
filenames:
  - /var/log/traefik/access.log
labels:
  type: traefik
```

### 3. Création du bouncer Traefik
```bash
# Génère une clé API pour le bouncer
docker exec -it crowdsec cscli bouncers add traefik-bouncer

# Note la clé générée (ex: iKfSivZrTN6Us7GCopETB4dTT476yUpYbF/4gKN4bTE)

# Configure le bouncer dans Traefik (voir docs/TRAEFIK.md)
```

## Collections et Scénarios

### Collections installées
```bash
docker exec crowdsec cscli collections list
```

- `crowdsecurity/linux` : Protection système Linux
- `crowdsecurity/traefik` : Protection Traefik
- `crowdsecurity/http-cve` : CVEs HTTP connues

### Scénarios actifs
```bash
docker exec crowdsec cscli scenarios list
```

Scénarios de détection :
- `ssh:bruteforce` : Détection brute-force SSH
- `http:scan` : Détection de scans HTTP
- `http:crawl` : Détection crawlers malveillants
- `http:exploit` : Tentatives d'exploitation
- `http:bruteforce` : Brute-force HTTP

## Commandes utiles

### Voir les alertes
```bash
docker exec crowdsec cscli alerts list
```

### Voir les décisions (bans)
```bash
docker exec crowdsec cscli decisions list
```

### Métriques
```bash
docker exec crowdsec cscli metrics
```

### Débannir une IP
```bash
docker exec crowdsec cscli decisions delete --ip 192.168.1.100
```

### Bannir manuellement une IP
```bash
docker exec crowdsec cscli decisions add --ip 1.2.3.4 --duration 24h --reason "Manual ban"
```

## Whitelist réseau local

Pour éviter de bannir ton propre réseau :
```bash
docker exec -it crowdsec sh

cat > /etc/crowdsec/parsers/s02-enrich/mywhitelist.yaml << 'YAML'
name: crowdsecurity/mywhitelist
description: "Whitelist réseau local"
whitelist:
  reason: "Réseau local de confiance"
  cidr:
    - "192.168.0.0/16"
    - "10.0.0.0/8"
YAML

exit
docker restart crowdsec
```

## Intégration Prometheus

CrowdSec expose ses métriques sur le port 6060.

Configuration Prometheus (`prometheus.yml`) :
```yaml
scrape_configs:
  - job_name: 'crowdsec'
    static_configs:
      - targets: ['crowdsec:6060']
```

Métriques disponibles :
- `cs_active_decisions` : Décisions actives par type
- `cs_alerts` : Nombre d'alertes
- `cs_parser_hits_total` : Logs parsés
- `cs_lapi_bouncer_requests_total` : Requêtes des bouncers

## Statistiques actuelles

Au moment de la documentation :
```
Total IPs bannies : 16 690+
Top scénarios :
  - http:scan        : 6 387
  - ssh:bruteforce   : 4 471
  - http:crawl       : 1 725
  - http:exploit     :   935
  - generic:scan     : 1 055
```

## Intégration avec Traefik

### Configuration du bouncer

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
          crowdsecCapiMachineId: ""
          crowdsecCapiPassword: ""
          crowdsecCapiScenarios:
            - crowdsecurity/http-path-traversal-probing
            - crowdsecurity/http-xss-probing
            - crowdsecurity/http-generic-bf
```

### Application du middleware

Dans les labels Docker d'un service :
```yaml
labels:
  - "traefik.http.routers.mon-service.middlewares=crowdsec-bouncer@file"
```

## Dashboard Grafana

### Création du dashboard CrowdSec

1. **Importe un dashboard existant** :
   - ID : 15835 (CrowdSec Prometheus)
   
2. **Ou crée des panels custom** :

**Panel "Total IPs bannies"** :
```promql
sum(cs_active_decisions)
```

**Panel "Top Scénarios"** :
```promql
cs_active_decisions
```

**Panel "Décisions par origine"** :
```promql
sum(cs_active_decisions) by (origin)
```

**Panel "Taux d'alertes"** :
```promql
rate(cs_alerts[5m])
```

## Troubleshooting

### CrowdSec ne détecte rien
```bash
# Vérifie l'acquisition
docker exec crowdsec cat /etc/crowdsec/acquis.yaml

# Vérifie les logs parsés
docker exec crowdsec cscli metrics

# Vérifie les scénarios
docker exec crowdsec cscli scenarios list
```

### Bouncer ne bloque pas
```bash
# Vérifie le bouncer
docker exec crowdsec cscli bouncers list

# Vérifie les décisions
docker exec crowdsec cscli decisions list

# Test manuel
curl -I http://ton-service.lab.local
```

### Logs non analysés
```bash
# Vérifie que les logs sont accessibles
docker exec crowdsec ls -la /var/log/traefik/

# Vérifie les permissions
docker exec crowdsec cat /var/log/traefik/access.log

# Redémarre CrowdSec
docker restart crowdsec
```

## Maintenance

### Mise à jour des collections
```bash
# Update hub
docker exec crowdsec cscli hub update

# Upgrade collections
docker exec crowdsec cscli collections upgrade --all
```

### Nettoyage des décisions expirées

Les décisions expirent automatiquement selon leur durée configurée.

Pour forcer le nettoyage :
```bash
docker exec crowdsec cscli decisions delete --all
```

## Ressources

- [Documentation CrowdSec](https://docs.crowdsec.net/)
- [Hub CrowdSec](https://hub.crowdsec.net/)
- [Community](https://discourse.crowdsec.net/)
- [Plugin Traefik](https://plugins.traefik.io/plugins/6335346ca4caa9ddeffda116/crowdsec-bouncer-traefik-plugin)

## Évolutions possibles

- [ ] Ajout du bouncer firewall (protection SSH niveau système)
- [ ] Notifications Slack/Discord pour les alertes critiques
- [ ] Intégration avec un SIEM externe
- [ ] Règles personnalisées pour des attaques spécifiques
- [ ] Tests d'intrusion automatisés pour valider la détection
