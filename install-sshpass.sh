#!/bin/bash

# Script para instalar sshpass no Jenkins
# Execute este script no servidor Jenkins

echo "📦 Instalando sshpass no Jenkins..."

# Verificar se está rodando como root
if [[ $EUID -eq 0 ]]; then
    echo "🔧 Instalando sshpass..."
    apt-get update
    apt-get install -y sshpass
    echo "✅ sshpass instalado com sucesso!"
else
    echo "🔧 Tentando instalar com sudo..."
    sudo apt-get update
    sudo apt-get install -y sshpass
    echo "✅ sshpass instalado com sucesso!"
fi

# Verificar instalação
if command -v sshpass &> /dev/null; then
    echo "✅ sshpass está funcionando: $(sshpass -V)"
else
    echo "❌ Falha na instalação do sshpass"
    exit 1
fi 