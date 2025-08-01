# Configuração SSH entre Jenkins Controller e Agent

Este documento explica como configurar a autenticação SSH entre o Jenkins Controller e o Agent VM.

## 📋 Pré-requisitos

- Jenkins Controller rodando
- Acesso root no Jenkins Controller
- VM Agent acessível via SSH (135.181.24.29)
- Credenciais da VM: `root@135.181.24.29` / `ZX100mil!`

## 🚀 Configuração Automática

### 1. Execute o script principal

```bash
cd setup-new-vm
sudo ./setup-jenkins-ssh-master.sh
```

Este script irá:
- ✅ Verificar se o Jenkins está rodando
- ✅ Gerar chave SSH para o Jenkins
- ✅ Configurar SSH na VM Agent
- ✅ Adicionar credencial SSH no Jenkins
- ✅ Testar a conexão

## 🔧 Configuração Manual

Se preferir configurar manualmente, siga os passos abaixo:

### 1. Gerar chave SSH no Jenkins Controller

```bash
# Criar diretório SSH
sudo mkdir -p /var/lib/jenkins/.ssh
sudo chown jenkins:jenkins /var/lib/jenkins/.ssh
sudo chmod 700 /var/lib/jenkins/.ssh

# Gerar chave SSH
sudo -u jenkins ssh-keygen -t rsa -b 4096 -f /var/lib/jenkins/.ssh/id_rsa -N ""

# Verificar chave pública
sudo cat /var/lib/jenkins/.ssh/id_rsa.pub
```

### 2. Configurar SSH na VM Agent

```bash
# Conectar na VM
ssh root@135.181.24.29

# Criar diretório SSH
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Criar authorized_keys
touch ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys

# Adicionar chave pública (cole a chave do passo anterior)
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC..." >> ~/.ssh/authorized_keys
```

### 3. Adicionar credencial no Jenkins

1. Acesse Jenkins UI: `http://localhost:8080`
2. Vá em **Manage Jenkins** > **Manage Credentials**
3. Clique em **System** > **Global credentials**
4. Clique em **Add Credentials**
5. Configure:
   - **Kind**: SSH Username with private key
   - **ID**: `jenkins-ssh-key`
   - **Description**: `SSH Key para VM Agent`
   - **Username**: `root`
   - **Private Key**: Enter directly
   - Cole o conteúdo de `/var/lib/jenkins/.ssh/id_rsa`

## 🧪 Teste da Configuração

### Teste manual

```bash
# Testar conexão SSH
sudo -u jenkins ssh -o StrictHostKeyChecking=no root@135.181.24.29 "echo 'Conexão SSH funcionando!'"
```

### Teste via Jenkinsfile

O Jenkinsfile já está configurado para usar a credencial SSH:

```groovy
sshagent(['jenkins-ssh-key']) {
    sh '''
        ssh -o StrictHostKeyChecking=no "${VM_USER}@${VM_HOST}" '
            echo "✅ Conexão SSH estabelecida!"
            echo "🖥️  Sistema: $(uname -a)"
        '
    '''
}
```

## 📁 Arquivos de Configuração

- `setup-jenkins-ssh-master.sh` - Script principal
- `setup-jenkins-ssh-complete.sh` - Configuração SSH completa
- `setup-jenkins-credential.sh` - Configuração da credencial
- `Jenkinsfile-setup-vm` - Pipeline Jenkins configurado

## 🔍 Troubleshooting

### Problema: Conexão SSH falha

```bash
# Verificar permissões no Jenkins
sudo ls -la /var/lib/jenkins/.ssh/

# Verificar permissões na VM
ssh root@135.181.24.29 "ls -la ~/.ssh/"

# Verificar logs SSH
sudo tail -f /var/log/auth.log
```

### Problema: Credencial não encontrada

1. Verifique se a credencial foi criada no Jenkins
2. Confirme o ID da credencial: `jenkins-ssh-key`
3. Verifique se o plugin SSH Credentials está instalado

### Problema: Jenkins não consegue conectar

```bash
# Verificar se o Jenkins está rodando
sudo systemctl status jenkins

# Verificar logs do Jenkins
sudo tail -f /var/log/jenkins/jenkins.log
```

## 📝 Configurações Importantes

### VM Agent (135.181.24.29)
- **Usuário**: `root`
- **Senha**: `ZX100mil!`
- **Porta SSH**: `22`

### Jenkins Controller
- **Credential ID**: `jenkins-ssh-key`
- **Chave SSH**: `/var/lib/jenkins/.ssh/id_rsa`
- **Usuário Jenkins**: `jenkins`

## 🎉 Resultado Final

Após a configuração, você terá:
- ✅ Autenticação SSH sem senha entre Controller e Agent
- ✅ Credencial SSH configurada no Jenkins
- ✅ Pipeline funcionando com `sshagent(['jenkins-ssh-key'])`
- ✅ Conexão segura e confiável

## 📞 Suporte

Se encontrar problemas:
1. Verifique os logs do Jenkins e SSH
2. Confirme as permissões dos arquivos
3. Teste a conexão manualmente
4. Verifique se a VM está acessível 