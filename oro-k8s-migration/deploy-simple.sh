#!/bin/bash

# Script de déploiement simple pour OroCommerce
# Usage: ./deploy-simple.sh [action]
# Actions: install, upgrade, uninstall, status

set -e

# Variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ACTION=${1:-install}
NAMESPACE="oro-simple"
RELEASE_NAME="oro-simple"

# Couleurs pour les logs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Vérifier les prérequis
check_prerequisites() {
    log_info "Vérification des prérequis..."
    
    # Vérifier kubectl
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl n'est pas installé"
        exit 1
    fi
    
    # Vérifier helm
    if ! command -v helm &> /dev/null; then
        log_error "helm n'est pas installé"
        exit 1
    fi
    
    # Vérifier la connexion au cluster
    if ! kubectl cluster-info &> /dev/null; then
        log_error "Impossible de se connecter au cluster Kubernetes"
        exit 1
    fi
    
    log_success "Prérequis vérifiés"
}

# Installer les dépendances
install_dependencies() {
    log_info "Installation des dépendances..."
    
    # Ajouter le repository Bitnami
    helm repo add bitnami https://charts.bitnami.com/bitnami
    helm repo update
    
    log_success "Dépendances installées"
}

# Préparer l'environnement
setup_environment() {
    log_info "Préparation de l'environnement..."
    
    # Créer le namespace
    kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -
    
    log_success "Environnement préparé"
}

# Installer l'application
install_application() {
    log_info "Installation d'OroCommerce..."
    
    # Mettre à jour les dépendances
    helm dependency update "$SCRIPT_DIR"
    
    # Installer avec Chart-simple.yaml et values-simple.yaml
    helm install $RELEASE_NAME "$SCRIPT_DIR" \
        --namespace $NAMESPACE \
        --values "$SCRIPT_DIR/values-simple.yaml" \
        --timeout 30m \
        --wait
    
    log_success "OroCommerce installé"
}

# Mettre à jour l'application
upgrade_application() {
    log_info "Mise à jour d'OroCommerce..."
    
    # Mettre à jour les dépendances
    helm dependency update "$SCRIPT_DIR"
    
    # Mettre à jour
    helm upgrade $RELEASE_NAME "$SCRIPT_DIR" \
        --namespace $NAMESPACE \
        --values "$SCRIPT_DIR/values-simple.yaml" \
        --timeout 30m \
        --wait
    
    log_success "OroCommerce mis à jour"
}

# Désinstaller l'application
uninstall_application() {
    log_info "Désinstallation d'OroCommerce..."
    
    helm uninstall $RELEASE_NAME --namespace $NAMESPACE
    kubectl delete namespace $NAMESPACE
    
    log_success "OroCommerce désinstallé"
}

# Vérifier le statut
check_status() {
    log_info "Statut du déploiement:"
    
    echo ""
    echo "📦 Helm Release:"
    helm status $RELEASE_NAME --namespace $NAMESPACE
    
    echo ""
    echo "🚀 Pods:"
    kubectl get pods -n $NAMESPACE
    
    echo ""
    echo "🔌 Services:"
    kubectl get services -n $NAMESPACE
    
    echo ""
    echo "💾 PVC:"
    kubectl get pvc -n $NAMESPACE
    
    # Obtenir l'IP du service
    FRONTEND_IP=$(kubectl get svc $RELEASE_NAME-frontend -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
    
    if [ -z "$FRONTEND_IP" ]; then
        FRONTEND_IP=$(kubectl get svc $RELEASE_NAME-frontend -n $NAMESPACE -o jsonpath='{.spec.clusterIP}' 2>/dev/null || echo "localhost")
    fi
    
    echo ""
    echo "🌐 Accès à l'application:"
    echo "   Port-forward: kubectl port-forward svc/$RELEASE_NAME-frontend 8080:80 -n $NAMESPACE"
    echo "   Puis ouvrez: http://localhost:8080"
    echo "   Login admin: admin / admin"
    echo ""
    echo "📋 Commandes utiles:"
    echo "   kubectl logs -f deployment/$RELEASE_NAME-backend -n $NAMESPACE"
    echo "   kubectl logs -f deployment/$RELEASE_NAME-frontend -n $NAMESPACE"
    echo "   kubectl logs -f statefulset/$RELEASE_NAME-postgresql -n $NAMESPACE"
    echo ""
}

# Fonction principale
main() {
    echo "🚀 Déploiement OroCommerce Simple"
    echo "================================="
    echo "Action: $ACTION"
    echo "Namespace: $NAMESPACE"
    echo "Release: $RELEASE_NAME"
    echo ""
    
    case $ACTION in
        install)
            check_prerequisites
            install_dependencies
            setup_environment
            install_application
            check_status
            ;;
        upgrade)
            check_prerequisites
            upgrade_application
            check_status
            ;;
        uninstall)
            uninstall_application
            ;;
        status)
            check_status
            ;;
        *)
            log_error "Action inconnue: $ACTION"
            echo "Actions disponibles: install, upgrade, uninstall, status"
            exit 1
            ;;
    esac
    
    log_success "Opération terminée avec succès ! 🎉"
}

# Gestion des erreurs
trap 'log_error "Erreur lors de l'\''opération. Vérifiez les logs ci-dessus."' ERR

# Exécuter le script
main "$@" 