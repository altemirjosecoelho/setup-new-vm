#!/bin/bash

# Script para configurar chaves SSH para Jenkins
# Execute este script na VM para configurar a autenticação SSH

echo "🔑 Configurando chaves SSH para Jenkins..."

# Verificar se o usuário jenkins existe
if ! id "jenkins" &>/dev/null; then
    echo "❌ Usuário 'jenkins' não existe na VM"
    echo "🔧 Criando usuário jenkins..."
    sudo useradd -m -s /bin/bash jenkins
    sudo usermod -aG sudo jenkins
    echo "✅ Usuário jenkins criado"
fi

# Criar diretório .ssh para o usuário jenkins
sudo mkdir -p /home/jenkins/.ssh
sudo chown jenkins:jenkins /home/jenkins/.ssh
sudo chmod 700 /home/jenkins/.ssh

# Criar arquivo authorized_keys
sudo touch /home/jenkins/.ssh/authorized_keys
sudo chown jenkins:jenkins /home/jenkins/.ssh/authorized_keys
sudo chmod 600 /home/jenkins/.ssh/authorized_keys

echo "📝 Adicione a chave pública do Jenkins ao arquivo:"
echo "   /home/jenkins/.ssh/authorized_keys"
echo ""
echo "🔧 Para obter a chave pública do Jenkins, execute no Jenkins:"
echo "   cat /var/lib/jenkins/.ssh/id_rsa.pub"
echo ""
echo "📋 Depois copie o conteúdo e adicione ao authorized_keys da VM"
echo ""
echo "✅ Configuração SSH concluída!" 