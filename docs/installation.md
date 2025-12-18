# 📖 Guide d'Installation Détaillé

## Prérequis

### Matériel
- Serveur/VM avec au minimum :
  - 4 Go RAM (8 Go recommandé)
  - 2 CPU cores (4 recommandé)
  - 50 Go d'espace disque (100 Go recommandé)
  - Connexion réseau

### Logiciels
- Ubuntu Server 24.04 LTS (ou compatible Debian)
- Accès sudo
- Connexion internet

---

## Installation Pas à Pas

### 1. Mise à jour du système
```bash
sudo apt update && sudo apt upgrade -y
```

### 2. Installation de Docker
```bash
# Installer les dépendances
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common

# Ajouter la clé GPG officielle de Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Ajouter le repository Docker
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Installer Docker
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Ajouter l'utilisateur au groupe docker
sudo usermod -aG docker $USER

# Vérifier l'installation
docker --version
docker compose version
```

**Déconnectez-vous et reconnectez-vous pour que les changements prennent effet.**

### 3. Cloner le repository
```bash
cd ~
git clone https://gitlab.com/samuel-deville/homelab-docker.git
cd homelab-docker
```

### 4. Créer les réseaux Docker
```bash
docker network create traefik-net
docker network create monitoring
```

### 5. Créer la structure des volumes
```bash
# Créer les dossiers
sudo mkdir -p /mnt/docker-volumes/{traefik,portainer,grafana,prometheus/{config,data}}

# Donner les permissions
sudo chown -R $USER:$USER /mnt/docker-volumes/

# Permissions spécifiques pour Grafana
sudo chown -R 472:472 /mnt/docker-volumes/grafana/
```

### 6. Copier la configuration Prometheus
```bash
cp monitoring/prometheus.yml /mnt/docker-volumes/prometheus/config/
```

### 7. Déployer Traefik et les services
```bash
cd traefik
docker compose up -d
```

**Vérifier :**
```bash
docker compose ps
```

Tous les services doivent afficher `Up`.

### 8. Déployer la stack de monitoring
```bash
cd ../monitoring
docker compose up -d
```

**Vérifier :**
```bash
docker compose ps
```

### 9. Vérifier le déploiement complet
```bash
docker ps
```

Vous devriez voir 7 containers :
- traefik
- portainer
- grafana
- whoami
- prometheus
- node-exporter
- cadvisor

### 10. Configuration DNS (optionnel)

#### Option A : Fichier /etc/hosts (simple)

Sur votre machine cliente :
```bash
sudo nano /etc/hosts
```

Ajouter :
```
192.168.10.52  portainer.lab.local grafana.lab.local prometheus.lab.local whoami.lab.local
```

#### Option B : dnsmasq (automatique)

Installation sur Ubuntu Desktop :
```bash
sudo apt install dnsmasq
sudo nano /etc/dnsmasq.d/lab-local.conf
```

Ajouter :
```
address=/lab.local/192.168.10.52
```

Redémarrer :
```bash
sudo systemctl restart dnsmasq
```

---

## Configuration Post-Installation

### Portainer

1. Accéder à http://portainer.lab.local
2. Créer un compte administrateur
3. Connecter l'environnement Docker local

### Grafana

1. Accéder à http://grafana.lab.local
2. Login : `admin` / `admin`
3. Changer le mot de passe

**Ajouter Prometheus comme datasource :**
- Menu → Connections → Data sources → Add data source
- Choisir Prometheus
- URL : `http://prometheus:9090`
- Save & Test

**Importer le dashboard Node Exporter :**
- Menu → Dashboards → Import
- ID : `1860`
- Sélectionner la datasource Prometheus
- Import

### Prometheus

Accéder à http://prometheus.lab.local/targets

Vérifier que les 3 targets sont UP :
- prometheus
- node-exporter
- cadvisor

---

## Démarrage Automatique au Boot

Pour que les stacks démarrent automatiquement au boot du serveur :

### Créer le service Traefik
```bash
sudo nano /etc/systemd/system/docker-traefik.service
```

Contenu :
```ini
[Unit]
Description=Docker Compose Traefik Stack
Requires=docker.service
After=docker.service network-online.target
Wants=network-online.target

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/home/VOTRE_USER/homelab-docker/traefik
ExecStart=/usr/bin/docker compose up -d
ExecStop=/usr/bin/docker compose down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
```

### Créer le service Monitoring
```bash
sudo nano /etc/systemd/system/docker-monitoring.service
```

Contenu :
```ini
[Unit]
Description=Docker Compose Monitoring Stack
Requires=docker.service
After=docker.service docker-traefik.service network-online.target
Wants=network-online.target

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/home/VOTRE_USER/homelab-docker/monitoring
ExecStart=/usr/bin/docker compose up -d
ExecStop=/usr/bin/docker compose down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
```

### Activer les services
```bash
sudo systemctl daemon-reload
sudo systemctl enable docker-traefik.service
sudo systemctl enable docker-monitoring.service
```

---

## Vérification Finale

### Services Web

Accéder aux URLs suivantes depuis votre navigateur :

- Traefik Dashboard : http://192.168.10.52:8080
- Portainer : http://portainer.lab.local
- Grafana : http://grafana.lab.local
- Prometheus : http://prometheus.lab.local
- Whoami : http://whoami.lab.local

### Logs

Vérifier les logs si besoin :
```bash
# Traefik
cd ~/homelab-docker/traefik
docker compose logs -f traefik

# Prometheus
cd ~/homelab-docker/monitoring
docker compose logs -f prometheus
```

---

## Prochaines Étapes

- [ ] Configurer des alertes dans Grafana
- [ ] Mettre en place HTTPS avec Let's Encrypt
- [ ] Configurer des backups automatiques
- [ ] Ajouter d'autres services (Nextcloud, GitLab, etc.)

---

**Installation terminée ! 🎉**
