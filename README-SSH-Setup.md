# 🔑 Configuração SSH para Jenkins

## Problema
O Jenkins não consegue se conectar à VM via SSH porque a chave SSH não está configurada corretamente.

## Solução

### 1. Verificar se a VM está acessível
```bash
# Testar conectividade
ping 135.181.24.29

# Testar porta SSH
nc -zv 135.181.24.29 22
```

### 2. Configurar usuário na VM
Execute na VM:
```bash
# Criar usuário jenkins se não existir
sudo useradd -m -s /bin/bash jenkins
sudo usermod -aG sudo jenkins

# Criar diretório .ssh
sudo mkdir -p /home/jenkins/.ssh
sudo chown jenkins:jenkins /home/jenkins/.ssh
sudo chmod 700 /home/jenkins/.ssh

# Criar authorized_keys
sudo touch /home/jenkins/.ssh/authorized_keys
sudo chown jenkins:jenkins /home/jenkins/.ssh/authorized_keys
sudo chmod 600 /home/jenkins/.ssh/authorized_keys
```

### 3. Gerar chave SSH no Jenkins
Execute no Jenkins:
```bash
# Criar diretório .ssh
mkdir -p /var/lib/jenkins/.ssh
chown jenkins:jenkins /var/lib/jenkins/.ssh
chmod 700 /var/lib/jenkins/.ssh

# Gerar chave SSH
ssh-keygen -t rsa -b 4096 -f /var/lib/jenkins/.ssh/id_rsa -N ""
chown jenkins:jenkins /var/lib/jenkins/.ssh/id_rsa*
chmod 600 /var/lib/jenkins/.ssh/id_rsa
chmod 644 /var/lib/jenkins/.ssh/id_rsa.pub
```

### 4. Copiar chave pública para a VM
```bash
# Obter chave pública
cat /var/lib/jenkins/.ssh/id_rsa.pub

# Copiar para a VM (substitua USERNAME pelo seu usuário na VM)
ssh-copy-id -i /var/lib/jenkins/.ssh/id_rsa.pub USERNAME@135.181.24.29
```

### 5. Testar conexão
```bash
# Testar SSH do Jenkins para a VM
ssh -i /var/lib/jenkins/.ssh/id_rsa jenkins@135.181.24.29 'echo "Conexão SSH OK"'
```

## Alternativa: Usar senha (menos segura)
Se preferir usar senha em vez de chave SSH:

1. Configure o usuário jenkins na VM com senha
2. Modifique o Jenkinsfile para usar autenticação por senha
3. Use sshpass para autenticação automática

## Verificações
- ✅ VM acessível via ping
- ✅ Porta 22 aberta
- ✅ Usuário jenkins existe na VM
- ✅ Chave SSH gerada no Jenkins
- ✅ Chave pública adicionada ao authorized_keys da VM
- ✅ Permissões corretas nos arquivos SSH 