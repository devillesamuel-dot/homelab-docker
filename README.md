
# 🏠 Homelab Docker - Infrastructure de Monitoring

Infrastructure complète de monitoring et de gestion de containers basée sur Docker, Traefik, Prometheus et Grafana.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

---

## 🎯 Objectifs du Projet

- Déployer une stack de monitoring moderne et scalable
- Automatiser le déploiement avec Docker Compose et Infrastructure as Code
- Apprendre les pratiques DevOps/InfraOps
- Créer un environnement de lab pour tester de nouvelles technologies
- Documenter les solutions aux problèmes courants

---

## 🏗️ Architecture
```
┌─────────────────────────────────────────────┐
│           TRAEFIK (Reverse Proxy)           │
│    Auto-discovery • SSL • Load Balancing    │
│         Port 80, 443, 8080 (dashboard)      │
└──────────┬──────────┬───────────┬───────────┘
           │          │           │
           ▼          ▼           ▼
    ┌──────────┐  ┌──────────┐  ┌──────────┐
    │ Portainer│  │ Grafana  │  │  Whoami  │
    │  :9000   │  │  :3000   │  │   :80    │
    └──────────┘  └─────┬────┘  └──────────┘
                        │
                        ▼
                  ┌──────────┐
                  │Prometheus│
                  │  :9090   │
                  └────┬─────┘
                       │
           ┌───────────┴───────────┐
           ▼                       ▼
    ┌──────────┐          ┌──────────┐
    │   Node   │          │ cAdvisor │
    │ Exporter │          │  :8080   │
    │  :9100   │          │          │
    └──────────┘          └──────────┘
```

---

## 🛠️ Stack Technique

### Infrastructure
- **OS** : Ubuntu Server 24.04 LTS
- **Containerisation** : Docker 27.x + Docker Compose v2
- **Stockage** : 512 Go SSD (système) + 3 To HDD USB (données)
- **RAM** : 32 Go
- **CPU** : 6 cores

### Services Déployés

| Service | Version | Description | Port |
|---------|---------|-------------|------|
| **Traefik** | v3.2 | Reverse proxy moderne avec service discovery automatique | 80, 443, 8080 |
| **Portainer** | CE latest | Interface web de gestion des containers Docker | 9000, 9443 |
| **Prometheus** | latest | Base de données time-series pour les métriques | 9090 |
| **Grafana** | latest | Plateforme de visualisation et dashboards | 3000 |
| **Node Exporter** | latest | Export des métriques système (CPU, RAM, disque, réseau) | 9100 |
| **cAdvisor** | latest | Monitoring des containers Docker | 8080 |

### Réseau
- **DNS local** : dnsmasq (résolution automatique `*.lab.local`)
- **Réseaux Docker** : 
  - `traefik-net` (172.18.0.0/16) - Communication avec Traefik
  - `monitoring` (172.19.0.0/16) - Communication interne monitoring

---

## 🌐 Services Accessibles

| Service | URL | Credentials | Description |
|---------|-----|-------------|-------------|
| Traefik Dashboard | http://192.168.10.52:8080 | - | Visualisation des routes et services |
| Portainer | http://portainer.lab.local | admin/[password] | Gestion des containers |
| Grafana | http://grafana.lab.local | admin/admin | Dashboards de monitoring |
| Prometheus | http://prometheus.lab.local | - | Métriques et targets |
| Whoami | http://whoami.lab.local | - | Service de test |

---

## 🚀 Démarrage Rapide

### Prérequis

- Ubuntu Server 24.04 LTS (ou compatible)
- Docker Engine 20.10+ et Docker Compose v2+
- 4 Go RAM minimum (8 Go recommandé)
- 50 Go d'espace disque minimum
- Accès sudo

### Installation

#### 1. Cloner le repository
```bash
git clone https://gitlab.com/samuel-deville/homelab-docker.git
cd homelab-docker
```

#### 2. Créer les réseaux Docker
```bash
docker network create traefik-net
docker network create monitoring
```

#### 3. Créer les volumes
```bash
sudo mkdir -p /mnt/docker-volumes/{traefik,portainer,grafana,prometheus/{config,data}}
sudo chown -R $USER:$USER /mnt/docker-volumes/
sudo chown -R 472:472 /mnt/docker-volumes/grafana/
```

#### 4. Copier la config Prometheus
```bash
cp monitoring/prometheus.yml /mnt/docker-volumes/prometheus/config/
```

#### 5. Déployer Traefik + services
```bash
cd traefik
docker compose up -d
```

#### 6. Déployer la stack de monitoring
```bash
cd ../monitoring
docker compose up -d
```

#### 7. Vérifier le déploiement
```bash
docker ps
```

Tous les containers doivent afficher le statut `Up`.

---

## 📸 Captures d'écran

### Dashboard Grafana - Node Exporter Full
Monitoring en temps réel du serveur (CPU, RAM, disque, réseau)

*[Screenshot à ajouter]*

### Traefik Dashboard
Vue d'ensemble des routes HTTP et des services

*[Screenshot à ajouter]*

### Prometheus Targets
État des targets de collecte de métriques

*[Screenshot à ajouter]*

---

## 📚 Documentation Complète

- [📖 Guide d'installation détaillé](docs/installation.md)
- [🏗️ Architecture technique](docs/architecture.md)
- [🔧 Troubleshooting](docs/troubleshooting.md)

---

## 🎓 Compétences Démontrées

### DevOps & Infrastructure
- ✅ Infrastructure as Code (Docker Compose)
- ✅ Containerisation et orchestration
- ✅ Reverse proxy et service discovery automatique
- ✅ Configuration de réseaux Docker avancés
- ✅ Gestion de volumes persistants

### Monitoring & Observability
- ✅ Déploiement de stack Prometheus + Grafana
- ✅ Configuration de collecteurs de métriques
- ✅ Création et import de dashboards
- ✅ Monitoring système et applicatif

### Linux System Administration
- ✅ Installation et configuration Ubuntu Server
- ✅ Gestion des services systemd
- ✅ Configuration réseau et DNS
- ✅ Gestion des permissions et sécurité

### Troubleshooting
- ✅ Debugging de problèmes réseau Docker
- ✅ Résolution de conflits de ports
- ✅ Correction de problèmes de permissions
- ✅ Analyse de logs et diagnostic

---

## �� Sécurité

### Bonnes Pratiques Implémentées
- Isolation réseau avec réseaux Docker dédiés
- Volumes montés en read-only quand possible
- Pas de ports sensibles exposés publiquement
- Gestion des secrets via Docker secrets (à implémenter)

### Améliorations Futures
- [ ] Mise en place de HTTPS avec Let's Encrypt
- [ ] Authentification centralisée (OAuth2)
- [ ] Scanning de vulnérabilités des images
- [ ] Backups automatiques chiffrés

---

## 🔄 Maintenance

### Backups Automatiques

Un script de backup est disponible dans `scripts/backup.sh` :
```bash
# Exécuter un backup manuel
./scripts/backup.sh

# Configurer un backup quotidien (cron)
0 2 * * * /chemin/vers/homelab-docker/scripts/backup.sh
```

### Mises à Jour
```bash
# Mettre à jour les images Docker
cd traefik && docker compose pull && docker compose up -d
cd ../monitoring && docker compose pull && docker compose up -d
```

---

## 🤝 Contribution

Les contributions sont les bienvenues ! N'hésitez pas à :
- Ouvrir une issue pour signaler un bug
- Proposer des améliorations
- Soumettre une pull request

---

## 📄 Licence

Ce projet est sous licence MIT - voir le fichier [LICENSE](LICENSE) pour plus de détails.

---

## 👤 Auteur

**Samuel Deville**
- 15 ans d'expérience en infrastructure IT
- Spécialités : Systèmes critiques, DevOps, Monitoring
- LinkedIn : [samuel-deville](https://linkedin.com/in/samuel-deville)
- GitLab : [@samuel-deville](https://gitlab.com/samuel-deville)

---

## 📞 Contact

Pour toute question ou suggestion : [samuel.deville@example.com](mailto:samuel.deville@example.com)

---

**⭐ Si ce projet vous a été utile, n'hésitez pas à lui donner une étoile !**
