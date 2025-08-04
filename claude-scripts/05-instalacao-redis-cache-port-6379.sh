#!/bin/bash

# 05 - Script de Instalação Redis Cache (Porta 6379)
# Instala Redis para cache temporário sem persistência

set -e

# Configurações (modifique conforme necessário)
REDIS_PASSWORD=${REDIS_PASSWORD:-"RedisCache123!"}

echo "🔴 [05] Instalando Redis Cache (Porta 6379)..."
echo "   Tipo: Cache temporário (sem persistência)"
echo "   Porta: 6379"

# Configurar KUBECONFIG
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

# 1. Criar namespace para Redis Cache
echo "📁 Criando namespace redis-cache..."
sudo kubectl create namespace redis-cache --dry-run=client -o yaml | sudo kubectl apply -f -

# 2. Criar Secret com senha
echo "🔐 Criando Secret com credenciais..."
sudo kubectl create secret generic redis-cache-credentials \
  --namespace=redis-cache \
  --from-literal=redis-password="$REDIS_PASSWORD" \
  --dry-run=client -o yaml | sudo kubectl apply -f -

# 3. Criar ConfigMap com configurações
echo "⚙️ Criando ConfigMap com configurações..."
cat <<EOF | sudo kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: redis-cache-config
  namespace: redis-cache
data:
  redis.conf: |
    # Configurações do Redis Cache
    bind 0.0.0.0
    port 6379
    timeout 0
    tcp-keepalive 300
    
    # Configurações de memória para cache
    maxmemory 512mb
    maxmemory-policy allkeys-lru
    
    # Desabilitar persistência (cache temporário)
    save ""
    stop-writes-on-bgsave-error no
    
    # Configurações de performance
    tcp-backlog 511
    databases 16
    
    # Logs
    loglevel notice
    
    # Configurações de segurança
    protected-mode yes
    requirepass REDIS_PASSWORD_PLACEHOLDER
EOF

# 4. Criar Deployment do Redis Cache
echo "🚀 Criando Deployment do Redis Cache..."
cat <<EOF | sudo kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: redis-cache
  namespace: redis-cache
spec:
  replicas: 1
  selector:
    matchLabels:
      app: redis-cache
  template:
    metadata:
      labels:
        app: redis-cache
    spec:
      containers:
      - name: redis
        image: redis:7-alpine
        ports:
        - containerPort: 6379
        command:
        - redis-server
        args:
        - /etc/redis/redis.conf
        - --requirepass
        - \$(REDIS_PASSWORD)
        env:
        - name: REDIS_PASSWORD
          valueFrom:
            secretKeyRef:
              name: redis-cache-credentials
              key: redis-password
        volumeMounts:
        - name: redis-config
          mountPath: /etc/redis
          readOnly: true
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          exec:
            command:
            - redis-cli
            - -a
            - \$(REDIS_PASSWORD)
            - ping
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          exec:
            command:
            - redis-cli
            - -a
            - \$(REDIS_PASSWORD)
            - ping
          initialDelaySeconds: 5
          periodSeconds: 5
      volumes:
      - name: redis-config
        configMap:
          name: redis-cache-config
          items:
          - key: redis.conf
            path: redis.conf
EOF

# 5. Criar Service
echo "🌐 Criando Service do Redis Cache..."
cat <<EOF | sudo kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: redis-cache-service
  namespace: redis-cache
spec:
  selector:
    app: redis-cache
  ports:
  - name: redis
    port: 6379
    targetPort: 6379
  type: ClusterIP
EOF

# 6. Aguardar Redis ficar pronto
echo "⏳ Aguardando Redis Cache ficar pronto..."
sudo kubectl -n redis-cache rollout status deployment/redis-cache --timeout=300s

# 7. Verificar status
echo "🔍 Verificando status da instalação..."
echo "   Redis Cache pods:"
sudo kubectl get pods -n redis-cache
echo ""
echo "   Redis Cache service:"
sudo kubectl get svc -n redis-cache
echo ""

# 8. Testar conexão
echo "🧪 Testando conexão com Redis Cache..."
sleep 5
sudo kubectl exec -n redis-cache deployment/redis-cache -- redis-cli -a "$REDIS_PASSWORD" ping

echo ""
echo "✅ [05] Redis Cache instalado com sucesso!"
echo ""
echo "📋 Informações de conexão Redis Cache:"
echo "   Host: redis-cache-service.redis-cache.svc.cluster.local"
echo "   Porta: 6379"
echo "   Senha: $REDIS_PASSWORD"
echo "   Tipo: Cache temporário (sem persistência)"
echo "   Política de memória: allkeys-lru"
echo "   Memória máxima: 512MB"
echo ""
echo "⚠️  Notas importantes:"
echo "   - Este Redis NÃO persiste dados (cache temporário)"
echo "   - Dados são perdidos quando o pod reinicia"
echo "   - Usar para cache de sessões, cache de aplicação, etc."
echo "   - Para conexões externas ao cluster, use port-forward:"
echo "     kubectl port-forward -n redis-cache svc/redis-cache-service 6379:6379"
echo ""
echo "🔧 Comandos úteis:"
echo "   - Conectar ao Redis: kubectl exec -n redis-cache -it deployment/redis-cache -- redis-cli -a $REDIS_PASSWORD"
echo "   - Ver logs: kubectl logs -n redis-cache deployment/redis-cache"
echo "   - Reiniciar: kubectl rollout restart deployment/redis-cache -n redis-cache"
echo "   - Monitorar: kubectl exec -n redis-cache deployment/redis-cache -- redis-cli -a $REDIS_PASSWORD monitor"
echo "   - Info: kubectl exec -n redis-cache deployment/redis-cache -- redis-cli -a $REDIS_PASSWORD info"