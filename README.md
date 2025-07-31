# 🚀 OroCommerce Kubernetes Installation

Ce dossier contient l'installation complète d'OroCommerce sur Kubernetes.

## 📁 Structure

```
kube/
└── orocommerce-simple/          # Installation principale d'OroCommerce
    ├── Chart.yaml              # Configuration Helm
    ├── values.yaml             # Configuration par défaut
    ├── values-production.yaml  # Configuration de production
    ├── README-INSTALLATION.md  # Guide d'installation détaillé
    ├── charts/                 # Sous-charts Helm
    └── templates/              # Templates Kubernetes
```

## 🎯 Installation rapide

```bash
cd orocommerce-simple
helm install orocommerce-simple . -f values.yaml
```

## 🌐 Accès

- **Frontend** : http://localhost:30080
- **Admin** : http://localhost:30080/admin (admin/admin)
- **MailHog** : http://localhost:30025

## 📖 Documentation

Voir `orocommerce-simple/README-INSTALLATION.md` pour le guide complet d'installation et de configuration. 