#!/bin/bash

# 02 - Script de Instalação K3s + Traefik
# Instala K3s com Traefik e configura HTTPS com autenticação

set -e

# Configurações (modifique conforme necessário)
DOMAIN=${DOMAIN:-"traefik.testes.possoatender.com"}
EMAIL=${EMAIL:-"admin@possoatender.com"}
USERNAME=${USERNAME:-"admin"}
PASSWORD=${PASSWORD:-"ZX@geb0090"}

echo "🚀 [02] Instalando K3s com Traefik HTTPS..."
echo "   Domínio Traefik: $DOMAIN"
echo "   Email: $EMAIL"
echo "   Usuário: $USERNAME"

# 1. Instalar K3s
echo "🔧 Instalando K3s..."
curl -sfL https://get.k3s.io | sh -

# 2. Aguardar K3s ficar pronto
echo "⏳ Aguardando K3s ficar pronto..."
kubectl wait --for=condition=ready node --all --timeout=120s

# 3. Gerar senha hash para autenticação
echo "🔐 Gerando credenciais de autenticação..."
PASSWORD_HASH=$(htpasswd -nb "$USERNAME" "$PASSWORD")
PASSWORD_BASE64=$(echo "$PASSWORD_HASH" | base64 -w 0)

# 4. Criar diretório de manifestos
sudo mkdir -p /etc/rancher/k3s/server/manifests

# 5. Criar autenticação básica
cat <<EOF | sudo tee /etc/rancher/k3s/server/manifests/traefik-auth.yaml
---
apiVersion: v1
kind: Secret
metadata:
  name: traefik-basic-auth
  namespace: kube-system
data:
  users: $PASSWORD_BASE64
---
apiVersion: traefik.io/v1alpha1
kind: Middleware
metadata:
  name: traefik-basic-auth
  namespace: kube-system
spec:
  basicAuth:
    secret: traefik-basic-auth
EOF

# 6. Configurar dashboard com HTTPS e autenticação
cat <<EOF | sudo tee /etc/rancher/k3s/server/manifests/traefik-dashboard.yaml
---
apiVersion: v1
kind: Service
metadata:
  name: traefik-dashboard
  namespace: kube-system
spec:
  type: ClusterIP
  ports:
  - name: traefik
    port: 9000
    targetPort: traefik
  selector:
    app.kubernetes.io/instance: traefik-kube-system
    app.kubernetes.io/name: traefik
---
apiVersion: traefik.io/v1alpha1
kind: IngressRoute
metadata:
  name: traefik-dashboard
  namespace: kube-system
spec:
  entryPoints:
    - websecure
  routes:
  - match: Host(\`$DOMAIN\`)
    kind: Rule
    services:
    - name: api@internal
      kind: TraefikService
    middlewares:
    - name: traefik-basic-auth
  tls:
    certResolver: letsencrypt
EOF

# 7. Aguardar Traefik ficar pronto
echo "⏳ Aguardando Traefik ficar pronto..."
sleep 60
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=traefik -n kube-system --timeout=300s

# 8. Aguardar CRDs do Traefik ficarem disponíveis
echo "⏳ Aguardando CRDs do Traefik ficarem disponíveis..."
for i in {1..30}; do
    if kubectl get crd ingressroutes.traefik.io >/dev/null 2>&1; then
        echo "   CRDs do Traefik estão disponíveis!"
        break
    fi
    echo "   Aguardando CRDs... ($i/30)"
    sleep 5
done

# 9. Configurar HTTPS no Traefik via patch
echo "🔒 Configurando HTTPS automático..."
kubectl patch deployment traefik -n kube-system --type='json' -p='[
  {
    "op": "add",
    "path": "/spec/template/spec/containers/0/args/-",
    "value": "--certificatesresolvers.letsencrypt.acme.email='$EMAIL'"
  },
  {
    "op": "add", 
    "path": "/spec/template/spec/containers/0/args/-",
    "value": "--certificatesresolvers.letsencrypt.acme.storage=/data/acme.json"
  },
  {
    "op": "add",
    "path": "/spec/template/spec/containers/0/args/-", 
    "value": "--certificatesresolvers.letsencrypt.acme.tlschallenge=true"
  }
]'

# 10. Aguardar Traefik reiniciar
echo "⏳ Aguardando Traefik reiniciar..."
kubectl rollout status deployment traefik -n kube-system --timeout=300s
sleep 30

# 11. Verificar status
echo "🔍 Verificando status da instalação..."
echo "   Nodes:"
kubectl get nodes
echo ""
echo "   Pods do Traefik:"
kubectl get pods -n kube-system | grep traefik
echo ""
echo "   IngressRoutes:"
kubectl get ingressroute -n kube-system

echo ""
echo "✅ [02] K3s + Traefik instalado com sucesso!"
echo ""
echo "📋 Informações de acesso Traefik:"
echo "   URL: https://$DOMAIN/dashboard/"
echo "   Usuário: $USERNAME"
echo "   Senha: $PASSWORD"
echo ""
echo "⏭️  Execute o próximo script: ./03-instalacao-rancher.sh"