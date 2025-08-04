# K3s + Traefik + Rancher - Script de Instalação Automática

Este script instala automaticamente um cluster K3s completo com:
- 🔧 **Traefik** - Load balancer e proxy reverso com HTTPS automático
- 🐄 **Rancher** - Interface web para gerenciamento do Kubernetes
- 🔒 **Let's Encrypt** - Certificados SSL automáticos
- 🔐 **Autenticação** - Basic Auth para Traefik e login para Rancher

## 🚀 Uso Rápido

```bash
# Executar com configurações padrão
sudo ./setup-k3s-traefik.sh

# Ou personalizar os domínios
DOMAIN="traefik.meudominio.com" \
RANCHER_DOMAIN="rancher.meudominio.com" \
EMAIL="admin@meudominio.com" \
sudo ./setup-k3s-traefik.sh
```

## ⚙️ Configurações

| Variável | Padrão | Descrição |
|----------|---------|-----------|
| `DOMAIN` | traefik.testes.possoatender.com | Domínio para o dashboard do Traefik |
| `RANCHER_DOMAIN` | rancher.testes.possoatender.com | Domínio para o Rancher |
| `EMAIL` | admin@possoatender.com | Email para Let's Encrypt |
| `USERNAME` | admin | Usuário do Traefik dashboard |
| `PASSWORD` | ZX@geb0090 | Senha do Traefik dashboard |
| `RANCHER_PASSWORD` | RancherAdmin123! | Senha inicial do Rancher |

## 📋 Acessos Após Instalação

### 🔧 Traefik Dashboard
- **URL:** https://traefik.testes.possoatender.com/dashboard/
- **Usuário:** admin
- **Senha:** ZX@geb0090

### 🐄 Rancher Management
- **URL:** https://rancher.testes.possoatender.com
- **Usuário:** admin
- **Senha:** RancherAdmin123!

## 🔧 Comandos Úteis

```bash
# Ver status do cluster
kubectl get all -A

# Ver logs do Traefik
kubectl logs -n kube-system deployment/traefik

# Ver logs do Rancher
kubectl logs -n cattle-system deployment/rancher

# Ver certificados SSL
kubectl get certificates -A

# Reiniciar Rancher se necessário
kubectl rollout restart deployment/rancher -n cattle-system
```

## ⚠️ Pré-requisitos

1. **Ubuntu 22.04 ARM64** (testado)
2. **Acesso root** ou sudo
3. **DNS configurado** - Os domínios devem apontar para o IP do servidor
4. **Portas abertas:**
   - 80 (HTTP)
   - 443 (HTTPS) 
   - 6443 (Kubernetes API)

## 🔍 Troubleshooting

### Certificado SSL não gerado
```bash
# Verificar logs do cert-manager
kubectl logs -n cert-manager deployment/cert-manager

# Verificar certificados
kubectl get certificates -A
kubectl describe certificate -A
```

### Rancher não carrega
```bash
# Verificar pods do Rancher
kubectl get pods -n cattle-system

# Reiniciar Rancher
kubectl rollout restart deployment/rancher -n cattle-system
```

### Traefik não responde
```bash
# Verificar pods do Traefik
kubectl get pods -n kube-system

# Ver IngressRoutes
kubectl get ingressroute -A
```

## 📝 O que o Script Faz

1. ✅ Limpa instalações anteriores do K3s
2. ✅ Instala dependências (apache2-utils, helm)
3. ✅ Instala K3s com Traefik
4. ✅ Configura Traefik com HTTPS automático (TLS challenge)
5. ✅ Cria autenticação básica para dashboard do Traefik
6. ✅ Instala cert-manager para gerenciamento de certificados
7. ✅ Instala Rancher com HTTPS automático
8. ✅ Configura todos os IngressRoutes necessários
9. ✅ Valida funcionamento de todos os componentes

## 🛡️ Segurança

- HTTPS obrigatório com redirecionamento automático
- Certificados válidos do Let's Encrypt
- Autenticação básica no Traefik
- Senhas configuráveis via variáveis de ambiente
- Isolamento de namespaces no Kubernetes

## 🔄 Atualizações

Para atualizar componentes:

```bash
# Atualizar Traefik (via K3s)
sudo systemctl restart k3s

# Atualizar Rancher
helm upgrade rancher rancher-latest/rancher -n cattle-system

# Atualizar cert-manager
helm upgrade cert-manager jetstack/cert-manager -n cert-manager
```

---

**Autor:** Claude Code  
**Versão:** 2.0 (com Rancher)  
**Última atualização:** $(date +%Y-%m-%d)