#!/bin/bash

# Script de Instalação Completa K3s + Traefik + Rancher
# Executa todos os scripts em sequência

set -e

# Configurações globais (modifique conforme necessário)
export DOMAIN=${DOMAIN:-"traefik.testes.possoatender.com"}
export RANCHER_DOMAIN=${RANCHER_DOMAIN:-"rancher.testes.possoatender.com"}
export EMAIL=${EMAIL:-"admin@possoatender.com"}
export USERNAME=${USERNAME:-"admin"}
export PASSWORD=${PASSWORD:-"ZX@geb0090"}
export RANCHER_PASSWORD=${RANCHER_PASSWORD:-"RancherAdmin123!"}

echo "🚀 Iniciando instalação completa do K3s + Traefik + Rancher..."
echo "   Domínio Traefik: $DOMAIN"
echo "   Domínio Rancher: $RANCHER_DOMAIN"
echo "   Email: $EMAIL"
echo ""

# Verificar se os scripts existem
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ ! -f "$SCRIPT_DIR/01-limpeza-k3s.sh" ]; then
    echo "❌ Script 01-limpeza-k3s.sh não encontrado!"
    exit 1
fi

if [ ! -f "$SCRIPT_DIR/02-instalacao-k3s-traefik.sh" ]; then
    echo "❌ Script 02-instalacao-k3s-traefik.sh não encontrado!"
    exit 1
fi

if [ ! -f "$SCRIPT_DIR/03-instalacao-rancher.sh" ]; then
    echo "❌ Script 03-instalacao-rancher.sh não encontrado!"
    exit 1
fi

# Tornar scripts executáveis
chmod +x "$SCRIPT_DIR/01-limpeza-k3s.sh"
chmod +x "$SCRIPT_DIR/02-instalacao-k3s-traefik.sh"
chmod +x "$SCRIPT_DIR/03-instalacao-rancher.sh"

# Executar scripts em sequência
echo "📋 Executando scripts em sequência..."
echo ""

echo "🔸 Executando 01-limpeza-k3s.sh..."
"$SCRIPT_DIR/01-limpeza-k3s.sh"
echo ""

echo "🔸 Executando 02-instalacao-k3s-traefik.sh..."
"$SCRIPT_DIR/02-instalacao-k3s-traefik.sh"
echo ""

echo "🔸 Executando 03-instalacao-rancher.sh..."
"$SCRIPT_DIR/03-instalacao-rancher.sh"
echo ""

echo "🎉 Instalação completa finalizada!"
echo ""
echo "📋 Resumo dos acessos:"
echo ""
echo "🔧 Traefik Dashboard:"
echo "   URL: https://$DOMAIN/dashboard/"
echo "   Usuário: $USERNAME"
echo "   Senha: $PASSWORD"
echo ""
echo "🐄 Rancher Management:"
echo "   URL: https://$RANCHER_DOMAIN"
echo "   Usuário: admin"
echo "   Senha: $RANCHER_PASSWORD"
echo ""
echo "✅ Todos os serviços estão rodando com HTTPS automático!"