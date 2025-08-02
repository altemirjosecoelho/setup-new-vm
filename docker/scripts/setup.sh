#!/bin/bash

# Script de setup automatizado para Traefik e Portainer
# Uso: ./setup.sh

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

# Verificar se Docker está instalado
check_docker() {
    log "Verificando se Docker está instalado..."
    if ! command -v docker &> /dev/null; then
        error "Docker não está instalado. Instale o Docker primeiro."
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        error "Docker Compose não está instalado. Instale o Docker Compose primeiro."
    fi
    
    log "Docker e Docker Compose encontrados!"
}

# Verificar se arquivo .env existe
check_env() {
    log "Verificando arquivo .env..."
    if [ ! -f .env ]; then
        warn "Arquivo .env não encontrado!"
        if [ -f env.example ]; then
            log "Copiando env.example para .env..."
            cp env.example .env
            warn "Por favor, edite o arquivo .env com suas configurações antes de continuar."
            exit 1
        else
            error "Arquivo env.example não encontrado!"
        fi
    fi
    
    log "Arquivo .env encontrado!"
}

# Carregar variáveis do .env
load_env() {
    log "Carregando variáveis de ambiente..."
    if [ -f .env ]; then
        export $(cat .env | grep -v '^#' | xargs)
    fi
}

# Verificar variáveis obrigatórias
check_variables() {
    log "Verificando variáveis obrigatórias..."
    
    local required_vars=("TRAEFIK_SUBDOMAIN" "DEFAULT_DOMAIN" "PORTAINER_SUBDOMAIN" "ADMIN_PASSWORD")
    
    for var in "${required_vars[@]}"; do
        if [ -z "${!var}" ]; then
            error "Variável $var não está definida no arquivo .env"
        fi
    done
    
    # Definir valores padrão se não estiverem configurados
    if [ -z "$TRAEFIK_NETWORK" ]; then
        TRAEFIK_NETWORK="traefik_network"
        log "Usando network padrão: $TRAEFIK_NETWORK"
    fi
    
    if [ -z "$DEFAULT_EMAIL" ]; then
        DEFAULT_EMAIL="admin@$DEFAULT_DOMAIN"
        log "Usando email padrão: $DEFAULT_EMAIL"
    fi
    
    log "Todas as variáveis obrigatórias estão configuradas!"
}

# Criar network Docker
create_network() {
    log "Criando network Docker..."
    if ! docker network ls | grep -q "$TRAEFIK_NETWORK"; then
        docker network create "$TRAEFIK_NETWORK"
        log "Network $TRAEFIK_NETWORK criada!"
    else
        log "Network $TRAEFIK_NETWORK já existe!"
    fi
}

# Criar diretórios necessários
create_directories() {
    log "Criando diretórios necessários..."
    mkdir -p traefik/config traefik/certificates portainer/data
    log "Diretórios criados!"
}

# Gerar hash da senha
generate_password_hash() {
    log "Gerando hash da senha..."
    if command -v htpasswd &> /dev/null; then
        ADMIN_PASSWORD_HASH=$(htpasswd -nbB admin "$ADMIN_PASSWORD" | cut -d ':' -f 2)
        echo "ADMIN_PASSWORD_HASH=$ADMIN_PASSWORD_HASH" >> .env
        log "Hash da senha gerado e adicionado ao .env!"
    else
        warn "htpasswd não encontrado. Instale apache2-utils para gerar hash da senha."
        warn "Você precisará gerar o hash manualmente e adicionar ADMIN_PASSWORD_HASH ao .env"
    fi
}

# Executar Traefik
start_traefik() {
    log "Iniciando Traefik..."
    docker compose -f docker-compose.traefik.yml --env-file .env up -d
    log "Traefik iniciado!"
}

# Executar Portainer
start_portainer() {
    log "Iniciando Portainer..."
    docker compose -f docker-compose.portainer.yml --env-file .env up -d
    log "Portainer iniciado!"
}

# Verificar status dos containers
check_status() {
    log "Verificando status dos containers..."
    echo ""
    echo "=== STATUS DOS CONTAINERS ==="
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    echo ""
    echo "=== NETWORKS ==="
    docker network ls
    echo ""
}

# Mostrar informações de acesso
show_access_info() {
    log "Setup concluído com sucesso!"
    echo ""
    echo "=== INFORMAÇÕES DE ACESSO ==="
    echo "🌐 Traefik Dashboard: https://$TRAEFIK_SUBDOMAIN.$DEFAULT_DOMAIN"
    echo "👤 Usuário: admin"
    echo "🔑 Senha: $ADMIN_PASSWORD"
    echo ""
    echo "🐳 Portainer: https://$PORTAINER_SUBDOMAIN.$DEFAULT_DOMAIN"
    echo ""
    echo "=== COMANDOS ÚTEIS ==="
    echo "Ver logs do Traefik: docker logs traefik"
    echo "Ver logs do Portainer: docker logs portainer"
    echo "Reiniciar Traefik: docker compose -f docker-compose.traefik.yml --env-file .env restart"
    echo "Reiniciar Portainer: docker compose -f docker-compose.portainer.yml --env-file .env restart"
    echo ""
}

# Função principal
main() {
    log "Iniciando setup do Traefik e Portainer..."
    
    check_docker
    check_env
    load_env
    check_variables
    create_network
    create_directories
    generate_password_hash
    start_traefik
    start_portainer
    check_status
    show_access_info
    
    log "Setup concluído!"
}

# Executar função principal
main "$@" 