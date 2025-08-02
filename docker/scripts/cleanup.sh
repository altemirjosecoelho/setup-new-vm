#!/bin/bash

# Script de limpeza para Traefik e Portainer
# Uso: ./cleanup.sh

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para log
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
    exit 1
}

# Carregar variáveis do .env se existir
load_env() {
    if [ -f .env ]; then
        log "Carregando variáveis de ambiente..."
        export $(cat .env | grep -v '^#' | xargs)
    else
        warn "Arquivo .env não encontrado. Usando valores padrão."
        TRAEFIK_NETWORK="traefik_network"
    fi
}

# Parar e remover containers
stop_containers() {
    log "Parando containers..."
    
    # Parar containers se existirem
    if docker ps -q --filter "name=traefik" | grep -q .; then
        docker stop traefik
        docker rm traefik
        log "Container traefik parado e removido!"
    else
        log "Container traefik não encontrado."
    fi
    
    if docker ps -q --filter "name=portainer" | grep -q .; then
        docker stop portainer
        docker rm portainer
        log "Container portainer parado e removido!"
    else
        log "Container portainer não encontrado."
    fi
}

# Remover network
remove_network() {
    log "Removendo network Docker..."
    if docker network ls | grep -q "$TRAEFIK_NETWORK"; then
        docker network rm "$TRAEFIK_NETWORK"
        log "Network $TRAEFIK_NETWORK removida!"
    else
        log "Network $TRAEFIK_NETWORK não encontrada."
    fi
}

# Remover volumes (opcional)
remove_volumes() {
    read -p "Deseja remover os volumes de dados? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log "Removendo volumes..."
        
        # Remover volume do Portainer
        if docker volume ls -q | grep -q "portainer_data"; then
            docker volume rm portainer_data
            log "Volume portainer_data removido!"
        fi
        
        # Remover diretórios locais
        if [ -d "portainer/data" ]; then
            rm -rf portainer/data
            log "Diretório portainer/data removido!"
        fi
        
        if [ -d "traefik/certificates" ]; then
            rm -rf traefik/certificates
            log "Diretório traefik/certificates removido!"
        fi
    else
        log "Volumes mantidos."
    fi
}

# Remover imagens (opcional)
remove_images() {
    read -p "Deseja remover as imagens Docker? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log "Removendo imagens..."
        
        # Remover imagem do Traefik
        if docker images -q traefik:v2.10 | grep -q .; then
            docker rmi traefik:v2.10
            log "Imagem traefik:v2.10 removida!"
        fi
        
        # Remover imagem do Portainer
        if docker images -q portainer/portainer-ce:latest | grep -q .; then
            docker rmi portainer/portainer-ce:latest
            log "Imagem portainer/portainer-ce:latest removida!"
        fi
    else
        log "Imagens mantidas."
    fi
}

# Limpar arquivos temporários
cleanup_files() {
    log "Limpando arquivos temporários..."
    
    # Remover arquivo .env se existir
    if [ -f .env ]; then
        rm .env
        log "Arquivo .env removido!"
    fi
    
    # Remover logs antigos
    find . -name "*.log" -type f -delete 2>/dev/null || true
    log "Logs antigos removidos!"
}

# Verificar status final
check_final_status() {
    log "Verificando status final..."
    echo ""
    echo "=== CONTAINERS RESTANTES ==="
    docker ps -a --filter "name=traefik" --filter "name=portainer"
    echo ""
    echo "=== NETWORKS RESTANTES ==="
    docker network ls | grep -E "(traefik|portainer)" || echo "Nenhuma network relacionada encontrada."
    echo ""
    echo "=== VOLUMES RESTANTES ==="
    docker volume ls | grep -E "(traefik|portainer)" || echo "Nenhum volume relacionado encontrado."
    echo ""
}

# Função principal
main() {
    log "Iniciando limpeza do Traefik e Portainer..."
    
    load_env
    stop_containers
    remove_network
    remove_volumes
    remove_images
    cleanup_files
    check_final_status
    
    log "Limpeza concluída!"
    echo ""
    echo "=== RESUMO DA LIMPEZA ==="
    echo "✅ Containers parados e removidos"
    echo "✅ Network removida"
    echo "✅ Arquivos temporários limpos"
    echo ""
    echo "Para reinstalar, execute: ./setup.sh"
}

# Executar função principal
main "$@" 