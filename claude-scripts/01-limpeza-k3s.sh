#!/bin/bash

# 01 - Script de Limpeza K3s
# Remove instalações existentes do K3s e dependências

set -e

echo "🧹 [01] Iniciando limpeza do sistema..."

# Função para verificar se comando existe
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# 1. Limpar instalação existente do K3s
echo "🗑️  Removendo K3s existente..."
if [ -f /usr/local/bin/k3s-uninstall.sh ]; then
    sudo /usr/local/bin/k3s-uninstall.sh
fi

# Limpeza adicional de diretórios
echo "🧽 Limpeza adicional de diretórios..."
sudo rm -rf /etc/ceph /etc/cni /etc/kubernetes /opt/cni /run/calico /run/flannel \
    /run/secrets/kubernetes.io /var/lib/calico /var/lib/cni /var/lib/etcd \
    /var/lib/kubelet /var/lib/weave /var/log/containers /var/log/pods /var/run/calico 2>/dev/null || true

# 2. Instalar dependências se necessário
echo "📦 Verificando dependências..."
if ! command_exists htpasswd; then
    echo "   Instalando apache2-utils..."
    sudo apt update && sudo apt install -y apache2-utils
fi

if ! command_exists helm; then
    echo "   Instalando Helm..."
    curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
    sudo apt-get update && sudo apt-get install -y helm
fi

echo "✅ [01] Limpeza concluída!"
echo ""
echo "⏭️  Execute o próximo script: ./02-instalacao-k3s-traefik.sh"