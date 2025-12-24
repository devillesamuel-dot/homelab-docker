# 📊 Monitoring avec Grafana & Prometheus

## Stack de monitoring
```
┌─────────────┐
│   Grafana   │ ← Visualisation & Dashboards
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ Prometheus  │ ← Collecte des métriques
└──────┬──────┘
       │
   ┌───┴────┬─────────┬──────────┐
   ▼        ▼         ▼          ▼
┌────┐  ┌────────┐ ┌────────┐ ┌────────┐
│Node│  │cAdvisor│ │CrowdSec│ │ ... │
│Exp │  │        │ │        │ │     │
└────┘  └────────┘ └────────┘ └────────┘
```

## Prometheus

### Configuration

Fichier : `/mnt/docker-volumes/prometheus/config/prometheus.yml`
```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'node-exporter'
    static_configs:
      - targets: ['node-exporter:9100']

  - job_name: 'cadvisor'
    static_configs:
      - targets: ['cadvisor:8080']

  - job_name: 'crowdsec'
    static_configs:
      - targets: ['crowdsec:6060']
```

### Ajout d'une nouvelle source
```yaml
  - job_name: 'mon-service'
    static_configs:
      - targets: ['mon-service:9090']
```

Puis recharge Prometheus :
```bash
# Sans redémarrage
docker exec prometheus kill -HUP 1

# Ou redémarre
docker restart prometheus
```

### Vérifier les targets

Accède à : `http://prometheus.lab.local/targets`

Toutes les targets doivent être **UP** (vertes).

## Grafana

### Accès

URL : `http://grafana.lab.local`  
Login par défaut : `admin` / `admin`

### Configuration initiale

1. **Ajoute Prometheus comme data source** :
   - Configuration → Data Sources → Add data source
   - Type : **Prometheus**
   - URL : `http://prometheus:9090`
   - Save & Test

2. **Importe des dashboards** :
   - Dashboards → Import
   - Dashboard IDs populaires :
     - **1860** : Node Exporter Full
     - **193** : Docker monitoring
     - **15835** : CrowdSec Prometheus

### Création d'un dashboard custom

1. Dashboards → New → New Dashboard
2. Add visualization
3. Data source : Prometheus
4. Query examples :
```promql
# CPU usage
100 - (avg(irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# Memory usage
(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100

# Disk usage
100 - ((node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"}) * 100)

# CrowdSec decisions
cs_active_decisions

# Container CPU
rate(container_cpu_usage_seconds_total[5m])
```

## Node Exporter

Collecte les métriques système :
- CPU, RAM, Disk, Network
- Processus, Load average
- Filesystem

Port : 9100 (pas d'interface web)

## cAdvisor

Collecte les métriques des containers Docker :
- CPU et mémoire par container
- I/O réseau et disque
- Statistiques d'utilisation

Port : 8080 (interface web disponible)

## Alerting Grafana

### Créer une alerte

1. Edit un panel
2. Alert tab
3. Create alert rule
4. Définir les conditions :
```
WHEN avg() OF query(A, 5m, now)
IS ABOVE 80
```

### Notification channels

Configuration → Alerting → Contact points

Exemples :
- Email
- Slack
- Discord
- Webhook

## Dashboards recommandés

### Dashboard CrowdSec

Panels utiles :

**Total IPs bannies**
```promql
sum(cs_active_decisions)
```

**Top 5 scénarios**
```promql
topk(5, cs_active_decisions)
```

**Décisions par origine**
```promql
cs_active_decisions{origin="CAPI"}
cs_active_decisions{origin="cscli"}
```

**Taux d'alertes**
```promql
rate(cs_alerts[5m])
```

### Dashboard Infrastructure

**CPU par core**
```promql
100 - (avg by (cpu) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)
```

**Network traffic**
```promql
rate(node_network_receive_bytes_total[5m])
rate(node_network_transmit_bytes_total[5m])
```

**Top containers CPU**
```promql
topk(5, rate(container_cpu_usage_seconds_total[5m]))
```

## Maintenance

### Backup Grafana
```bash
# Backup des dashboards et configs
docker exec grafana backup

# Ou backup du volume
sudo tar -czf grafana-backup.tar.gz /mnt/docker-volumes/grafana/
```

### Rétention Prometheus

Configuration dans `prometheus.yml` :
```yaml
storage:
  tsdb:
    retention.time: 30d
    retention.size: 10GB
```

## Ressources

- [Prometheus Docs](https://prometheus.io/docs/)
- [Grafana Docs](https://grafana.com/docs/grafana/latest/)
- [PromQL Cheat Sheet](https://promlabs.com/promql-cheat-sheet/)
