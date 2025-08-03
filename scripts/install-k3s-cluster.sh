#!/bin/bash

# Script para instalação do K3s, criação de cluster e deploy de container hello world
# Autor: Jenkins Pipeline
# Data: $(date)

set -e  # Para o script se houver erro

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para log colorido
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

# Função para verificar se o comando existe
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Função para detectar arquitetura
detect_architecture() {
    local arch=$(uname -m)
    case $arch in
        x86_64)
            echo "amd64"
            ;;
        aarch64|arm64)
            echo "arm64"
            ;;
        *)
            log_error "Arquitetura não suportada: $arch"
            exit 1
            ;;
    esac
}

# Função para verificar se o usuário é root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        log_warning "Executando como root. Isso pode causar problemas com K3s."
        log_warning "Recomendado executar como usuário não-root."
    fi
}

# Função para verificar requisitos do sistema
check_requirements() {
    log_info "Verificando requisitos do sistema..."
    
    # Verificar se o sistema é Linux
    if [[ "$OSTYPE" != "linux-gnu"* ]]; then
        log_error "Este script é compatível apenas com Linux"
        exit 1
    fi
    
    # Verificar se tem curl instalado
    if ! command_exists curl; then
        log_info "Instalando curl..."
        sudo apt-get update && sudo apt-get install -y curl
    fi
    
    # Verificar se tem wget instalado
    if ! command_exists wget; then
        log_info "Instalando wget..."
        sudo apt-get update && sudo apt-get install -y wget
    fi
    
    # Verificar se tem git instalado
    if ! command_exists git; then
        log_info "Instalando git..."
        sudo apt-get update && sudo apt-get install -y git
    fi
    
    log_success "Requisitos verificados!"
}

# Função para instalar K3s
install_k3s() {
    log_info "Iniciando instalação do K3s..."
    
    # Detectar arquitetura
    local arch=$(detect_architecture)
    log_info "Arquitetura detectada: $arch"
    
    # Verificar se K3s já está instalado
    if command_exists k3s; then
        log_warning "K3s já está instalado!"
        k3s --version
        return 0
    fi
    
    # Instalar K3s
    log_info "Baixando e instalando K3s..."
    curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--docker" sh -
    
    # Aguardar o K3s inicializar
    log_info "Aguardando K3s inicializar..."
    sleep 10
    
    # Verificar se o K3s está rodando
    if sudo systemctl is-active --quiet k3s; then
        log_success "K3s instalado e rodando com sucesso!"
    else
        log_error "Falha ao iniciar K3s"
        sudo systemctl status k3s
        exit 1
    fi
    
    # Configurar permissões do kubeconfig
    sudo chmod 644 /etc/rancher/k3s/k3s.yaml
    
    # Criar link simbólico para kubectl
    if [[ ! -f /usr/local/bin/kubectl ]]; then
        sudo ln -sf /usr/local/bin/k3s kubectl
    fi
    
    log_success "K3s instalado com sucesso!"
}

# Função para configurar o cluster
configure_cluster() {
    log_info "Configurando cluster K3s..."
    
    # Aguardar nodes ficarem prontos
    log_info "Aguardando nodes ficarem prontos..."
    timeout=60
    counter=0
    
    while [[ $counter -lt $timeout ]]; do
        if kubectl get nodes 2>/dev/null | grep -q "Ready"; then
            log_success "Nodes prontos!"
            break
        fi
        sleep 2
        counter=$((counter + 2))
    done
    
    if [[ $counter -ge $timeout ]]; then
        log_error "Timeout aguardando nodes ficarem prontos"
        kubectl get nodes
        exit 1
    fi
    
    # Mostrar informações do cluster
    log_info "Informações do cluster:"
    kubectl cluster-info
    kubectl get nodes -o wide
    
    # Verificar namespaces padrão
    log_info "Namespaces disponíveis:"
    kubectl get namespaces
    
    log_success "Cluster configurado com sucesso!"
}

# Função para criar namespace para o hello world
create_namespace() {
    log_info "Criando namespace para hello world..."
    
    # Verificar se o namespace já existe
    if kubectl get namespace hello-world 2>/dev/null | grep -q "hello-world"; then
        log_warning "Namespace hello-world já existe"
        return 0
    fi
    
    # Criar namespace
    kubectl create namespace hello-world
    
    log_success "Namespace hello-world criado!"
}

# Função para deployar container hello world
deploy_hello_world() {
    log_info "Deployando container hello world..."
    
    # Criar deployment do hello world
    cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: hello-world
  namespace: hello-world
  labels:
    app: hello-world
spec:
  replicas: 2
  selector:
    matchLabels:
      app: hello-world
  template:
    metadata:
      labels:
        app: hello-world
    spec:
      containers:
      - name: hello-world
        image: nginxdemos/hello:latest
        ports:
        - containerPort: 80
        resources:
          requests:
            memory: "64Mi"
            cpu: "50m"
          limits:
            memory: "128Mi"
            cpu: "100m"
        livenessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 5
EOF
    
    # Criar service para expor o hello world
    cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: hello-world-service
  namespace: hello-world
  labels:
    app: hello-world
spec:
  type: NodePort
  ports:
  - port: 80
    targetPort: 80
    nodePort: 30080
    protocol: TCP
  selector:
    app: hello-world
EOF
    
    # Aguardar deployment ficar pronto
    log_info "Aguardando deployment ficar pronto..."
    kubectl rollout status deployment/hello-world -n hello-world
    
    log_success "Container hello world deployado com sucesso!"
}

# Função para verificar o status do deployment
verify_deployment() {
    log_info "Verificando status do deployment..."
    
    # Mostrar pods
    log_info "Pods do hello world:"
    kubectl get pods -n hello-world -o wide
    
    # Mostrar services
    log_info "Services do hello world:"
    kubectl get services -n hello-world
    
    # Mostrar endpoints
    log_info "Endpoints do hello world:"
    kubectl get endpoints -n hello-world
    
    # Testar conectividade
    log_info "Testando conectividade..."
    local node_ip=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
    local node_port=30080
    
    if [[ -n "$node_ip" ]]; then
        log_info "Testando acesso em: http://$node_ip:$node_port"
        
        # Aguardar um pouco para o serviço ficar disponível
        sleep 5
        
        # Testar com curl
        if command_exists curl; then
            if curl -s -o /dev/null -w "%{http_code}" "http://$node_ip:$node_port" | grep -q "200"; then
                log_success "Hello world está acessível!"
                log_info "URL de acesso: http://$node_ip:$node_port"
            else
                log_warning "Hello world pode não estar acessível ainda"
            fi
        fi
    else
        log_warning "Não foi possível obter IP do node"
    fi
    
    log_success "Verificação concluída!"
}

# Função para mostrar informações úteis
show_useful_info() {
    log_info "=== INFORMAÇÕES ÚTEIS ==="
    echo ""
    log_info "Comandos úteis:"
    echo "  kubectl get pods -n hello-world"
    echo "  kubectl logs -f deployment/hello-world -n hello-world"
    echo "  kubectl describe service hello-world-service -n hello-world"
    echo "  kubectl get nodes"
    echo "  kubectl cluster-info"
    echo ""
    log_info "Para acessar o hello world:"
    echo "  http://<IP_DO_NODE>:30080"
    echo ""
    log_info "Para parar o K3s:"
    echo "  sudo systemctl stop k3s"
    echo ""
    log_info "Para desinstalar o K3s:"
    echo "  /usr/local/bin/k3s-uninstall.sh"
    echo ""
    log_info "Kubeconfig localizado em:"
    echo "  /etc/rancher/k3s/k3s.yaml"
    echo ""
}

# Função principal
main() {
    log_info "=== INSTALAÇÃO K3S E CLUSTER HELLO WORLD ==="
    echo ""
    
    # Verificar se é root
    check_root
    
    # Verificar requisitos
    check_requirements
    
    # Instalar K3s
    install_k3s
    
    # Configurar cluster
    configure_cluster
    
    # Criar namespace
    create_namespace
    
    # Deployar hello world
    deploy_hello_world
    
    # Verificar deployment
    verify_deployment
    
    # Mostrar informações úteis
    show_useful_info
    
    log_success "=== INSTALAÇÃO CONCLUÍDA COM SUCESSO! ==="
}

# Executar função principal
main "$@" 