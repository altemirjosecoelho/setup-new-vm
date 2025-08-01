#!/bin/bash

# Script alternativo que usa expect em vez de sshpass
# Execute este script no Jenkins

echo "🔑 Testando conexão SSH com expect..."

# Verificar se expect está instalado
if ! command -v expect &> /dev/null; then
    echo "📦 Instalando expect..."
    sudo apt-get update
    sudo apt-get install -y expect
fi

# Configurações
VM_HOST="135.181.24.29"
VM_USER="root"
VM_PASSWORD="zx100mil!"

# Criar script expect temporário
cat > /tmp/ssh_test.exp << 'EOF'
#!/usr/bin/expect -f

set timeout 30
set host [lindex $argv 0]
set user [lindex $argv 1]
set password [lindex $argv 2]

spawn ssh -o StrictHostKeyChecking=no ${user}@${host}

expect {
    "password:" {
        send "${password}\r"
        exp_continue
    }
    "$ " {
        send "echo '✅ Conexão SSH estabelecida!'\r"
        send "echo '🖥️  Sistema:' \$(uname -a)\r"
        send "echo '📦 Executando apt update...'\r"
        send "apt update\r"
        send "echo '📦 Executando apt upgrade -y...'\r"
        send "apt upgrade -y\r"
        send "echo '🎉 Teste mínimo concluído com sucesso!'\r"
        send "exit\r"
    }
    timeout {
        puts "❌ Timeout na conexão SSH"
        exit 1
    }
}

expect eof
EOF

# Executar script expect
chmod +x /tmp/ssh_test.exp
/tmp/ssh_test.exp $VM_HOST $VM_USER $VM_PASSWORD

# Limpar arquivo temporário
rm -f /tmp/ssh_test.exp 