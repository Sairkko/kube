# 🚀 Installation OroCommerce - ONE TAP (Zéro Intervention)

## 📋 Prérequis

- Kubernetes cluster (Docker Desktop, Minikube, etc.)
- Helm 3.x installé
- kubectl configuré

## 🎯 Installation ONE TAP (AUTOMATIQUE)

### 1. Installation complète en une commande
```bash
helm install orocommerce-simple . -f values.yaml
```

**✅ Tout fonctionne automatiquement !** Plus besoin de commandes supplémentaires.

### 2. Attendre que tous les pods soient "Running"
```bash
kubectl get pods -w
```

**Pods attendus :**
- `database-orocommerce-simple-0` : Base de données PostgreSQL
- `php-fpm-orocommerce-simple-*` : Backend PHP-FPM
- `webserver-orocommerce-simple-*` : Serveur web Nginx (configuré automatiquement)
- `mail-orocommerce-simple-*` : Service mail MailHog
- `ws-orocommerce-simple-*` : WebSocket

### 3. Vérifier les services
```bash
kubectl get services
```

**Services attendus :**
- `webserver-orocommerce-simple` : NodePort 30080
- `orocommerce-simple-mail-ui` : NodePort 30616

## 🌐 Accès à l'application

### OroCommerce
- **URL** : `http://oro.demo:30080` ou `http://localhost:30080`
- **Admin** : `http://oro.demo:30080/admin` ou `http://localhost:30080/admin`
- **Identifiants** : `admin` / `admin`

### MailHog (Interface mail)
- **URL** : `http://localhost:30616`
- **Fonction** : Capture tous les emails envoyés par OroCommerce

## 🔧 Configuration automatique

### ✅ Ce qui est configuré automatiquement :
1. **Base de données PostgreSQL** avec données d'exemple
2. **Nginx** configuré pour OroCommerce (suppression automatique du fichier default.conf)
3. **PHP-FPM** avec permissions correctes
4. **MailHog** pour capturer les emails
5. **WebSocket** pour les notifications temps réel
6. **Permissions** des dossiers var/sessions, var/cache, etc.
7. **Configuration mailer** vers MailHog
8. **Service NodePort** sur le port 30080

### 🎯 Test de l'installation

#### Test de l'application :
1. Accédez à `http://oro.demo:30080`
2. Connectez-vous avec `admin/admin`
3. L'interface d'administration devrait être accessible

#### Test des emails :
1. Accédez à `http://localhost:30616` (MailHog)
2. Dans OroCommerce, utilisez la commande de test :
   ```bash
   kubectl exec -it $(kubectl get pods -l app=php-fpm-orocommerce-simple -o jsonpath='{.items[0].metadata.name}') -- php /var/www/oro/bin/console mailer:test test@example.com --subject="Test" --body="Test email"
   ```
3. L'email devrait apparaître dans MailHog

## 🗑️ Désinstallation complète

```bash
helm uninstall orocommerce-simple
kubectl delete pvc --all
```

## 🔄 Réinstallation propre

```bash
# Désinstallation complète
helm uninstall orocommerce-simple
kubectl delete pvc --all

# Réinstallation ONE TAP
helm install orocommerce-simple . -f values.yaml
```

## 🐛 Dépannage

### Si OroCommerce affiche "Welcome to nginx" :
- Le pod webserver se redémarre automatiquement avec la bonne configuration
- Attendez 30 secondes et rechargez la page

### Si les emails n'apparaissent pas dans MailHog :
- Vérifiez que le pod mail est en "Running"
- Testez avec la commande mailer:test ci-dessus

### Si la connexion admin ne fonctionne pas :
- Vérifiez que tous les pods sont en "Running"
- Attendez que le job d'installation soit "Completed"

## 📝 Notes importantes

- **Configuration hosts** : Ajoutez `127.0.0.1 oro.demo` dans votre fichier hosts pour une meilleure expérience
- **Ports** : 30080 (OroCommerce), 30616 (MailHog)
- **Données** : L'installation inclut des données d'exemple
- **Sécurité** : Configuration de développement uniquement

---

**🎉 Installation ONE TAP réussie ! Tout fonctionne automatiquement.** 