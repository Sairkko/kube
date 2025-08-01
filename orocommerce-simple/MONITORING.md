# 📊 Monitoring OroCommerce avec Prometheus et Grafana

## 🎯 Vue d'ensemble

Cette configuration ajoute un stack de monitoring complet à votre installation OroCommerce avec :
- **Prometheus** : Collecte et stockage des métriques
- **Grafana** : Visualisation et dashboards

## 🚀 Installation

### Installation avec monitoring (recommandé)
```bash
helm install orocommerce-simple . -f values.yaml
```

### Installation sans monitoring
```bash
# Désactiver le monitoring dans values.yaml
prometheus:
  enabled: false
grafana:
  enabled: false

helm install orocommerce-simple . -f values.yaml
```

## 🌐 Accès aux interfaces

### Prometheus
- **URL** : `http://localhost:30909`
- **Fonction** : Interface de requêtes et exploration des métriques
- **Exemples de requêtes** :
  - `up` : État des services
  - `rate(nginx_http_requests_total[5m])` : Taux de requêtes Nginx
  - `php_fpm_processes_total` : Processus PHP-FPM

### Grafana
- **URL** : `http://localhost:30300`
- **Identifiants** : `admin` / `admin`
- **Fonction** : Dashboards et visualisations

## 📈 Métriques disponibles

### Métriques OroCommerce
- **PHP-FPM** : Processus, requêtes actives, temps de réponse
- **Nginx** : Requêtes HTTP, codes de statut, bande passante
- **PostgreSQL** : Connexions, requêtes, performance
- **Kubernetes** : État des pods, utilisation des ressources

### Dashboards pré-configurés
1. **OroCommerce Overview** : Vue d'ensemble des métriques principales
2. **PHP-FPM Status** : État des processus PHP
3. **Nginx Performance** : Performance du serveur web

## 🔧 Configuration

### Ajouter des métriques personnalisées

#### Pour PHP-FPM
Ajoutez dans votre application PHP :
```php
// Exposer les métriques PHP-FPM
if (isset($_GET['status']) && $_GET['status'] === 'json') {
    header('Content-Type: application/json');
    echo json_encode([
        'active_processes' => 10,
        'max_processes' => 50,
        'requests_per_second' => 25
    ]);
    exit;
}
```

#### Pour Nginx
Ajoutez dans la configuration Nginx :
```nginx
location /nginx_status {
    stub_status on;
    access_log off;
    allow 127.0.0.1;
    deny all;
}
```

### Personnaliser les dashboards Grafana

1. Connectez-vous à Grafana (`http://localhost:30300`)
2. Allez dans **Dashboards** > **New**
3. Créez vos propres visualisations
4. Sauvegardez le dashboard

## 🐛 Dépannage

### Prometheus ne collecte pas de métriques
```bash
# Vérifier l'état du pod Prometheus
kubectl get pods -l app=prometheus-orocommerce-simple

# Vérifier les logs
kubectl logs -l app=prometheus-orocommerce-simple

# Tester l'accès à Prometheus
kubectl port-forward svc/prometheus-orocommerce-simple 9090:9090
```

### Grafana ne se connecte pas à Prometheus
```bash
# Vérifier l'état du pod Grafana
kubectl get pods -l app=grafana-orocommerce-simple

# Vérifier les logs
kubectl logs -l app=grafana-orocommerce-simple

# Tester la connexion interne
kubectl exec -it $(kubectl get pods -l app=grafana-orocommerce-simple -o jsonpath='{.items[0].metadata.name}') -- curl http://prometheus-orocommerce-simple:9090/api/v1/status/config
```

### Métriques PHP-FPM non disponibles
```bash
# Vérifier que PHP-FPM expose les métriques
kubectl exec -it $(kubectl get pods -l app=php-fpm-orocommerce-simple -o jsonpath='{.items[0].metadata.name}') -- curl http://localhost:9000/status?format=json
```

## 📊 Exemples de requêtes Prometheus

### Performance OroCommerce
```promql
# Taux de requêtes par seconde
rate(nginx_http_requests_total[5m])

# Temps de réponse moyen
histogram_quantile(0.95, rate(nginx_http_request_duration_seconds_bucket[5m]))

# Erreurs 5xx
rate(nginx_http_requests_total{status=~"5.."}[5m])
```

### Ressources système
```promql
# Utilisation CPU
rate(container_cpu_usage_seconds_total{container="php-fpm"}[5m])

# Utilisation mémoire
container_memory_usage_bytes{container="php-fpm"}

# Espace disque
kubelet_volume_stats_used_bytes
```

## 🔒 Sécurité

### En production
1. **Changer les mots de passe par défaut**
2. **Configurer HTTPS**
3. **Restreindre l'accès réseau**
4. **Utiliser des secrets Kubernetes pour les credentials**

### Configuration sécurisée
```yaml
grafana:
  config:
    security:
      admin_user: admin
      admin_password: "{{ .Values.grafana.adminPassword }}"
    server:
      root_url: "https://grafana.votre-domaine.com/"
```

## 📝 Notes importantes

- **Ports utilisés** : 30909 (Prometheus), 30300 (Grafana)
- **Stockage** : Les données sont persistantes par défaut
- **Ressources** : Monitoring léger, impact minimal sur les performances
- **Compatibilité** : Fonctionne avec toutes les versions d'OroCommerce

---

**🎉 Monitoring configuré ! Accédez à Prometheus et Grafana pour surveiller votre application.** 