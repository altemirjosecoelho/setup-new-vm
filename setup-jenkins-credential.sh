#!/bin/bash

# Script para configurar credencial SSH no Jenkins
# Execute este script no Jenkins Controller

echo "🔑 Configurando credencial SSH no Jenkins..."

# Configurações
CREDENTIAL_ID="jenkins-ssh-key"
CREDENTIAL_DESCRIPTION="SSH Key para VM Agent"
KEY_FILE="/var/lib/jenkins/.ssh/id_rsa"

# Verificar se a chave existe
if [ ! -f "$KEY_FILE" ]; then
    echo "❌ Chave SSH não encontrada em $KEY_FILE"
    echo "🔧 Execute primeiro o script setup-jenkins-ssh-complete.sh"
    exit 1
fi

# Verificar se o Jenkins CLI está disponível
if [ ! -f "/var/lib/jenkins/jenkins-cli.jar" ]; then
    echo "📦 Baixando Jenkins CLI..."
    sudo -u jenkins wget -O /var/lib/jenkins/jenkins-cli.jar http://localhost:8080/jnlpJars/jenkins-cli.jar
fi

# Criar arquivo XML para a credencial
echo "📝 Criando configuração da credencial..."
cat > /tmp/ssh-credential.xml << EOF
<com.cloudbees.jenkins.plugins.sshcredentials.impl.BasicSSHUserPrivateKey plugin="ssh-credentials@1.19">
  <scope>GLOBAL</scope>
  <id>$CREDENTIAL_ID</id>
  <description>$CREDENTIAL_DESCRIPTION</description>
  <username>root</username>
  <privateKeySource class="com.cloudbees.jenkins.plugins.sshcredentials.impl.BasicSSHUserPrivateKey\$DirectEntryPrivateKeySource">
    <privateKey>$(sudo cat $KEY_FILE)</privateKey>
  </privateKeySource>
</com.cloudbees.jenkins.plugins.sshcredentials.impl.BasicSSHUserPrivateKey>
EOF

# Adicionar credencial via Jenkins CLI
echo "🔧 Adicionando credencial ao Jenkins..."
if sudo -u jenkins java -jar /var/lib/jenkins/jenkins-cli.jar -s http://localhost:8080/ create-credentials-by-xml system::system::jenkins _ < /tmp/ssh-credential.xml; then
    echo "✅ Credencial SSH adicionada com sucesso!"
else
    echo "❌ Falha ao adicionar credencial"
    echo "🔧 Verificando se o Jenkins está rodando..."
    sudo systemctl status jenkins
    echo ""
    echo "💡 Alternativa manual:"
    echo "1. Acesse Jenkins UI: http://localhost:8080"
    echo "2. Vá em 'Manage Jenkins' > 'Manage Credentials'"
    echo "3. Clique em 'System' > 'Global credentials'"
    echo "4. Clique em 'Add Credentials'"
    echo "5. Selecione 'SSH Username with private key'"
    echo "6. ID: $CREDENTIAL_ID"
    echo "7. Description: $CREDENTIAL_DESCRIPTION"
    echo "8. Username: root"
    echo "9. Private Key: Enter directly"
    echo "10. Cole o conteúdo de: $KEY_FILE"
fi

# Limpar arquivo temporário
rm -f /tmp/ssh-credential.xml

echo ""
echo "🎉 Configuração da credencial finalizada!"
echo ""
echo "📋 Resumo:"
echo "   Credential ID: $CREDENTIAL_ID"
echo "   Description: $CREDENTIAL_DESCRIPTION"
echo "   Key File: $KEY_FILE"
echo ""
echo "📝 Para usar no Jenkinsfile:"
echo "   sshagent(['$CREDENTIAL_ID']) {"
echo "       sh 'ssh root@135.181.24.29 \"comando\"'"
echo "   }" 