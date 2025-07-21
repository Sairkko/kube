# Script PowerShell pour déployer OroCommerce sur Kubernetes
# Usage: .\deploy-simple.ps1 [action]
# Actions: install, upgrade, uninstall, status

param(
    [string]$Action = "install"
)

# Variables
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$NAMESPACE = "oro-simple"
$RELEASE_NAME = "oro-simple"

# Fonctions pour les couleurs
function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Blue
}

function Write-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

# Vérifier les prérequis
function Test-Prerequisites {
    Write-Info "Vérification des prérequis..."
    
    # Vérifier kubectl
    if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) {
        Write-Error "kubectl n'est pas installé"
        exit 1
    }
    
    # Vérifier helm
    if (-not (Get-Command helm -ErrorAction SilentlyContinue)) {
        Write-Error "helm n'est pas installé"
        exit 1
    }
    
    # Vérifier la connexion au cluster
    try {
        kubectl cluster-info | Out-Null
        Write-Success "Prérequis vérifiés"
    }
    catch {
        Write-Error "Impossible de se connecter au cluster Kubernetes"
        exit 1
    }
}

# Installer les dépendances
function Install-Dependencies {
    Write-Info "Installation des dépendances..."
    
    # Ajouter le repository Bitnami
    helm repo add bitnami https://charts.bitnami.com/bitnami
    helm repo update
    
    Write-Success "Dépendances installées"
}

# Préparer l'environnement
function Setup-Environment {
    Write-Info "Préparation de l'environnement..."
    
    # Créer le namespace
    kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -
    
    Write-Success "Environnement préparé"
}

# Installer l'application
function Install-Application {
    Write-Info "Installation d'OroCommerce..."
    
    # Mettre à jour les dépendances
    helm dependency update $SCRIPT_DIR
    
    # Installer avec Chart-simple.yaml et values-simple.yaml
    helm install $RELEASE_NAME $SCRIPT_DIR `
        --namespace $NAMESPACE `
        --values "$SCRIPT_DIR/values-simple.yaml" `
        --timeout 30m `
        --wait
    
    Write-Success "OroCommerce installé"
}

# Mettre à jour l'application
function Update-Application {
    Write-Info "Mise à jour d'OroCommerce..."
    
    # Mettre à jour les dépendances
    helm dependency update $SCRIPT_DIR
    
    # Mettre à jour
    helm upgrade $RELEASE_NAME $SCRIPT_DIR `
        --namespace $NAMESPACE `
        --values "$SCRIPT_DIR/values-simple.yaml" `
        --timeout 30m `
        --wait
    
    Write-Success "OroCommerce mis à jour"
}

# Désinstaller l'application
function Uninstall-Application {
    Write-Info "Désinstallation d'OroCommerce..."
    
    helm uninstall $RELEASE_NAME --namespace $NAMESPACE
    kubectl delete namespace $NAMESPACE
    
    Write-Success "OroCommerce désinstallé"
}

# Vérifier le statut
function Get-Status {
    Write-Info "Statut du déploiement:"
    
    Write-Host ""
    Write-Host "📦 Helm Release:" -ForegroundColor Yellow
    helm status $RELEASE_NAME --namespace $NAMESPACE
    
    Write-Host ""
    Write-Host "🚀 Pods:" -ForegroundColor Yellow
    kubectl get pods -n $NAMESPACE
    
    Write-Host ""
    Write-Host "🔌 Services:" -ForegroundColor Yellow
    kubectl get services -n $NAMESPACE
    
    Write-Host ""
    Write-Host "💾 PVC:" -ForegroundColor Yellow
    kubectl get pvc -n $NAMESPACE
    
    Write-Host ""
    Write-Host "🌐 Accès à l'application:" -ForegroundColor Yellow
    Write-Host "   Port-forward: kubectl port-forward svc/$RELEASE_NAME-frontend 8080:80 -n $NAMESPACE"
    Write-Host "   Puis ouvrez: http://localhost:8080"
    Write-Host "   Login admin: admin / admin"
    Write-Host ""
    Write-Host "📋 Commandes utiles:" -ForegroundColor Yellow
    Write-Host "   kubectl logs -f deployment/$RELEASE_NAME-backend -n $NAMESPACE"
    Write-Host "   kubectl logs -f deployment/$RELEASE_NAME-frontend -n $NAMESPACE"
    Write-Host "   kubectl logs -f statefulset/$RELEASE_NAME-postgresql -n $NAMESPACE"
    Write-Host ""
}

# Fonction principale
function Main {
    Write-Host "🚀 Déploiement OroCommerce Simple" -ForegroundColor Green
    Write-Host "=================================" -ForegroundColor Green
    Write-Host "Action: $Action"
    Write-Host "Namespace: $NAMESPACE"
    Write-Host "Release: $RELEASE_NAME"
    Write-Host ""
    
    switch ($Action.ToLower()) {
        "install" {
            Test-Prerequisites
            Install-Dependencies
            Setup-Environment
            Install-Application
            Get-Status
        }
        "upgrade" {
            Test-Prerequisites
            Update-Application
            Get-Status
        }
        "uninstall" {
            Uninstall-Application
        }
        "status" {
            Get-Status
        }
        default {
            Write-Error "Action inconnue: $Action"
            Write-Host "Actions disponibles: install, upgrade, uninstall, status"
            exit 1
        }
    }
    
    Write-Success "Opération terminée avec succès ! 🎉"
}

# Gestion des erreurs
trap {
    Write-Error "Erreur lors de l'operation. Verifiez les logs ci-dessus."
    exit 1
}

# Exécuter le script
Main 