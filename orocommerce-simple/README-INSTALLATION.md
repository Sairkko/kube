# 🚀 Installation OroCommerce - Guide Complet

## 📋 Prérequis

- Kubernetes cluster (Docker Desktop, Minikube, etc.)
- Helm 3.x installé
- kubectl configuré

## 🎯 Installation en une commande

### 1. Installation complète
```bash
helm install orocommerce-simple . -f values.yaml
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

### Configuration du fichier hosts (Windows)

**Important :** Pour accéder à OroCommerce sans problème de redirection, ajoutez cette ligne dans votre fichier hosts :

1. **Ouvrez le fichier hosts en tant qu'administrateur :**
   - Ouvrez Notepad en tant qu'administrateur
   - Ouvrez le fichier : `C:\Windows\System32\drivers\etc\hosts`

2. **Ajoutez cette ligne :**
   ```
   127.0.0.1 oro.demo
   ```

3. **Sauvegardez le fichier**

### Frontend OroCommerce
- **URL recommandée** : `http://oro.demo:30080`
- **URL alternative** : `http://localhost:30080` (peut rediriger vers oro.demo)
- **Admin** : `http://oro.demo:30080/admin`
- **Identifiants** : `admin` / `admin`

### Interface MailHog
- **URL** : `http://localhost:32446/mailcatcher/` (port configuré par défaut)
- **Fonction** : Visualiser les emails envoyés
- **Note** : Le port peut varier si 32446 est déjà utilisé (vérifiez avec `kubectl get services`)

## 🔧 Configuration des produits

### Pour afficher des produits sur le frontend :

1. **Connecte-toi à l'admin** : `http://oro.demo:30080/admin`
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
- **Ports** : 30080 (web), 32446 (mail UI par défaut)
- **Domaine** : Utilisez `oro.demo:30080` pour éviter les problèmes de redirection

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

### Si vous avez des problèmes de redirection :
- Vérifiez que `127.0.0.1 oro.demo` est bien dans votre fichier hosts
- Utilisez `http://oro.demo:30080` au lieu de `localhost:30080`

### Si la base de données ne répond pas :
```bash
kubectl exec -it database-orocommerce-simple-0 -- pg_isready -U postgres
``` 