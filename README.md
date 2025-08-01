# Setup de Infraestrutura com Jenkins

Este projeto automatiza a configuração de uma infraestrutura completa usando Jenkins Pipeline, incluindo Traefik, Portainer, PostgreSQL, MongoDB, Redis e pgAdmin.

## 🏗️ Infraestrutura Configurada

### Containers Docker:
- **Traefik**: Load balancer/reverse proxy
- **Portainer**: Interface web para gerenciar Docker
- **PostgreSQL**: Banco de dados relacional
- **MongoDB**: Banco NoSQL
- **Redis 1**: Cache temporário (porta 6379, sem persistência)
- **Redis 2**: Cache persistente (porta 6380, com persistência)
- **pgAdmin**: Interface web para PostgreSQL

### Domínios Configurados:
- **Traefik**: `https://traefik.testes.possoatender.com`
- **Portainer**: `https://portainer.testes.possoatender.com`
- **pgAdmin**: `https://pgadmin.testes.possoatender.com`

## 🔐 Configuração Segura de Credenciais

### ⚠️ IMPORTANTE: Segurança
**NUNCA** commite credenciais reais no repositório Git. Use sempre variáveis de ambiente ou o sistema de Credentials do Jenkins.

### Método 1: Variáveis de Ambiente no Jenkins

1. Acesse o Jenkins > **Gerenciar Jenkins** > **Configurar o Sistema**
2. Na seção **"Variáveis de ambiente globais"**, adicione:

```bash
# Configurações de Conexão SSH
VM_HOST=192.168.1.100
VM_USER=jenkins
SSH_KEY_PATH=/var/lib/jenkins/.ssh/id_rsa

# Credenciais de Banco de Dados
POSTGRES_PASSWORD=sua_senha_postgres_aqui
MONGODB_PASSWORD=sua_senha_mongodb_aqui
PGADMIN_EMAIL=admin@seudominio.com
PGADMIN_PASSWORD=sua_senha_pgadmin_aqui
PORTAINER_PASSWORD=sua_senha_portainer_aqui

# Domínios (opcional)
TRAEFIK_DOMAIN=traefik.seudominio.com
PORTAINER_DOMAIN=portainer.seudominio.com
PGADMIN_DOMAIN=pgadmin.seudominio.com
```

### Método 2: Sistema de Credentials do Jenkins (Recomendado)

1. Acesse o Jenkins > **Gerenciar Jenkins** > **Gerenciar Credentials**
2. Adicione as credenciais como **Secret text** ou **Username with password**
3. Use os IDs das credenciais no pipeline

Exemplo de uso no pipeline:
```groovy
withCredentials([
    string(credentialsId: 'postgres-password', variable: 'POSTGRES_PASSWORD'),
    string(credentialsId: 'mongodb-password', variable: 'MONGODB_PASSWORD'),
    string(credentialsId: 'portainer-password', variable: 'PORTAINER_PASSWORD')
]) {
    // Seu código aqui
}
```

## 🚀 Como Executar

### Pré-requisitos:
1. Jenkins configurado com agente `Jenkins-Testes-agent`
2. Chave SSH configurada para acesso à VM
3. Variáveis de ambiente configuradas (ver seção acima)

### Execução:
1. Clone este repositório
2. Configure as credenciais no Jenkins
3. Execute o pipeline `Jenkinsfile-setup-vm`

## 📋 Credenciais Padrão (após instalação)

Após a execução bem-sucedida do pipeline, você terá acesso a:

| Serviço | URL | Usuário | Senha |
|---------|-----|---------|-------|
| **Traefik** | `https://traefik.testes.possoatender.com` | - | - |
| **Portainer** | `https://portainer.testes.possoatender.com` | `admin` | Configurada via variável |
| **pgAdmin** | `https://pgadmin.testes.possoatender.com` | Configurado via variável | Configurada via variável |
| **PostgreSQL** | `localhost:5432` | `postgres` | Configurada via variável |
| **MongoDB** | `localhost:27017` | `admin` | Configurada via variável |
| **Redis 1** | `localhost:6379` | - | Sem autenticação |
| **Redis 2** | `localhost:6380` | - | Sem autenticação |

## 🔧 Configurações Técnicas

### Portas Utilizadas:
- **80/443**: Traefik (HTTP/HTTPS)
- **5432**: PostgreSQL
- **6379**: Redis 1 (cache temporário)
- **6380**: Redis 2 (com persistência)
- **27017**: MongoDB
- **9000**: Portainer
- **5050**: pgAdmin

### Volumes Persistentes:
- `/opt/docker/volumes/postgres` - Dados PostgreSQL
- `/opt/docker/volumes/redis-6380` - Dados Redis persistente
- `/opt/docker/volumes/mongodb` - Dados MongoDB
- `/opt/docker/volumes/traefik` - Configurações Traefik
- `/opt/docker/volumes/portainer` - Dados Portainer
- `/opt/docker/volumes/pgadmin` - Dados pgAdmin

### Rede Docker:
- **Nome**: `traefik_network`
- **Tipo**: Bridge
- **Todos os containers conectados**

## 🛡️ Segurança

### Firewall Configurado:
- SSH permitido
- Portas 80, 443, 3000, 8080, 9000, 5050 liberadas
- Demais conexões bloqueadas

### Boas Práticas Implementadas:
- Credenciais via variáveis de ambiente
- Volumes persistentes para dados importantes
- Redis sem persistência para cache temporário
- Rede Docker isolada
- Firewall configurado

## 📝 Logs e Monitoramento

O pipeline inclui:
- Verificação de conectividade
- Testes de saúde dos containers
- Logs detalhados de cada etapa
- Resumo final com status de todos os serviços

## 🤝 Contribuição

1. Fork o projeto
2. Crie uma branch para sua feature (`git checkout -b feature/AmazingFeature`)
3. Commit suas mudanças (`git commit -m 'Add some AmazingFeature'`)
4. Push para a branch (`git push origin feature/AmazingFeature`)
5. Abra um Pull Request

## 📄 Licença

Este projeto está sob a licença MIT. Veja o arquivo `LICENSE` para mais detalhes. 