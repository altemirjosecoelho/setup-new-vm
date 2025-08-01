# 🔑 Configuração SSH no Jenkins

## Plugins Instalados
- ✅ **SSH Server** - Adiciona funcionalidade de servidor SSH ao Jenkins
- ✅ **SSH Agent** - Permite fornecer credenciais SSH para builds

## Configuração das Credenciais SSH

### 1. Gerar Chave SSH (se necessário)
```bash
# No Jenkins ou em qualquer máquina
ssh-keygen -t rsa -b 4096 -f ~/.ssh/jenkins_key -N ""
```

### 2. Adicionar Chave Pública na VM
```bash
# Copiar a chave pública para a VM
ssh-copy-id -i ~/.ssh/jenkins_key.pub root@135.181.24.29

# Ou manualmente
cat ~/.ssh/jenkins_key.pub | ssh root@135.181.24.29 "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
```

### 3. Configurar Credenciais no Jenkins

#### Opção A: Usando Jenkins Web UI
1. Vá em **Manage Jenkins > Manage Credentials**
2. Clique em **System > Global credentials > Add Credentials**
3. Configure:
   - **Kind**: SSH Username with private key
   - **Scope**: Global
   - **ID**: `jenkins-ssh-key`
   - **Description**: `SSH Key for VM`
   - **Username**: `root`
   - **Private Key**: Enter directly (cole o conteúdo da chave privada)
   - **Passphrase**: (deixe em branco se não tiver)

#### Opção B: Usando Jenkins CLI
```bash
# No Jenkins
java -jar jenkins-cli.jar -s http://localhost:8080/ \
  create-credentials-by-xml system::system::jenkins _ < ssh-credentials.xml
```

### 4. Testar Conexão
```bash
# Testar manualmente
ssh -i ~/.ssh/jenkins_key root@135.181.24.29 'echo "Conexão SSH OK"'
```

## Configuração Alternativa com Senha

Se preferir usar senha em vez de chave SSH:

### 1. Configurar Credenciais de Senha
1. Vá em **Manage Jenkins > Manage Credentials**
2. Clique em **System > Global credentials > Add Credentials**
3. Configure:
   - **Kind**: Username with password
   - **Scope**: Global
   - **ID**: `vm-credentials`
   - **Description**: `VM Login Credentials`
   - **Username**: `root`
   - **Password**: `zx100mil!`

### 2. Modificar Jenkinsfile
```groovy
// Substituir sshagent por withCredentials
withCredentials([usernamePassword(credentialsId: 'vm-credentials', usernameVariable: 'VM_USER', passwordVariable: 'VM_PASSWORD')]) {
    // Usar expect ou sshpass
}
```

## Troubleshooting

### Problema: "jenkins-ssh-key not found"
**Solução**: Configure as credenciais SSH no Jenkins

### Problema: "Permission denied"
**Solução**: Verifique se a chave pública está na VM

### Problema: "Host key verification failed"
**Solução**: Use `-o StrictHostKeyChecking=no` (já configurado)

## Próximos Passos

1. **Configure as credenciais SSH** no Jenkins
2. **Execute o pipeline** - deve funcionar com SSH Agent
3. **Se falhar**, habilite o stage alternativo com senha

## Comandos Úteis

```bash
# Verificar chaves SSH
ls -la ~/.ssh/

# Testar conexão
ssh root@135.181.24.29

# Verificar logs SSH
tail -f /var/log/auth.log
``` 