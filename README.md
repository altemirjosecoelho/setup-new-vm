# 🖥️ Setup de VMs via Jenkins

Este projeto inclui pipelines e scripts para automatizar a configuração de VMs (Máquinas Virtuais) através do Jenkins, instalando e configurando todas as dependências necessárias para desenvolvimento e produção.

## 🎯 **Quando Usar Jenkins para Setup de VMs**

### ✅ **Cenários Ideais:**
- **Ambientes de desenvolvimento** padronizados
- **Servidores de teste/staging** 
- **Deploy de aplicações** que precisam de dependências específicas
- **Ambientes temporários** para testes
- **Infraestrutura como código** (IaC)

### ⚠️ **Cenários que Requerem Cuidado:**
- **Produção crítica** (melhor usar ferramentas especializadas como Ansible, Terraform)
- **VMs com dados sensíveis**
- **Ambientes muito complexos**

## 📁 **Arquivos do Projeto**

### **Pipelines:**
- `Jenkinsfile-setup-vm` - Pipeline principal para setup de VMs
- `Jenkinsfile` - Pipeline original do projeto

### **Scripts:**
- `scripts/setup-ssh-keys.sh` - Configuração de chaves SSH

## 🚀 **Como Usar**

### **1. Configuração Inicial**

#### **A. Configurar Chaves SSH:**
```bash
# Execute como root ou com sudo
sudo ./scripts/setup-ssh-keys.sh [VM_IP] [VM_USER] [JENKINS_USER]

# Exemplo:
sudo ./scripts/setup-ssh-keys.sh 192.168.1.100 jenkins jenkins
```

#### **B. Configurar Pipeline no Jenkins:**
1. Acesse o Jenkins: `https://jenkins.controller.possoatender.com/`
2. Crie um novo pipeline job
3. Configure para usar o arquivo `Jenkinsfile-setup-vm`
4. Configure as variáveis de ambiente conforme necessário

### **2. Variáveis de Ambiente**

Edite as variáveis no pipeline conforme sua necessidade:

```groovy
environment {
    VM_HOST = '192.168.1.100'  // IP da sua VM
    VM_USER = 'jenkins'        // Usuário SSH na VM
    SSH_KEY_PATH = '/var/lib/jenkins/.ssh/id_rsa'
    
    // Versões das ferramentas
    NODE_VERSION = '18.x'
    DOCKER_VERSION = 'latest'
    POSTGRES_VERSION = '15'
    REDIS_VERSION = '7'
    
    // Configurações de containers
    POSTGRES_CONTAINER = 'postgres-app'
    REDIS_CONTAINER = 'redis-app'
    POSTGRES_PORT = '5432'
    REDIS_PORT = '6379'
    POSTGRES_PASSWORD = 'postgres123'
    POSTGRES_DB = 'appdb'
}
```

### **3. Executar o Pipeline**

1. **No Jenkins:**
   - Acesse o job criado
   - Clique em "Build Now"
   - Acompanhe os logs em tempo real

2. **Via Git (se configurado):**
   - Faça push para a branch configurada
   - O Jenkins executará automaticamente

## 📋 **O que o Pipeline Instala/Configura**

### **🔧 Ferramentas Principais:**
- **Node.js** (versão configurável)
- **NPM** (gerenciador de pacotes)
- **Docker** (containerização)
- **Docker Compose** (orquestração)
- **Git** (controle de versão)
- **PM2** (gerenciamento de processos Node.js)

### **🗄️ Bancos de Dados:**
- **PostgreSQL** (container Docker)
- **Redis** (container Docker)

### **🛠️ Ferramentas Adicionais:**
- **htop** (monitoramento de sistema)
- **tree** (visualização de diretórios)
- **jq** (processamento JSON)
- **curl/wget** (requisições HTTP)
- **vim** (editor de texto)
- **nginx** (servidor web)
- **nodemon** (desenvolvimento Node.js)
- **concurrently** (execução paralela)
- **cross-env** (variáveis de ambiente)

### **🔥 Segurança:**
- **UFW Firewall** configurado
- **Portas específicas** liberadas
- **SSH seguro** configurado

## 🔍 **Stages do Pipeline**

### **1. Verificar Conectividade**
- Testa conexão SSH com a VM
- Verifica informações básicas do sistema

### **2. Verificar Dependências Existentes**
- Verifica se Node.js, Docker, Git já estão instalados
- Evita reinstalações desnecessárias

### **3. Instalar Node.js**
- Remove versões antigas
- Instala versão configurada via NodeSource
- Instala PM2 globalmente

### **4. Instalar Docker**
- Remove versões antigas
- Instala Docker CE oficial
- Configura usuário no grupo docker
- Habilita e inicia o serviço

### **5. Configurar Containers de Banco**
- Cria rede Docker para containers
- Executa PostgreSQL com volume persistente
- Executa Redis com volume persistente
- Testa conectividade dos bancos

### **6. Instalar Ferramentas Adicionais**
- Instala ferramentas de sistema
- Instala ferramentas de desenvolvimento Node.js

### **7. Configurar Firewall**
- Instala e configura UFW
- Libera portas necessárias
- Habilita firewall

### **8. Teste Final do Ambiente**
- Executa testes em todas as ferramentas
- Verifica conectividade dos containers
- Valida configuração completa

## 📊 **Monitoramento e Logs**

### **Logs Detalhados:**
- Cada stage gera logs específicos
- Informações de versão das ferramentas
- Status de containers e serviços
- Testes de conectividade

### **Tratamento de Erros:**
- **Rollback automático** em caso de falha
- **Logs de debug** para troubleshooting
- **Informações de sistema** em caso de erro

## 🔧 **Personalização**

### **Adicionar Novas Ferramentas:**
Edite o stage `'Instalar Ferramentas Adicionais'`:

```groovy
stage('Instalar Ferramentas Adicionais') {
    steps {
        script {
            sh '''
                ssh -i ${SSH_KEY_PATH} ${VM_USER}@${VM_HOST} '''
                    # Suas ferramentas aqui
                    sudo apt-get install -y sua-ferramenta
                    sudo npm install -g seu-pacote-npm
                '''
            '''
        }
    }
}
```

### **Adicionar Novos Containers:**
Edite o stage `'Configurar Containers de Banco'`:

```groovy
# Exemplo: Adicionar MongoDB
docker run -d \\
    --name mongodb-app \\
    --network app-network \\
    -p 27017:27017 \\
    -v mongodb_data:/data/db \\
    mongo:latest
```

### **Configurar Novas Portas:**
Edite o stage `'Configurar Firewall'`:

```groovy
sudo ufw allow 27017/tcp  # MongoDB
sudo ufw allow 9000/tcp   # Porta customizada
```

## 🛡️ **Segurança**

### **Boas Práticas Implementadas:**
- **Usuário específico** para Jenkins
- **Chaves SSH** em vez de senhas
- **Firewall configurado** com regras específicas
- **Containers isolados** em rede própria
- **Volumes persistentes** para dados
- **Logs de auditoria** completos

### **Recomendações Adicionais:**
- **Altere senhas padrão** dos bancos de dados
- **Configure backup** dos volumes Docker
- **Monitore logs** regularmente
- **Atualize ferramentas** periodicamente

## 🔄 **Manutenção**

### **Atualizações:**
- Execute o pipeline periodicamente para atualizar ferramentas
- Monitore logs para identificar problemas
- Faça backup dos volumes Docker antes de atualizações

### **Troubleshooting:**
- Verifique logs do Jenkins
- Teste conectividade SSH manualmente
- Verifique status dos containers: `docker ps`
- Verifique logs dos containers: `docker logs [container]`

## 📞 **Suporte**

Para problemas ou dúvidas:
1. Verifique os logs do Jenkins
2. Execute testes manuais na VM
3. Consulte a documentação das ferramentas
4. Abra uma issue no repositório

---

**🎯 Resultado Final:** Uma VM completamente configurada e pronta para desenvolvimento/produção com todas as ferramentas necessárias instaladas e configuradas automaticamente! 