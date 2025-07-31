# 🚀 Installation OroCommerce - Guide Complet

## 📋 Prérequis

- Kubernetes cluster (Docker Desktop, Minikube, etc.)
- Helm 3.x installé
- kubectl configuré

## 🎯 Installation en une commande

### 1. Installation complète
```bash
helm install orocommerce-simple . --values values-production.yaml
```

### 2. Vérification de l'installation
```bash
kubectl get pods -w
```

### 3. Attendre que tous les pods soient "Running"
- `database-orocommerce-simple-0` : Base de données PostgreSQL
- `php-fpm-orocommerce-simple-*` : Backend PHP-FPM
- `webserver-orocommerce-simple-*` : Serveur web Nginx
- `mail-orocommerce-simple-*` : Service mail MailHog

## 🌐 Accès à l'application

### Frontend OroCommerce
- **URL** : `http://localhost:30080`
- **Admin** : `http://localhost:30080/admin`
- **Identifiants** : `admin` / `admin`

### Interface MailHog
- **URL** : `http://localhost:30025`
- **Fonction** : Visualiser les emails envoyés

## 🔧 Configuration des produits

### Pour afficher des produits sur le frontend :

1. **Connecte-toi à l'admin** : `http://localhost:30080/admin`
2. **Va dans** : Products → Products
3. **Pour chaque produit** :
   - Clique sur le produit
   - Onglet "SEO" → "Generate URL"
   - Sauvegarde
4. **Réindexe** : System → Tools → Website Search → Reindex All

## 🛠️ Commandes utiles

### Vérifier l'état des pods
```bash
kubectl get pods
```

### Voir les logs d'un service
```bash
kubectl logs -f deployment/php-fpm-orocommerce-simple
kubectl logs -f deployment/webserver-orocommerce-simple
```

### Accéder à la base de données
```bash
kubectl exec -it database-orocommerce-simple-0 -- psql -U postgres -d orocommerce
```

### Vider le cache
```bash
kubectl exec -it deployment/php-fpm-orocommerce-simple -- php /var/www/oro/bin/console cache:clear
```

## 🗑️ Désinstallation

```bash
helm uninstall orocommerce-simple
kubectl delete pvc --all
```

## ⚠️ Notes importantes

- **Première installation** : Peut prendre 5-10 minutes
- **Volumes** : Les données persistent entre les redémarrages
- **Ressources** : Minimum 4GB RAM recommandé
- **Ports** : 30080 (web), 30025 (mail)

## 🆘 Dépannage

### Si les pods ne démarrent pas :
```bash
kubectl describe pod <nom-du-pod>
kubectl logs <nom-du-pod>
```

### Si l'application ne répond pas :
```bash
kubectl get services
kubectl port-forward service/webserver-orocommerce-simple 8080:80
```

### Si la base de données ne répond pas :
```bash
kubectl exec -it database-orocommerce-simple-0 -- pg_isready -U postgres
``` 