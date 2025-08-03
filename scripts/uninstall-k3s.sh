#!/bin/bash

# Script para desinstalar K3s e limpar recursos
# Autor: Jenkins Pipeline

set -e

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

# Função para parar e remover recursos do Kubernetes
cleanup_kubernetes_resources() {
    log_info "Removendo recursos do Kubernetes..."
    
    if command_exists kubectl; then
        # Remover namespace hello-world se existir
        if kubectl get namespace hello-world 2>/dev/null | grep -q "hello-world"; then
            log_info "Removendo namespace hello-world..."
            kubectl delete namespace hello-world
        fi
        
        # Remover outros recursos que possam ter sido criados
        log_info "Limpando outros recursos..."
        kubectl delete all --all --all-namespaces 2>/dev/null || true
    fi
}

# Função para parar o K3s
stop_k3s() {
    log_info "Parando serviço K3s..."
    
    if sudo systemctl is-active --quiet k3s; then
        sudo systemctl stop k3s
        log_success "K3s parado com sucesso!"
    else
        log_warning "K3s já estava parado"
    fi
    
    # Desabilitar o serviço
    if sudo systemctl is-enabled --quiet k3s; then
        sudo systemctl disable k3s
        log_success "Serviço K3s desabilitado!"
    fi
}

# Função para desinstalar K3s
uninstall_k3s() {
    log_info "Desinstalando K3s..."
    
    if [[ -f /usr/local/bin/k3s-uninstall.sh ]]; then
        log_info "Executando script de desinstalação oficial..."
        sudo /usr/local/bin/k3s-uninstall.sh
        log_success "K3s desinstalado com sucesso!"
    else
        log_warning "Script de desinstalação não encontrado, removendo manualmente..."
        
        # Parar o serviço
        stop_k3s
        
        # Remover arquivos do K3s
        sudo rm -rf /var/lib/rancher/k3s
        sudo rm -rf /etc/rancher/k3s
        sudo rm -f /usr/local/bin/k3s
        sudo rm -f /usr/local/bin/kubectl
        sudo rm -f /usr/local/bin/crictl
        sudo rm -f /usr/local/bin/ctr
        
        # Remover arquivos de configuração do systemd
        sudo rm -f /etc/systemd/system/k3s.service
        sudo rm -f /etc/systemd/system/k3s-agent.service
        
        # Recarregar systemd
        sudo systemctl daemon-reload
        
        log_success "K3s removido manualmente!"
    fi
}

# Função para limpar containers Docker (se existir)
cleanup_docker() {
    log_info "Limpando containers Docker..."
    
    if command_exists docker; then
        # Parar todos os containers
        docker stop $(docker ps -q) 2>/dev/null || true
        
        # Remover todos os containers
        docker rm $(docker ps -aq) 2>/dev/null || true
        
        # Remover imagens relacionadas ao K3s
        docker rmi $(docker images | grep -E "(rancher|k3s)" | awk '{print $3}') 2>/dev/null || true
        
        log_success "Containers Docker limpos!"
    else
        log_warning "Docker não encontrado"
    fi
}

# Função para limpar arquivos temporários
cleanup_temp_files() {
    log_info "Limpando arquivos temporários..."
    
    # Remover arquivos de log do K3s
    sudo rm -rf /var/log/k3s* 2>/dev/null || true
    
    # Limpar cache do apt
    sudo apt-get clean 2>/dev/null || true
    
    log_success "Arquivos temporários limpos!"
}

# Função para verificar se a desinstalação foi bem-sucedida
verify_uninstall() {
    log_info "Verificando se a desinstalação foi bem-sucedida..."
    
    # Verificar se o K3s foi removido
    if ! command_exists k3s; then
        log_success "K3s foi removido com sucesso!"
    else
        log_error "K3s ainda está presente!"
        return 1
    fi
    
    # Verificar se o kubectl foi removido
    if ! command_exists kubectl; then
        log_success "kubectl foi removido com sucesso!"
    else
        log_warning "kubectl ainda está presente"
    fi
    
    # Verificar se os diretórios foram removidos
    if [[ ! -d /var/lib/rancher/k3s ]] && [[ ! -d /etc/rancher/k3s ]]; then
        log_success "Diretórios do K3s foram removidos!"
    else
        log_warning "Alguns diretórios do K3s ainda existem"
    fi
    
    log_success "Verificação concluída!"
}

# Função principal
main() {
    log_info "=== DESINSTALAÇÃO DO K3S ==="
    echo ""
    
    # Confirmar com o usuário
    read -p "Tem certeza que deseja desinstalar o K3s? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Desinstalação cancelada pelo usuário"
        exit 0
    fi
    
    # Limpar recursos do Kubernetes
    cleanup_kubernetes_resources
    
    # Parar K3s
    stop_k3s
    
    # Desinstalar K3s
    uninstall_k3s
    
    # Limpar Docker
    cleanup_docker
    
    # Limpar arquivos temporários
    cleanup_temp_files
    
    # Verificar desinstalação
    verify_uninstall
    
    log_success "=== DESINSTALAÇÃO CONCLUÍDA COM SUCESSO! ==="
    echo ""
    log_info "Para reinstalar o K3s, execute:"
    echo "  ./install-k3s-cluster.sh"
}

# Executar função principal
main "$@" 