#!/bin/bash

# Script principal para configurar SSH completo entre Jenkins Controller e Agent
# Execute este script no Jenkins Controller

echo "🚀 Iniciando configuração SSH completa entre Jenkins Controller e Agent..."
echo ""

# Verificar se está rodando como root
if [[ $EUID -ne 0 ]]; then
   echo "❌ Este script deve ser executado como root"
   echo "💡 Execute: sudo $0"
   exit 1
fi

# Verificar se o Jenkins está rodando
echo "🔍 Verificando se o Jenkins está rodando..."
if ! systemctl is-active --quiet jenkins; then
    echo "❌ Jenkins não está rodando"
    echo "🔧 Iniciando Jenkins..."
    systemctl start jenkins
    sleep 5
fi

echo "✅ Jenkins está rodando"
echo ""

# Executar configuração SSH completa
echo "🔑 Executando configuração SSH completa..."
./setup-jenkins-ssh-complete.sh

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Configuração SSH concluída com sucesso!"
    echo ""
    
    # Executar configuração da credencial
    echo "🔑 Configurando credencial SSH no Jenkins..."
    ./setup-jenkins-credential.sh
    
    if [ $? -eq 0 ]; then
        echo ""
        echo "🎉 Configuração completa finalizada!"
        echo ""
        echo "📋 Resumo da configuração:"
        echo "   Controller: $(hostname)"
        echo "   Agent: root@135.181.24.29"
        echo "   Credential ID: jenkins-ssh-key"
        echo "   Chave SSH: /var/lib/jenkins/.ssh/id_rsa"
        echo ""
        echo "🧪 Testando conexão final..."
        if sudo -u jenkins ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 "root@135.181.24.29" "echo '✅ Conexão SSH funcionando perfeitamente!'"; then
            echo "🎉 Tudo configurado e funcionando!"
            echo ""
            echo "📝 Seu Jenkinsfile já está configurado corretamente:"
            echo "   sshagent(['jenkins-ssh-key']) {"
            echo "       sh 'ssh root@135.181.24.29 \"comando\"'"
            echo "   }"
        else
            echo "❌ Falha no teste final"
            echo "🔧 Verifique os logs e configurações"
        fi
    else
        echo "❌ Falha na configuração da credencial"
    fi
else
    echo "❌ Falha na configuração SSH"
    echo "🔧 Verifique os logs e tente novamente"
fi

echo ""
echo "🏁 Script finalizado!" 