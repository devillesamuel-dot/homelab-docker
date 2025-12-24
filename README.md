# 🏠 Homelab Infrastructure - Production-Ready Docker Stack

> Infrastructure de monitoring, sécurité et reverse proxy déployée sur Ubuntu Server 24.04 LTS

[![Docker](https://img.shields.io/badge/Docker-24.0+-blue.svg)](https://www.docker.com/)
[![Ubuntu](https://img.shields.io/badge/Ubuntu-24.04_LTS-orange.svg)](https://ubuntu.com/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

## 🎯 Vue d'ensemble

Stack Docker complète démontrant des compétences en :
- **Administration systèmes Linux** (Ubuntu Server)
- **Conteneurisation** (Docker, Docker Compose)  
- **Monitoring** (Prometheus, Grafana)
- **Cybersécurité** (CrowdSec IDS/IPS)
- **Automatisation** (Backups, Scripts Bash)

## 🏗️ Architecture
```
Internet/LAN
     │
     ▼
┌─────────────┐
│   Traefik   │ ← Reverse Proxy + CrowdSec Bouncer
│  (Port 80)  │   
└──────┬──────┘
       │
   ┌───┴────┬────────┬─────────┐
   ▼        ▼        ▼         ▼
┌────────┐ ┌────┐ ┌────────┐ ┌─────────┐
│Grafana │ │Prom│ │Portainer│ │CrowdSec │
└────────┘ └────┘ └────────┘ └─────────┘
```

## 📊 Services Déployés

| Service | Description | URL | Status |
|---------|-------------|-----|--------|
| **Traefik** | Reverse proxy & dashboard | `traefik.lab.local` | ✅ |
| **Grafana** | Monitoring dashboards | `grafana.lab.local` | ✅ |
| **Prometheus** | Metrics collection | `prometheus.lab.local` | ✅ |
| **Portainer** | Docker management | `portainer.lab.local` | ✅ |
| **CrowdSec** | IDS/IPS security | `crowdsec.lab.local` | ✅ |
| **Node Exporter** | System metrics | - | ✅ |
| **cAdvisor** | Container metrics | - | ✅ |

## 🔒 Sécurité CrowdSec

### Statistiques en temps réel
- **16 690+ IPs bannies** via Cyber Threat Intelligence
- **Protection active** contre SSH brute-force, HTTP exploits, port scanning
- **Intégration Traefik** pour blocage automatique

### Top menaces détectées
```
http:scan        : 6 387 décisions
ssh:bruteforce   : 4 471 décisions  
http:crawl       : 1 725 décisions
http:exploit     :   935 décisions
```

## 🚀 Quick Start

### Prérequis
```bash
# Ubuntu Server 24.04 LTS
sudo apt update && sudo apt install -y docker.io docker-compose git
```

### Déploiement
```bash
git clone https://github.com/TON-USERNAME/homelab-docker.git
cd homelab-docker

# Créer les réseaux
docker network create traefik-net
docker network create monitoring  
docker network create crowdsec-net

# Déployer les services
cd docker-compose/traefik && docker compose up -d
cd ../monitoring && docker compose up -d
cd ../crowdsec && docker compose up -d
```

## 📚 Documentation

- [📦 Installation complète](docs/INSTALLATION.md)
- [🔧 Configuration Traefik](docs/TRAEFIK.md)
- [🛡️ Setup CrowdSec](docs/CROWDSEC.md)
- [📊 Monitoring Grafana](docs/MONITORING.md)
- [💾 Stratégie Backup](docs/BACKUPS.md)
- [🔍 Troubleshooting](docs/TROUBLESHOOTING.md)

## 💾 Backups Automatisés

- **Quotidien** : Configurations (3h) → Rétention 7 jours
- **Hebdomadaire** : Données complètes (Dimanche 4h) → Rétention 3 semaines
- **Stockage** : Disque USB 3TB

## 🎓 Compétences Démontrées

### 🐧 Linux & Systèmes
- Administration Ubuntu Server 24.04 LTS
- Configuration réseau & DNS local
- Scripting Bash & automatisation cron
- Gestion des permissions & sécurité

### 🐳 Conteneurisation
- Docker & Docker Compose avancé
- Gestion multi-réseaux Docker
- Volumes & persistance données
- Orchestration multi-containers

### 📊 Monitoring & Observabilité
- Prometheus (scraping, PromQL)
- Grafana (dashboards, alerting)
- Métriques système (Node Exporter)
- Métriques containers (cAdvisor)

### 🔐 Cybersécurité
- IDS/IPS (CrowdSec)
- Cyber Threat Intelligence (CTI)
- Log analysis & pattern detection
- Automated incident response
- Traefik bouncer integration

### ⚙️ DevOps
- Infrastructure as Code
- GitOps workflow
- Automated backups & DR
- Documentation technique

## 📸 Screenshots

### Dashboard Grafana
![Grafana Dashboard](screenshots/grafana-dashboard.png)

### CrowdSec Security
![CrowdSec Metrics](screenshots/crowdsec-metrics.png)

### Traefik Routing
![Traefik Dashboard](screenshots/traefik-dashboard.png)

## 🛠️ Structure du Projet
```
homelab-docker/
├── docker-compose/         # Docker Compose files
│   ├── monitoring/        # Prometheus, Grafana, exporters
│   ├── traefik/           # Reverse proxy
│   ├── crowdsec/          # Security stack
│   └── portainer/         # Docker management
├── docs/                  # Documentation détaillée
├── scripts/               # Scripts d'automatisation
├── screenshots/           # Captures d'écran
└── README.md             # Ce fichier
```

## 📞 Contact

**Samuel** - Administrateur Systèmes & Réseaux  
🎯 Recherche poste : Admin Sys/Réseau, Support N2/N3, Cybersécurité  
📍 Auvergne-Rhône-Alpes, France  
🔗 LinkedIn : [Votre profil]  
📧 Email : [Votre email]

## 📄 Licence

MIT License - Libre d'utilisation pour apprentissage et référence.

---

⭐ **Si ce projet vous inspire, n'hésitez pas à le star !**
