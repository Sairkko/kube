#!/bin/bash

# Script de déploiement OroCommerce sur Kubernetes
# Usage: ./deploy.sh [environment] [action]
# Exemple: ./deploy.sh production install

set -e

# Variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
ENVIRONMENT=${1:-development}
ACTION=${2:-install}
NAMESPACE="orocommerce"

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
    
    # Ajouter les repositories Helm
    helm repo add bitnami https://charts.bitnami.com/bitnami
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    helm repo add grafana https://grafana.github.io/helm-charts
    helm repo update
    
    # Installer cert-manager si nécessaire
    if ! kubectl get namespace cert-manager &> /dev/null; then
        log_info "Installation de cert-manager..."
        kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml
        kubectl wait --for=condition=ready pod -l app=cert-manager --timeout=300s -n cert-manager
    fi
    
    # Installer NGINX Ingress Controller si nécessaire
    if ! kubectl get namespace ingress-nginx &> /dev/null; then
        log_info "Installation de NGINX Ingress Controller..."
        kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml
        kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=ingress-nginx --timeout=300s -n ingress-nginx
    fi
    
    # Installer Metrics Server si nécessaire
    if ! kubectl get deployment metrics-server -n kube-system &> /dev/null; then
        log_info "Installation de Metrics Server..."
        kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
    fi
    
    log_success "Dépendances installées"
}

# Préparer l'environnement
setup_environment() {
    log_info "Préparation de l'environnement $ENVIRONMENT..."
    
    # Créer le namespace si nécessaire
    if [ "$ENVIRONMENT" != "development" ]; then
        NAMESPACE="orocommerce-$ENVIRONMENT"
    fi
    
    kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -
    
    # Créer les secrets si nécessaire
    if [ "$ENVIRONMENT" == "production" ]; then
        create_production_secrets
    fi
    
    log_success "Environnement $ENVIRONMENT préparé"
}

# Créer les secrets pour la production
create_production_secrets() {
    log_info "Création des secrets de production..."
    
    # Générer des mots de passe aléatoirement sécurisés
    DB_PASSWORD=$(openssl rand -base64 32)
    REDIS_PASSWORD=$(openssl rand -base64 32)
    GRAFANA_PASSWORD=$(openssl rand -base64 32)
    
    # Créer les secrets
    kubectl create secret generic orocommerce-secrets \
        --from-literal=db-password="$DB_PASSWORD" \
        --from-literal=redis-password="$REDIS_PASSWORD" \
        --from-literal=grafana-password="$GRAFANA_PASSWORD" \
        --namespace $NAMESPACE \
        --dry-run=client -o yaml | kubectl apply -f -
    
    log_success "Secrets créés"
    log_warning "Sauvegardez ces mots de passe :"
    echo "  DB_PASSWORD: $DB_PASSWORD"
    echo "  REDIS_PASSWORD: $REDIS_PASSWORD"
    echo "  GRAFANA_PASSWORD: $GRAFANA_PASSWORD"
}

# Déployer l'application
deploy_application() {
    log_info "Déploiement de l'application..."
    
    local values_file="$PROJECT_DIR/values-$ENVIRONMENT.yaml"
    
    # Vérifier si le fichier de valeurs existe
    if [ ! -f "$values_file" ]; then
        log_warning "Fichier de valeurs $values_file introuvable, utilisation des valeurs par défaut"
        values_file="$PROJECT_DIR/values.yaml"
    fi
    
    # Exécuter le déploiement Helm
    case $ACTION in
        install)
            helm install orocommerce-$ENVIRONMENT "$PROJECT_DIR" \
                --namespace $NAMESPACE \
                --values "$values_file" \
                --timeout 20m \
                --wait
            ;;
        upgrade)
            helm upgrade orocommerce-$ENVIRONMENT "$PROJECT_DIR" \
                --namespace $NAMESPACE \
                --values "$values_file" \
                --timeout 20m \
                --wait
            ;;
        rollback)
            helm rollback orocommerce-$ENVIRONMENT \
                --namespace $NAMESPACE
            ;;
        *)
            log_error "Action inconnue: $ACTION"
            exit 1
            ;;
    esac
    
    log_success "Application déployée"
}

# Vérifier le déploiement
verify_deployment() {
    log_info "Vérification du déploiement..."
    
    # Attendre que tous les pods soient prêts
    kubectl wait --for=condition=ready pods \
        --all --timeout=600s -n $NAMESPACE
    
    # Vérifier les services
    kubectl get services -n $NAMESPACE
    
    # Vérifier les ingress
    kubectl get ingress -n $NAMESPACE
    
    # Vérifier HPA
    kubectl get hpa -n $NAMESPACE
    
    log_success "Déploiement vérifié"
}

# Afficher les informations de connexion
display_connection_info() {
    log_info "Informations de connexion:"
    
    # Obtenir l'IP de l'ingress
    INGRESS_IP=$(kubectl get ingress -n $NAMESPACE -o jsonpath='{.items[0].status.loadBalancer.ingress[0].ip}')
    
    if [ -z "$INGRESS_IP" ]; then
        INGRESS_IP=$(kubectl get ingress -n $NAMESPACE -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}')
    fi
    
    echo ""
    echo "🌐 Application OroCommerce:"
    echo "   URL: https://$INGRESS_IP"
    echo "   Admin: https://$INGRESS_IP/admin"
    echo "   Login: admin / admin"
    echo ""
    echo "📊 Monitoring:"
    echo "   Grafana: kubectl port-forward svc/orocommerce-$ENVIRONMENT-grafana 3000:80 -n $NAMESPACE"
    echo "   Prometheus: kubectl port-forward svc/orocommerce-$ENVIRONMENT-prometheus-server 9090:80 -n $NAMESPACE"
    echo ""
    echo "🔧 Commandes utiles:"
    echo "   kubectl get pods -n $NAMESPACE"
    echo "   kubectl logs -f deployment/orocommerce-$ENVIRONMENT-backend -n $NAMESPACE"
    echo "   kubectl get hpa -n $NAMESPACE"
    echo ""
}

# Nettoyer les ressources
cleanup() {
    log_info "Nettoyage des ressources..."
    
    helm uninstall orocommerce-$ENVIRONMENT --namespace $NAMESPACE
    kubectl delete namespace $NAMESPACE
    
    log_success "Nettoyage terminé"
}

# Fonction principale
main() {
    echo "🚀 Déploiement OroCommerce sur Kubernetes"
    echo "=========================================="
    echo "Environnement: $ENVIRONMENT"
    echo "Action: $ACTION"
    echo "Namespace: $NAMESPACE"
    echo ""
    
    case $ACTION in
        install)
            check_prerequisites
            install_dependencies
            setup_environment
            deploy_application
            verify_deployment
            display_connection_info
            ;;
        upgrade)
            check_prerequisites
            deploy_application
            verify_deployment
            display_connection_info
            ;;
        rollback)
            check_prerequisites
            deploy_application
            verify_deployment
            ;;
        cleanup)
            cleanup
            ;;
        *)
            log_error "Action inconnue: $ACTION"
            echo "Actions disponibles: install, upgrade, rollback, cleanup"
            exit 1
            ;;
    esac
    
    log_success "Déploiement terminé avec succès ! 🎉"
}

# Gestion des erreurs
trap 'log_error "Erreur lors du déploiement. Vérifiez les logs ci-dessus."' ERR

# Exécuter le script
main "$@" 