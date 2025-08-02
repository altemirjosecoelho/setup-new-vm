# Setup Traefik e Portainer com Docker Compose

Este diretório contém a configuração completa para executar Traefik (proxy reverso) e Portainer (gerenciamento de containers) usando Docker Compose.

## 📁 Estrutura de Arquivos

```
docker/
├── docker-compose.traefik.yml    # Configuração do Traefik
├── docker-compose.portainer.yml  # Configuração do Portainer
├── traefik/
│   └── config/
│       ├── traefik.yml           # Configuração principal do Traefik
│       └── dynamic.yml           # Configurações dinâmicas
├── portainer/
│   └── data/                     # Dados persistentes do Portainer
├── env.example                   # Exemplo de variáveis de ambiente
└── README.md                     # Este arquivo
```

## 🚀 Como Usar

### 1. Configurar Variáveis de Ambiente

Copie o arquivo de exemplo e configure suas variáveis:

```bash
cp env.example .env
```

Edite o arquivo `.env` com suas configurações:

```env
TRAEFIK_SUBDOMAIN=traefik
DEFAULT_DOMAIN=seudominio.com
DEFAULT_EMAIL=admin@seudominio.com
PORTAINER_SUBDOMAIN=portainer
TRAEFIK_NETWORK=traefik_network
ADMIN_PASSWORD=MinhaSenhaSegura123
```

### 2. Criar Network Docker

```bash
docker network create traefik_network
```

### 3. Executar os Serviços

#### Traefik:
```bash
docker compose -f docker-compose.traefik.yml --env-file .env up -d
```

#### Portainer:
```bash
docker compose -f docker-compose.portainer.yml --env-file .env up -d
```

## 🌐 URLs de Acesso

Após a configuração, você terá acesso aos seguintes serviços:

- **Traefik Dashboard**: https://traefik.seudominio.com
  - Usuário: `admin`
  - Senha: `MinhaSenhaSegura123` (ou a configurada em ADMIN_PASSWORD)

- **Portainer**: https://portainer.seudominio.com
  - Configure na primeira execução

## 🔧 Configurações

### Traefik

O Traefik está configurado com:

- **Dashboard**: Habilitado com autenticação básica
- **SSL/TLS**: Certificados automáticos via Let's Encrypt
- **Redirecionamento**: HTTP → HTTPS automático
- **Segurança**: Headers de segurança configurados
- **Logs**: Nível INFO

### Portainer

O Portainer está configurado para:

- **Persistência**: Dados salvos em `./portainer/data`
- **Acesso**: Via Traefik com SSL
- **Rede**: Conectado à network `traefik_network`

## 📋 Variáveis de Ambiente

| Variável | Descrição | Exemplo |
|----------|-----------|---------|
| `TRAEFIK_SUBDOMAIN` | Subdomínio do Traefik | `traefik` |
| `DEFAULT_DOMAIN` | Domínio principal | `exemplo.com` |
| `DEFAULT_EMAIL` | Email para Let's Encrypt | `admin@exemplo.com` |
| `PORTAINER_SUBDOMAIN` | Subdomínio do Portainer | `portainer` |
| `TRAEFIK_NETWORK` | Nome da network Docker | `traefik_network` |
| `ADMIN_PASSWORD` | Senha do admin do Traefik | `MinhaSenha123` |

## 🔒 Segurança

- **Autenticação**: Traefik protegido com autenticação básica
- **SSL/TLS**: Certificados automáticos via Let's Encrypt
- **Headers**: Headers de segurança configurados
- **Rate Limiting**: Proteção contra ataques de força bruta

## 🐛 Troubleshooting

### Verificar Logs

```bash
# Traefik
docker logs traefik

# Portainer
docker logs portainer
```

### Verificar Status

```bash
docker ps
docker network ls
```

### Reiniciar Serviços

```bash
# Traefik
docker compose -f docker-compose.traefik.yml --env-file .env restart

# Portainer
docker compose -f docker-compose.portainer.yml --env-file .env restart
```

## 📝 Notas Importantes

1. **DNS**: Configure os registros DNS para apontar para seu servidor
2. **Portas**: As portas 80 e 443 devem estar abertas no firewall
3. **Certificados**: Os certificados Let's Encrypt são válidos por 90 dias
4. **Backup**: Faça backup regular dos dados do Portainer

## 🤝 Contribuição

Para contribuir com melhorias:

1. Fork o repositório
2. Crie uma branch para sua feature
3. Commit suas mudanças
4. Push para a branch
5. Abra um Pull Request 