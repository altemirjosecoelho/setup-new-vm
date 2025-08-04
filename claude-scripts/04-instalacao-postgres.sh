#!/bin/bash

# 04 - Script de Instalação PostgreSQL
# Instala PostgreSQL com persistência e configurações de produção

set -e

# Configurações (modifique conforme necessário)
POSTGRES_PASSWORD=${POSTGRES_PASSWORD:-"PostgresAdmin123!"}
POSTGRES_DB=${POSTGRES_DB:-"app_database"}
POSTGRES_USER=${POSTGRES_USER:-"app_user"}
POSTGRES_USER_PASSWORD=${POSTGRES_USER_PASSWORD:-"AppUser123!"}

echo "🐘 [04] Instalando PostgreSQL..."
echo "   Banco de dados: $POSTGRES_DB"
echo "   Usuário da aplicação: $POSTGRES_USER"

# Configurar KUBECONFIG
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

# 1. Criar namespace para PostgreSQL
echo "📁 Criando namespace postgresql..."
sudo kubectl create namespace postgresql --dry-run=client -o yaml | sudo kubectl apply -f -

# 2. Criar PersistentVolume para PostgreSQL
echo "💾 Criando PersistentVolume para PostgreSQL..."
cat <<EOF | sudo kubectl apply -f -
apiVersion: v1
kind: PersistentVolume
metadata:
  name: postgres-pv
spec:
  capacity:
    storage: 10Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: local-storage
  hostPath:
    path: /var/lib/postgresql-data
    type: DirectoryOrCreate
EOF

# 3. Criar PersistentVolumeClaim
echo "📋 Criando PersistentVolumeClaim..."
cat <<EOF | sudo kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-pvc
  namespace: postgresql
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
  storageClassName: local-storage
EOF

# 4. Criar Secret com credenciais
echo "🔐 Criando Secret com credenciais..."
sudo kubectl create secret generic postgres-credentials \
  --namespace=postgresql \
  --from-literal=postgres-password="$POSTGRES_PASSWORD" \
  --from-literal=user-password="$POSTGRES_USER_PASSWORD" \
  --dry-run=client -o yaml | sudo kubectl apply -f -

# 5. Criar ConfigMap com configurações
echo "⚙️ Criando ConfigMap com configurações..."
cat <<EOF | sudo kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: postgres-config
  namespace: postgresql
data:
  POSTGRES_DB: "$POSTGRES_DB"
  POSTGRES_USER: "$POSTGRES_USER"
  PGDATA: "/var/lib/postgresql/data/pgdata"
EOF

# 6. Criar Deployment do PostgreSQL
echo "🚀 Criando Deployment do PostgreSQL..."
cat <<EOF | sudo kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres
  namespace: postgresql
spec:
  replicas: 1
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
      - name: postgres
        image: postgres:16-alpine
        ports:
        - containerPort: 5432
        env:
        - name: POSTGRES_PASSWORD
          valueFrom:
            secretKeyRef:
              name: postgres-credentials
              key: postgres-password
        - name: POSTGRES_DB
          valueFrom:
            configMapKeyRef:
              name: postgres-config
              key: POSTGRES_DB
        - name: POSTGRES_USER
          valueFrom:
            configMapKeyRef:
              name: postgres-config
              key: POSTGRES_USER
        - name: PGDATA
          valueFrom:
            configMapKeyRef:
              name: postgres-config
              key: PGDATA
        volumeMounts:
        - name: postgres-storage
          mountPath: /var/lib/postgresql/data
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
            - pg_isready
            - -U
            - $POSTGRES_USER
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          exec:
            command:
            - pg_isready
            - -U
            - $POSTGRES_USER
          initialDelaySeconds: 5
          periodSeconds: 5
      volumes:
      - name: postgres-storage
        persistentVolumeClaim:
          claimName: postgres-pvc
EOF

# 7. Criar Service
echo "🌐 Criando Service do PostgreSQL..."
cat <<EOF | sudo kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: postgres-service
  namespace: postgresql
spec:
  selector:
    app: postgres
  ports:
  - name: postgres
    port: 5432
    targetPort: 5432
  type: ClusterIP
EOF

# 8. Aguardar PostgreSQL ficar pronto
echo "⏳ Aguardando PostgreSQL ficar pronto..."
sudo kubectl -n postgresql rollout status deployment/postgres --timeout=300s

# 9. Verificar conexão e usuário
echo "👤 Verificando usuário da aplicação..."
sleep 10  # Aguardar um pouco mais para garantir que o PostgreSQL está totalmente inicializado

# O usuário já foi criado automaticamente pelo container PostgreSQL
sudo kubectl exec -n postgresql deployment/postgres -- psql -U $POSTGRES_USER -d $POSTGRES_DB -c "SELECT current_user, current_database();"

# 10. Verificar status
echo "🔍 Verificando status da instalação..."
echo "   PostgreSQL pods:"
sudo kubectl get pods -n postgresql
echo ""
echo "   PostgreSQL service:"
sudo kubectl get svc -n postgresql
echo ""
echo "   PersistentVolumes:"
sudo kubectl get pv | grep postgres

echo ""
echo "✅ [04] PostgreSQL instalado com sucesso!"
echo ""
echo "📋 Informações de conexão PostgreSQL:"
echo "   Host: postgres-service.postgresql.svc.cluster.local"
echo "   Porta: 5432"
echo "   Banco de dados: $POSTGRES_DB"
echo "   Usuário: $POSTGRES_USER"
echo "   Senha: $POSTGRES_PASSWORD"
echo ""
echo "⚠️  Notas importantes:"
echo "   - Os dados são persistidos em /var/lib/postgresql-data no host"
echo "   - Para conexões externas ao cluster, use port-forward:"
echo "     kubectl port-forward -n postgresql svc/postgres-service 5432:5432"
echo ""
echo "🔧 Comandos úteis:"
echo "   - Conectar ao PostgreSQL: kubectl exec -n postgresql -it deployment/postgres -- psql -U $POSTGRES_USER -d $POSTGRES_DB"
echo "   - Ver logs: kubectl logs -n postgresql deployment/postgres"
echo "   - Reiniciar: kubectl rollout restart deployment/postgres -n postgresql"
echo "   - Backup: kubectl exec -n postgresql deployment/postgres -- pg_dump -U $POSTGRES_USER $POSTGRES_DB > backup.sql"