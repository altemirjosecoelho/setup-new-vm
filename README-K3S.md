# Scripts de Instalação e Configuração do K3s

Este diretório contém scripts para instalar, configurar e gerenciar um cluster K3s com um container hello world.

## 📋 Pré-requisitos

- Sistema operacional Linux (Ubuntu/Debian recomendado)
- Acesso sudo
- Conexão com a internet
- Mínimo 2GB de RAM disponível
- Mínimo 10GB de espaço em disco

## 🚀 Scripts Disponíveis

### 1. `install-k3s-cluster.sh`
Script principal para instalar e configurar o K3s com um cluster hello world.

**Funcionalidades:**
- ✅ Instalação automática do K3s
- ✅ Detecção automática de arquitetura (AMD64/ARM64)
- ✅ Configuração do cluster Kubernetes
- ✅ Criação de namespace dedicado
- ✅ Deploy de container hello world
- ✅ Configuração de service NodePort
- ✅ Verificação de conectividade
- ✅ Logs coloridos e informativos

### 2. `uninstall-k3s.sh`
Script para desinstalar completamente o K3s e limpar todos os recursos.

**Funcionalidades:**
- ✅ Remoção de recursos Kubernetes
- ✅ Parada e desinstalação do K3s
- ✅ Limpeza de containers Docker
- ✅ Remoção de arquivos temporários
- ✅ Verificação de desinstalação

## 🛠️ Como Usar

### Instalação do K3s

```bash
# Tornar o script executável (se necessário)
chmod +x install-k3s-cluster.sh

# Executar a instalação
./install-k3s-cluster.sh
```

**O que o script fará:**
1. Verificar requisitos do sistema
2. Instalar dependências (curl, wget, git)
3. Detectar arquitetura do processador
4. Instalar K3s com suporte a Docker
5. Configurar o cluster Kubernetes
6. Criar namespace `hello-world`
7. Deployar container hello world
8. Configurar service NodePort na porta 30080
9. Verificar conectividade

### Desinstalação do K3s

```bash
# Tornar o script executável (se necessário)
chmod +x uninstall-k3s.sh

# Executar a desinstalação
./uninstall-k3s.sh
```

**O que o script fará:**
1. Confirmar com o usuário
2. Remover recursos Kubernetes
3. Parar e desinstalar K3s
4. Limpar containers Docker
5. Remover arquivos temporários
6. Verificar desinstalação

## 🌐 Acessando o Hello World

Após a instalação bem-sucedida, o container hello world estará disponível em:

```
http://<IP_DO_NODE>:30080
```

Para descobrir o IP do node:
```bash
kubectl get nodes -o wide
```

## 📊 Comandos Úteis

### Verificar Status do Cluster
```bash
# Informações do cluster
kubectl cluster-info

# Status dos nodes
kubectl get nodes -o wide

# Namespaces
kubectl get namespaces
```

### Gerenciar o Hello World
```bash
# Ver pods do hello world
kubectl get pods -n hello-world

# Logs do deployment
kubectl logs -f deployment/hello-world -n hello-world

# Status do service
kubectl get services -n hello-world

# Descrever o service
kubectl describe service hello-world-service -n hello-world
```

### Gerenciar o K3s
```bash
# Status do serviço K3s
sudo systemctl status k3s

# Parar K3s
sudo systemctl stop k3s

# Iniciar K3s
sudo systemctl start k3s

# Reiniciar K3s
sudo systemctl restart k3s
```

## 🔧 Configurações

### Kubeconfig
O arquivo de configuração do Kubernetes está localizado em:
```
/etc/rancher/k3s/k3s.yaml
```

Para usar o kubectl de outro computador:
```bash
# Copiar o kubeconfig
sudo cat /etc/rancher/k3s/k3s.yaml

# Ou configurar variável de ambiente
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
```

### Portas Utilizadas
- **30080**: Service NodePort do hello world
- **6443**: API Server do Kubernetes
- **10250**: Kubelet
- **2379-2380**: etcd (se usado)

## 🐛 Solução de Problemas

### K3s não inicia
```bash
# Verificar logs
sudo journalctl -u k3s -f

# Verificar status
sudo systemctl status k3s

# Reiniciar serviço
sudo systemctl restart k3s
```

### Pods não ficam prontos
```bash
# Verificar eventos
kubectl get events --sort-by='.lastTimestamp'

# Descrever pod com problema
kubectl describe pod <nome-do-pod> -n hello-world

# Verificar logs do pod
kubectl logs <nome-do-pod> -n hello-world
```

### Problemas de conectividade
```bash
# Verificar se o service está funcionando
kubectl get endpoints -n hello-world

# Testar conectividade interna
kubectl run test-pod --image=busybox --rm -it --restart=Never -- wget -O- http://hello-world-service:80

# Verificar firewall
sudo ufw status
```

## 📝 Logs e Monitoramento

### Logs do K3s
```bash
# Logs do sistema
sudo journalctl -u k3s -f

# Logs do containerd
sudo journalctl -u containerd -f
```

### Monitoramento de Recursos
```bash
# Uso de CPU e memória dos pods
kubectl top pods -n hello-world

# Uso de recursos dos nodes
kubectl top nodes
```

## 🔒 Segurança

### Recomendações
- ✅ Não execute como root (o script avisa se detectar)
- ✅ Mantenha o sistema atualizado
- ✅ Use namespaces para isolar aplicações
- ✅ Configure RBAC se necessário
- ✅ Monitore logs regularmente

### Firewall
Se estiver usando UFW:
```bash
# Permitir porta do hello world
sudo ufw allow 30080

# Permitir porta da API (se necessário)
sudo ufw allow 6443
```

## 📚 Recursos Adicionais

- [Documentação oficial do K3s](https://docs.k3s.io/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Rancher Documentation](https://docs.rancher.com/)

## 🤝 Contribuição

Para contribuir com melhorias nos scripts:
1. Teste em um ambiente limpo
2. Documente as mudanças
3. Mantenha compatibilidade com diferentes arquiteturas
4. Adicione tratamento de erros adequado

## 📄 Licença

Este projeto está sob a licença MIT. Veja o arquivo LICENSE para mais detalhes.

---

**Nota:** Estes scripts são destinados para uso em ambientes de desenvolvimento e teste. Para produção, considere configurações adicionais de segurança e alta disponibilidade. 