#!/bin/bash

# Script para configurar usuário jenkins e SSH na VM
# Execute este script na VM como root ou com sudo

echo "🔑 Configurando usuário jenkins e SSH na VM..."

# Verificar se está rodando como root
if [[ $EUID -ne 0 ]]; then
   echo "❌ Este script deve ser executado como root ou com sudo"
   exit 1
fi

# Criar usuário jenkins se não existir
if ! id "jenkins" &>/dev/null; then
    echo "🔧 Criando usuário jenkins..."
    useradd -m -s /bin/bash jenkins
    usermod -aG sudo jenkins
    echo "✅ Usuário jenkins criado"
else
    echo "✅ Usuário jenkins já existe"
fi

# Criar diretório .ssh para o usuário jenkins
echo "📁 Configurando diretório SSH..."
mkdir -p /home/jenkins/.ssh
chown jenkins:jenkins /home/jenkins/.ssh
chmod 700 /home/jenkins/.ssh

# Criar arquivo authorized_keys
touch /home/jenkins/.ssh/authorized_keys
chown jenkins:jenkins /home/jenkins/.ssh/authorized_keys
chmod 600 /home/jenkins/.ssh/authorized_keys

echo "🔑 Chave pública do Jenkins criada:"
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC49lGA+wFJBCz+T0Y7Ny9v1/BuemhTGSCQWnTMggTX4w jenkins@Jenkins-Controller"
echo ""

# Adicionar a chave pública ao authorized_keys
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC49lGA+wFJBCz+T0Y7Ny9v1/BuemhTGSCQWnTMggTX4w jenkins@Jenkins-Controller" >> /home/jenkins/.ssh/authorized_keys

echo "✅ Chave pública adicionada ao authorized_keys"
echo ""

# Verificar configuração SSH
echo "🔍 Verificando configuração SSH..."
if grep -q "PasswordAuthentication yes" /etc/ssh/sshd_config; then
    echo "⚠️  Autenticação por senha está habilitada (recomendado desabilitar para segurança)"
else
    echo "✅ Autenticação por senha está desabilitada"
fi

if grep -q "PubkeyAuthentication yes" /etc/ssh/sshd_config; then
    echo "✅ Autenticação por chave pública está habilitada"
else
    echo "⚠️  Autenticação por chave pública não está habilitada"
fi

# Verificar permissões
echo "🔍 Verificando permissões..."
ls -la /home/jenkins/.ssh/
echo ""

# Testar conexão local
echo "🧪 Testando configuração local..."
su - jenkins -c "echo 'Teste de login para usuário jenkins'"

echo ""
echo "🎉 Configuração SSH concluída!"
echo ""
echo "📋 Próximos passos:"
echo "1. Execute o pipeline Jenkins novamente"
echo "2. Se ainda falhar, verifique se o SSH está configurado corretamente"
echo "3. Verifique se o firewall permite conexões SSH"
echo ""
echo "🔧 Para verificar logs SSH:"
echo "   sudo tail -f /var/log/auth.log" 