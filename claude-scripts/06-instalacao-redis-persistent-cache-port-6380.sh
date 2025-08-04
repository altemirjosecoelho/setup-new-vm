#!/bin/bash

# 06 - Script de Instalação Redis Persistent Cache (Porta 6380)
# Instala Redis para dados persistentes com backup

set -e

# Configurações (modifique conforme necessário)
REDIS_PASSWORD=${REDIS_PASSWORD:-"RedisPersistent123!"}

echo "🔴 [06] Instalando Redis Persistent Cache (Porta 6380)..."
echo "   Tipo: Cache persistente com backup"
echo "   Porta: 6380"

# Configurar KUBECONFIG
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

# 1. Criar namespace para Redis Persistent
echo "📁 Criando namespace redis-persistent..."
sudo kubectl create namespace redis-persistent --dry-run=client -o yaml | sudo kubectl apply -f -

# 2. Criar PersistentVolume para Redis
echo "💾 Criando PersistentVolume para Redis Persistent..."
cat <<EOF | sudo kubectl apply -f -
apiVersion: v1
kind: PersistentVolume
metadata:
  name: redis-persistent-pv
spec:
  capacity:
    storage: 5Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: local-storage
  hostPath:
    path: /var/lib/redis-persistent-data
    type: DirectoryOrCreate
EOF

# 3. Criar PersistentVolumeClaim
echo "📋 Criando PersistentVolumeClaim..."
cat <<EOF | sudo kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: redis-persistent-pvc
  namespace: redis-persistent
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
  storageClassName: local-storage
EOF

# 4. Criar Secret com senha
echo "🔐 Criando Secret com credenciais..."
sudo kubectl create secret generic redis-persistent-credentials \
  --namespace=redis-persistent \
  --from-literal=redis-password="$REDIS_PASSWORD" \
  --dry-run=client -o yaml | sudo kubectl apply -f -

# 5. Criar ConfigMap com configurações
echo "⚙️ Criando ConfigMap com configurações..."
cat <<EOF | sudo kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: redis-persistent-config
  namespace: redis-persistent
data:
  redis.conf: |
    # Configurações do Redis Persistent
    bind 0.0.0.0
    port 6380
    timeout 0
    tcp-keepalive 300
    
    # Configurações de memória
    maxmemory 1gb
    maxmemory-policy allkeys-lru
    
    # Configurações de persistência
    save 900 1
    save 300 10
    save 60 10000
    stop-writes-on-bgsave-error yes
    rdbcompression yes
    rdbchecksum yes
    dbfilename dump.rdb
    dir /data
    
    # AOF (Append Only File) para maior durabilidade
    appendonly yes
    appendfilename "appendonly.aof"
    appendfsync everysec
    no-appendfsync-on-rewrite no
    auto-aof-rewrite-percentage 100
    auto-aof-rewrite-min-size 64mb
    
    # Configurações de performance
    tcp-backlog 511
    databases 16
    
    # Logs
    loglevel notice
    
    # Configurações de segurança
    protected-mode yes
    requirepass REDIS_PASSWORD_PLACEHOLDER
EOF

# 6. Criar Deployment do Redis Persistent
echo "🚀 Criando Deployment do Redis Persistent..."
cat <<EOF | sudo kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: redis-persistent
  namespace: redis-persistent
spec:
  replicas: 1
  selector:
    matchLabels:
      app: redis-persistent
  template:
    metadata:
      labels:
        app: redis-persistent
    spec:
      containers:
      - name: redis
        image: redis:7-alpine
        ports:
        - containerPort: 6380
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
              name: redis-persistent-credentials
              key: redis-password
        volumeMounts:
        - name: redis-config
          mountPath: /etc/redis
          readOnly: true
        - name: redis-data
          mountPath: /data
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "1Gi"
            cpu: "500m"
        livenessProbe:
          exec:
            command:
            - redis-cli
            - -p
            - "6380"
            - -a
            - \$(REDIS_PASSWORD)
            - ping
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          exec:
            command:
            - redis-cli
            - -p
            - "6380"
            - -a
            - \$(REDIS_PASSWORD)
            - ping
          initialDelaySeconds: 5
          periodSeconds: 5
      volumes:
      - name: redis-config
        configMap:
          name: redis-persistent-config
          items:
          - key: redis.conf
            path: redis.conf
      - name: redis-data
        persistentVolumeClaim:
          claimName: redis-persistent-pvc
EOF

# 7. Criar Service
echo "🌐 Criando Service do Redis Persistent..."
cat <<EOF | sudo kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: redis-persistent-service
  namespace: redis-persistent
spec:
  selector:
    app: redis-persistent
  ports:
  - name: redis
    port: 6380
    targetPort: 6380
  type: ClusterIP
EOF

# 8. Aguardar Redis ficar pronto
echo "⏳ Aguardando Redis Persistent ficar pronto..."
sudo kubectl -n redis-persistent rollout status deployment/redis-persistent --timeout=300s

# 9. Verificar status
echo "🔍 Verificando status da instalação..."
echo "   Redis Persistent pods:"
sudo kubectl get pods -n redis-persistent
echo ""
echo "   Redis Persistent service:"
sudo kubectl get svc -n redis-persistent
echo ""
echo "   PersistentVolumes:"
sudo kubectl get pv | grep redis-persistent

# 10. Testar conexão
echo "🧪 Testando conexão com Redis Persistent..."
sleep 5
sudo kubectl exec -n redis-persistent deployment/redis-persistent -- redis-cli -p 6380 -a "$REDIS_PASSWORD" ping

# 11. Testar persistência
echo "🧪 Testando persistência de dados..."
sudo kubectl exec -n redis-persistent deployment/redis-persistent -- redis-cli -p 6380 -a "$REDIS_PASSWORD" set test_key "test_value"
sudo kubectl exec -n redis-persistent deployment/redis-persistent -- redis-cli -p 6380 -a "$REDIS_PASSWORD" get test_key

echo ""
echo "✅ [06] Redis Persistent Cache instalado com sucesso!"
echo ""
echo "📋 Informações de conexão Redis Persistent:"
echo "   Host: redis-persistent-service.redis-persistent.svc.cluster.local"
echo "   Porta: 6380"
echo "   Senha: $REDIS_PASSWORD"
echo "   Tipo: Cache persistente com backup"
echo "   Política de memória: allkeys-lru"
echo "   Memória máxima: 1GB"
echo ""
echo "⚠️  Notas importantes:"
echo "   - Este Redis PERSISTE dados no disco"
echo "   - Dados são mantidos mesmo quando o pod reinicia"
echo "   - Backup automático: RDB + AOF habilitados"
echo "   - Dados salvos em /var/lib/redis-persistent-data no host"
echo "   - Para conexões externas ao cluster, use port-forward:"
echo "     kubectl port-forward -n redis-persistent svc/redis-persistent-service 6380:6380"
echo ""
echo "🔧 Comandos úteis:"
echo "   - Conectar ao Redis: kubectl exec -n redis-persistent -it deployment/redis-persistent -- redis-cli -p 6380 -a $REDIS_PASSWORD"
echo "   - Ver logs: kubectl logs -n redis-persistent deployment/redis-persistent"
echo "   - Reiniciar: kubectl rollout restart deployment/redis-persistent -n redis-persistent"
echo "   - Monitorar: kubectl exec -n redis-persistent deployment/redis-persistent -- redis-cli -p 6380 -a $REDIS_PASSWORD monitor"
echo "   - Info: kubectl exec -n redis-persistent deployment/redis-persistent -- redis-cli -p 6380 -a $REDIS_PASSWORD info"
echo "   - Backup manual: kubectl exec -n redis-persistent deployment/redis-persistent -- redis-cli -p 6380 -a $REDIS_PASSWORD bgsave"
echo "   - Verificar último save: kubectl exec -n redis-persistent deployment/redis-persistent -- redis-cli -p 6380 -a $REDIS_PASSWORD lastsave"