#!/bin/bash

# Script para configurar SSH para o usuário atual da VM
# Execute este script na VM como o usuário que você quer usar

echo "🔑 Configurando SSH para usuário atual..."

# Obter usuário atual
CURRENT_USER=$(whoami)
echo "👤 Usuário atual: $CURRENT_USER"

# Criar diretório .ssh se não existir
if [ ! -d ~/.ssh ]; then
    echo "📁 Criando diretório .ssh..."
    mkdir -p ~/.ssh
    chmod 700 ~/.ssh
fi

# Criar authorized_keys se não existir
if [ ! -f ~/.ssh/authorized_keys ]; then
    echo "📝 Criando arquivo authorized_keys..."
    touch ~/.ssh/authorized_keys
    chmod 600 ~/.ssh/authorized_keys
fi

echo "🔑 Chave pública do Jenkins:"
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC49lGA+wFJBCz+T0Y7Ny9v1/BuemhTGSCQWnTMggTX4w jenkins@Jenkins-Controller"
echo ""

# Verificar se a chave já existe
if grep -q "jenkins@Jenkins-Controller" ~/.ssh/authorized_keys; then
    echo "✅ Chave pública já existe no authorized_keys"
else
    echo "📝 Adicionando chave pública ao authorized_keys..."
    echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC49lGA+wFJBCz+T0Y7Ny9v1/BuemhTGSCQWnTMggTX4w jenkins@Jenkins-Controller" >> ~/.ssh/authorized_keys
    echo "✅ Chave pública adicionada"
fi

# Verificar permissões
echo "🔍 Verificando permissões..."
ls -la ~/.ssh/
echo ""

echo "🎉 Configuração SSH concluída!"
echo ""
echo "📋 Para usar este usuário no Jenkins, modifique o Jenkinsfile:"
echo "   env.VM_USER = env.VM_USER ?: '$CURRENT_USER'"
echo ""
echo "🔧 Para testar a conexão:"
echo "   ssh -i /var/lib/jenkins/.ssh/id_rsa $CURRENT_USER@135.181.24.29" 