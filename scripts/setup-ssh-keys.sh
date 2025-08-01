#!/bin/bash

# Script para configurar chaves SSH entre Jenkins e VMs
# Uso: ./setup-ssh-keys.sh [VM_IP] [VM_USER] [JENKINS_USER]

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para log colorido
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
}

info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $1${NC}"
}

# Verifica parâmetros
if [ $# -lt 3 ]; then
    echo "Uso: $0 <VM_IP> <VM_USER> <JENKINS_USER>"
    echo "Exemplo: $0 192.168.1.100 jenkins jenkins"
    exit 1
fi

VM_IP=$1
VM_USER=$2
JENKINS_USER=$3
JENKINS_HOME="/var/lib/jenkins"
SSH_DIR="$JENKINS_HOME/.ssh"
SSH_KEY="$SSH_DIR/id_rsa"

log "Configurando SSH entre Jenkins e VM $VM_IP"

# Verifica se está rodando como root ou com sudo
if [ "$EUID" -ne 0 ]; then
    error "Este script precisa ser executado como root ou com sudo"
    exit 1
fi

# Cria diretório SSH se não existir
if [ ! -d "$SSH_DIR" ]; then
    log "Criando diretório SSH: $SSH_DIR"
    mkdir -p "$SSH_DIR"
    chown "$JENKINS_USER:$JENKINS_USER" "$SSH_DIR"
    chmod 700 "$SSH_DIR"
fi

# Gera chave SSH se não existir
if [ ! -f "$SSH_KEY" ]; then
    log "Gerando nova chave SSH para Jenkins"
    sudo -u "$JENKINS_USER" ssh-keygen -t rsa -b 4096 -f "$SSH_KEY" -N "" -C "jenkins@$(hostname)"
    chmod 600 "$SSH_KEY"
    chmod 644 "$SSH_KEY.pub"
else
    log "Chave SSH já existe: $SSH_KEY"
fi

# Copia chave pública para a VM
log "Copiando chave pública para VM $VM_IP"
if ssh-copy-id -i "$SSH_KEY.pub" "$VM_USER@$VM_IP"; then
    log "Chave pública copiada com sucesso"
else
    warn "Não foi possível copiar a chave automaticamente"
    info "Execute manualmente:"
    echo "ssh-copy-id -i $SSH_KEY.pub $VM_USER@$VM_IP"
    echo ""
    info "Ou copie o conteúdo da chave pública:"
    cat "$SSH_KEY.pub"
    echo ""
    info "E adicione ao arquivo ~/.ssh/authorized_keys na VM"
fi

# Testa conexão SSH
log "Testando conexão SSH com a VM"
if ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 "$VM_USER@$VM_IP" "echo 'Conexão SSH estabelecida com sucesso'"; then
    log "✅ Conexão SSH funcionando corretamente"
else
    error "❌ Falha na conexão SSH"
    info "Verifique:"
    echo "1. Se a VM está acessível: ping $VM_IP"
    echo "2. Se o usuário $VM_USER existe na VM"
    echo "3. Se a chave foi adicionada ao authorized_keys"
    echo "4. Se o SSH está rodando na VM: sudo systemctl status ssh"
    exit 1
fi

# Configura SSH config para facilitar conexões
SSH_CONFIG="$SSH_DIR/config"
if [ ! -f "$SSH_CONFIG" ]; then
    log "Criando arquivo de configuração SSH"
    cat > "$SSH_CONFIG" << EOF
Host vm-*
    User $VM_USER
    IdentityFile $SSH_KEY
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
    ServerAliveInterval 60
    ServerAliveCountMax 3

Host vm-app
    HostName $VM_IP
    Port 22
EOF
    chown "$JENKINS_USER:$JENKINS_USER" "$SSH_CONFIG"
    chmod 600 "$SSH_CONFIG"
else
    log "Arquivo de configuração SSH já existe"
fi

# Testa conexão usando o alias
log "Testando conexão usando alias 'vm-app'"
if sudo -u "$JENKINS_USER" ssh vm-app "echo 'Conexão via alias funcionando'"; then
    log "✅ Conexão via alias funcionando"
else
    warn "Conexão via alias falhou, mas conexão direta funciona"
fi

# Mostra informações finais
log "Configuração SSH concluída!"
echo ""
info "Resumo da configuração:"
echo "  VM IP: $VM_IP"
echo "  VM User: $VM_USER"
echo "  Jenkins User: $JENKINS_USER"
echo "  SSH Key: $SSH_KEY"
echo "  SSH Config: $SSH_CONFIG"
echo ""
info "Para testar manualmente:"
echo "  sudo -u $JENKINS_USER ssh $VM_USER@$VM_IP"
echo "  sudo -u $JENKINS_USER ssh vm-app"
echo ""
info "Para usar no Jenkinsfile:"
echo "  ssh -i $SSH_KEY $VM_USER@$VM_IP 'comando'"
echo "  ssh vm-app 'comando'"

log "Setup SSH concluído com sucesso!" 