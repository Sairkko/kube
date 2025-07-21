# 🚀 Guide de Démarrage Rapide - OroCommerce sur Kubernetes

## ✅ Prérequis

- **Kubernetes** 1.25+ (minikube, Docker Desktop, ou cluster cloud)
- **Helm** 3.x
- **kubectl** configuré pour accéder au cluster

## 🎯 Déploiement Rapide

### 1. Cloner le projet
```bash
git clone <votre-repo>
cd oro-k8s-migration
```

### 2. Déploiement simple (recommandé pour les tests)
```bash
# Rendre le script exécutable (Linux/Mac)
chmod +x deploy-simple.sh

# Lancer le déploiement
./deploy-simple.sh install
```

### 3. Accéder à l'application
Une fois le déploiement terminé :

```bash
# Port-forward pour accéder à l'application
kubectl port-forward svc/oro-simple-frontend 8080:80 -n oro-simple

# Ouvrir dans le navigateur
http://localhost:8080
```

**Identifiants par défaut :**
- **Username:** admin
- **Password:** admin

## 🔧 Commandes Utiles

### Vérifier le statut
```bash
./deploy-simple.sh status
```

### Voir les logs
```bash
# Logs du backend OroCommerce
kubectl logs -f deployment/oro-simple-backend -n oro-simple

# Logs du frontend Nginx
kubectl logs -f deployment/oro-simple-frontend -n oro-simple

# Logs de la base de données
kubectl logs -f statefulset/oro-simple-postgresql -n oro-simple
```

### Mettre à jour
```bash
./deploy-simple.sh upgrade
```

### Désinstaller
```bash
./deploy-simple.sh uninstall
```

## 📋 Architecture Simple

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Frontend      │    │   Backend       │    │   Database      │
│   (Nginx)       │───▶│   (OroCommerce) │───▶│   (PostgreSQL)  │
│   Port 80       │    │   Port 80       │    │   Port 5432     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 🐛 Dépannage

### Pods qui ne démarrent pas
```bash
# Vérifier le statut des pods
kubectl get pods -n oro-simple

# Voir les détails d'un pod
kubectl describe pod <nom-du-pod> -n oro-simple
```

### Problèmes de base de données
```bash
# Se connecter à la base de données
kubectl exec -it statefulset/oro-simple-postgresql -n oro-simple -- psql -U orocommerce -d orocommerce
```

### Vérifier les ressources
```bash
# Vérifier les PVC
kubectl get pvc -n oro-simple

# Vérifier les services
kubectl get svc -n oro-simple
```

## 🚀 Déploiement Production

Pour un déploiement production, utilisez :

```bash
# Déploiement complet avec monitoring
./scripts/deploy.sh production install
```

Cela inclut :
- ✅ Haute disponibilité (HPA)
- ✅ Monitoring (Prometheus + Grafana)
- ✅ SSL/TLS
- ✅ Elasticsearch
- ✅ Redis
- ✅ Sécurité renforcée

## 📊 Monitoring

Une fois déployé, accédez aux outils de monitoring :

```bash
# Grafana
kubectl port-forward svc/orocommerce-production-grafana 3000:80 -n orocommerce-production

# Prometheus
kubectl port-forward svc/orocommerce-production-prometheus-server 9090:80 -n orocommerce-production
```

## 🔗 Liens Utiles

- [Documentation OroCommerce](https://doc.oroinc.com/)
- [OroCommerce GitHub](https://github.com/oroinc/docker-demo)
- [Helm Charts Documentation](https://helm.sh/docs/)

## 📝 Notes Importantes

1. **Première installation** : Le déploiement initial peut prendre 10-15 minutes
2. **Ressources** : Assurez-vous d'avoir au moins 4GB de RAM disponible
3. **Stockage** : Le déploiement utilise des PVC pour la persistance des données
4. **Sécurité** : Changez les mots de passe par défaut en production

## 🎉 Félicitations !

Vous avez maintenant OroCommerce déployé sur Kubernetes ! 🚀

Pour toute question ou problème, consultez les logs et la documentation officielle. 