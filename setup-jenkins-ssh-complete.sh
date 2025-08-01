#!/bin/bash

# Script completo para configurar SSH entre Jenkins Controller e Agent
# Execute este script no Jenkins Controller

echo "🔑 Configurando SSH completo entre Jenkins Controller e Agent..."

# Configurações
VM_HOST="135.181.24.29"
VM_USER="root"
VM_PASSWORD="ZX100mil!"

echo "🖥️  Configurando conexão para: $VM_USER@$VM_HOST"

# 1. Verificar se o diretório SSH do Jenkins existe
echo "📁 Verificando diretório SSH do Jenkins..."
if [ ! -d "/var/lib/jenkins/.ssh" ]; then
    echo "🔧 Criando diretório SSH do Jenkins..."
    sudo mkdir -p /var/lib/jenkins/.ssh
    sudo chown jenkins:jenkins /var/lib/jenkins/.ssh
    sudo chmod 700 /var/lib/jenkins/.ssh
fi

# 2. Gerar chave SSH se não existir
echo "🔑 Verificando chave SSH do Jenkins..."
if [ ! -f "/var/lib/jenkins/.ssh/id_rsa" ]; then
    echo "🔧 Gerando nova chave SSH para Jenkins..."
    sudo -u jenkins ssh-keygen -t rsa -b 4096 -f /var/lib/jenkins/.ssh/id_rsa -N ""
    echo "✅ Chave SSH gerada"
else
    echo "✅ Chave SSH já existe"
fi

# 3. Obter chave pública
echo "📋 Chave pública do Jenkins:"
PUBLIC_KEY=$(sudo cat /var/lib/jenkins/.ssh/id_rsa.pub)
echo "$PUBLIC_KEY"
echo ""

# 4. Instalar sshpass se não estiver disponível
echo "📦 Verificando sshpass..."
if ! command -v sshpass &> /dev/null; then
    echo "🔧 Instalando sshpass..."
    sudo apt-get update
    sudo apt-get install -y sshpass
fi

# 5. Configurar SSH na VM
echo "🖥️  Configurando SSH na VM..."
sshpass -p "$VM_PASSWORD" ssh -o StrictHostKeyChecking=no "$VM_USER@$VM_HOST" << 'EOF'
echo "🔑 Configurando SSH na VM..."

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

echo "✅ Diretório SSH configurado"
EOF

# 6. Enviar chave pública para a VM
echo "📤 Enviando chave pública para a VM..."
echo "$PUBLIC_KEY" | sshpass -p "$VM_PASSWORD" ssh -o StrictHostKeyChecking=no "$VM_USER@$VM_HOST" "cat >> ~/.ssh/authorized_keys"

# 7. Verificar configuração na VM
echo "🔍 Verificando configuração na VM..."
sshpass -p "$VM_PASSWORD" ssh -o StrictHostKeyChecking=no "$VM_USER@$VM_HOST" << 'EOF'
echo "🔍 Verificando permissões SSH..."
ls -la ~/.ssh/
echo ""
echo "📋 Conteúdo do authorized_keys:"
cat ~/.ssh/authorized_keys
echo ""
EOF

# 8. Testar conexão SSH sem senha
echo "🧪 Testando conexão SSH sem senha..."
if sudo -u jenkins ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 "$VM_USER@$VM_HOST" "echo '✅ Conexão SSH sem senha funcionando!'"; then
    echo "🎉 Conexão SSH configurada com sucesso!"
else
    echo "❌ Falha na conexão SSH sem senha"
    echo "🔧 Verificando configurações..."
    
    # Verificar permissões no Jenkins
    echo "🔍 Permissões no Jenkins:"
    sudo ls -la /var/lib/jenkins/.ssh/
    
    # Verificar configuração SSH na VM
    echo "🔍 Verificando configuração SSH na VM..."
    sshpass -p "$VM_PASSWORD" ssh -o StrictHostKeyChecking=no "$VM_USER@$VM_HOST" << 'EOF'
echo "🔍 Configuração SSH na VM:"
echo "Permissões:"
ls -la ~/.ssh/
echo ""
echo "Conteúdo authorized_keys:"
cat ~/.ssh/authorized_keys
echo ""
echo "Configuração SSH:"
grep -E "(PasswordAuthentication|PubkeyAuthentication)" /etc/ssh/sshd_config || echo "Configuração não encontrada"
EOF
fi

echo ""
echo "🎉 Configuração SSH completa finalizada!"
echo ""
echo "📋 Resumo:"
echo "   Controller: $(hostname)"
echo "   Agent: $VM_USER@$VM_HOST"
echo "   Chave: /var/lib/jenkins/.ssh/id_rsa"
echo ""
echo "🔧 Para testar manualmente:"
echo "   sudo -u jenkins ssh $VM_USER@$VM_HOST"
echo ""
echo "📝 Para usar no Jenkinsfile:"
echo "   sshagent(['jenkins-ssh-key']) {"
echo "       sh 'ssh $VM_USER@$VM_HOST \"comando\"'"
echo "   }" 