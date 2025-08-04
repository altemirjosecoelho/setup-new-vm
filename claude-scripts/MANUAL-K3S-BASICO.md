# Manual Rápido K3s - Conceitos Básicos

## 🏗️ **Hierarquia do Kubernetes/K3s**

```
🌐 CLUSTER (Fazenda)
├── 🖥️ NODE 1 (Servidor 1)
│   ├── 📦 POD (Container + recursos)
│   ├── 📦 POD 
│   └── 📦 POD
├── 🖥️ NODE 2 (Servidor 2)  
│   ├── 📦 POD
│   └── 📦 POD
└── 🖥️ NODE 3 (Servidor 3)
    └── 📦 POD
```

## 📖 **Conceitos Fundamentais**

### 🌐 **CLUSTER**
- **O que é:** Um conjunto de servidores trabalhando juntos
- **Analogia:** Uma fazenda com vários estábulos
- **Exemplo:** Seu ambiente K3s completo

### 🖥️ **NODE (Nó)**
- **O que é:** Um servidor físico ou virtual no cluster
- **Analogia:** Um estábulo na fazenda
- **Tipos:**
  - **Master Node:** Gerencia o cluster (seu servidor atual)
  - **Worker Node:** Executa as aplicações

### 📦 **POD**
- **O que é:** O equivalente mais próximo ao "container Docker"
- **Analogia:** Uma baia no estábulo
- **Conteúdo:** 1 ou mais containers + recursos compartilhados
- **Importante:** É a menor unidade que você pode criar/gerenciar

### 🚀 **DEPLOYMENT**
- **O que é:** Gerencia múltiplos PODs idênticos
- **Analogia:** Um rebanho de animais iguais
- **Função:** Garante que X PODs sempre estejam rodando

### 🌐 **SERVICE**
- **O que é:** Rede interna para acessar PODs
- **Analogia:** Endereço postal do estábulo
- **Função:** Load balancer interno entre PODs

### 🚪 **INGRESS**
- **O que é:** Entrada externa para o cluster (HTTPS/HTTP)
- **Analogia:** Portão principal da fazenda
- **No K3s:** Traefik faz esse papel

## 🐳 **Docker vs K3s - Equivalências**

| Docker | K3s/Kubernetes | Descrição |
|--------|----------------|-----------|
| `docker run` | `kubectl run` | Executar um container/pod |
| `docker ps` | `kubectl get pods` | Ver containers/pods rodando |
| `docker logs` | `kubectl logs` | Ver logs |
| `docker exec` | `kubectl exec` | Executar comando dentro |
| `docker-compose` | `kubectl apply -f` | Executar múltiplos serviços |
| Container | Pod | Unidade básica de execução |
| docker-compose.yml | manifest.yaml | Arquivo de configuração |

## 🛠️ **Comandos Básicos do K3s**

### 📋 **Ver Status do Cluster**
```bash
# Ver nós do cluster
kubectl get nodes

# Ver todos os pods
kubectl get pods -A

# Ver serviços
kubectl get services -A

# Status geral
kubectl cluster-info
```

### 🚀 **Executar Aplicações**

#### **Método 1: Comando direto (como docker run)**
```bash
# Executar um NGINX (equivalente a docker run nginx)
kubectl run meu-nginx --image=nginx --port=80

# Ver o pod criado
kubectl get pods

# Acessar logs (como docker logs)
kubectl logs meu-nginx

# Executar comando dentro (como docker exec)
kubectl exec -it meu-nginx -- bash
```

#### **Método 2: Arquivo YAML (como docker-compose)**
```bash
# Criar arquivo nginx.yaml
cat <<EOF > nginx.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  selector:
    app: nginx
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP
EOF

# Aplicar (como docker-compose up)
kubectl apply -f nginx.yaml

# Ver o que foi criado
kubectl get deployments
kubectl get pods
kubectl get services
```

### 🌐 **Expor Aplicação Externa (como Docker port)**

```bash
# Criar IngressRoute para acesso externo
cat <<EOF > nginx-ingress.yaml
apiVersion: traefik.io/v1alpha1
kind: IngressRoute
metadata:
  name: nginx-ingress
spec:
  entryPoints:
    - web
  routes:
  - match: Host(\`nginx.testes.possoatender.com\`)
    kind: Rule
    services:
    - name: nginx-service
      port: 80
EOF

kubectl apply -f nginx-ingress.yaml
```

## 🔍 **Como Adicionar um Novo Node**

### **Em outro servidor:**
```bash
# No servidor master (atual), pegar o token
sudo cat /var/lib/rancher/k3s/server/node-token

# No novo servidor, instalar K3s como agent
curl -sfL https://get.k3s.io | K3S_URL=https://SEU_IP_MASTER:6443 K3S_TOKEN=SEU_TOKEN sh -

# Ver o novo nó aparecer
kubectl get nodes
```

## 📊 **Namespaces - Organização**

```bash
# Ver namespaces (como pastas)
kubectl get namespaces

# Criar namespace
kubectl create namespace minha-app

# Executar pod em namespace específico
kubectl run meu-pod --image=nginx -n minha-app

# Ver pods de um namespace
kubectl get pods -n minha-app
```

## 🔧 **Comandos de Manutenção**

```bash
# Deletar pod
kubectl delete pod meu-nginx

# Deletar deployment
kubectl delete deployment nginx-deployment

# Deletar tudo de um arquivo
kubectl delete -f nginx.yaml

# Ver recursos consumidos
kubectl top nodes
kubectl top pods

# Descrever problemas
kubectl describe pod nome-do-pod
```

## 🎯 **Exemplo Prático Completo**

```bash
# 1. Criar uma aplicação web simples
kubectl run minha-web --image=nginx --port=80

# 2. Expor como serviço
kubectl expose pod minha-web --port=80 --type=ClusterIP

# 3. Criar acesso externo
cat <<EOF | kubectl apply -f -
apiVersion: traefik.io/v1alpha1
kind: IngressRoute
metadata:
  name: minha-web-ingress
spec:
  entryPoints:
    - web
  routes:
  - match: Host(\`minha-web.testes.possoatender.com\`)
    kind: Rule
    services:
    - name: minha-web
      port: 80
EOF

# 4. Testar acesso
curl -H "Host: minha-web.testes.possoatender.com" http://SEU_IP
```

## 💡 **Resumo para Iniciantes**

- **POD = Container Docker** (mais ou menos)
- **NODE = Servidor** onde os pods rodam
- **CLUSTER = Conjunto** de servidores
- **DEPLOYMENT = docker-compose** que garante que pods sempre rodem
- **SERVICE = Rede interna** entre pods
- **INGRESS = Porta de entrada** externa (HTTP/HTTPS)

**Dica:** Use o Rancher para visualizar tudo isso de forma gráfica! 🐄