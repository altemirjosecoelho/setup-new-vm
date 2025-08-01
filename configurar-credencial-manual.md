# Configuração Manual da Credencial SSH no Jenkins

A configuração SSH foi bem-sucedida! Agora você precisa configurar a credencial SSH no Jenkins manualmente.

## ✅ Status Atual

- ✅ Chave SSH gerada: `/var/lib/jenkins/.ssh/id_rsa`
- ✅ Conexão SSH funcionando: `root@135.181.24.29`
- ✅ VM configurada corretamente
- ⚠️ Credencial SSH precisa ser configurada manualmente

## 🔧 Configurar Credencial SSH no Jenkins

### 1. Acesse o Jenkins UI

Abra seu navegador e acesse: `http://localhost:8080`

### 2. Navegue até Credentials

1. Clique em **Manage Jenkins** (no menu lateral)
2. Clique em **Manage Credentials**
3. Clique em **System** (ou **Global**)
4. Clique em **Global credentials (unrestricted)**
5. Clique em **Add Credentials**

### 3. Configure a Credencial

Preencha os campos:

- **Kind**: `SSH Username with private key`
- **ID**: `jenkins-ssh-key`
- **Description**: `SSH Key para VM Agent`
- **Username**: `root`
- **Private Key**: Selecione `Enter directly`
- **Private Key**: Cole o conteúdo da chave privada

### 4. Obter a Chave Privada

Execute este comando para obter a chave privada:

```bash
sudo cat /var/lib/jenkins/.ssh/id_rsa
```

Copie todo o conteúdo (incluindo as linhas `-----BEGIN OPENSSH PRIVATE KEY-----` e `-----END OPENSSH PRIVATE KEY-----`)

### 5. Salvar a Credencial

Clique em **OK** para salvar a credencial.

## 🧪 Teste Final

Após configurar a credencial, teste o pipeline:

```bash
# Executar o pipeline Jenkins
cd setup-new-vm
# Acesse Jenkins UI e execute o job
```

## 📝 Configuração do Jenkinsfile

O Jenkinsfile já está configurado corretamente:

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

## 🎉 Resultado

Após configurar a credencial, você terá:
- ✅ Autenticação SSH sem senha
- ✅ Credencial SSH no Jenkins
- ✅ Pipeline funcionando perfeitamente
- ✅ Conexão segura entre Controller e Agent

## 🔍 Verificação

Para verificar se tudo está funcionando:

```bash
# Teste manual da conexão SSH
sudo -u jenkins ssh -o StrictHostKeyChecking=no root@135.181.24.29 "echo 'Conexão SSH funcionando!'"
```

## 📞 Próximos Passos

1. Configure a credencial SSH no Jenkins UI
2. Execute o pipeline Jenkins
3. Verifique se a conexão está funcionando
4. Comece a usar o agent para seus builds 