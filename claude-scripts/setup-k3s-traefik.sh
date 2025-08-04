#!/bin/bash

# Script de instalação automática do K3s com Traefik HTTPS e autenticação
# Autor: Claude Code
# Data: $(date +%Y-%m-%d)

set -e

# Configurações (modifique conforme necessário)
DOMAIN=${DOMAIN:-"traefik.testes.possoatender.com"}
RANCHER_DOMAIN=${RANCHER_DOMAIN:-"rancher.testes.possoatender.com"}
EMAIL=${EMAIL:-"admin@possoatender.com"}
USERNAME=${USERNAME:-"admin"}
PASSWORD=${PASSWORD:-"ZX@geb0090"}
RANCHER_PASSWORD=${RANCHER_PASSWORD:-"RancherAdmin123!"}

echo "🚀 Iniciando instalação do K3s com Traefik HTTPS + Rancher..."
echo "   Domínio Traefik: $DOMAIN"
echo "   Domínio Rancher: $RANCHER_DOMAIN"
echo "   Email: $EMAIL"
echo "   Usuário: $USERNAME"

# Função para verificar se comando existe
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# 1. Limpar instalação existente do K3s
echo "🧹 Limpando instalação existente do K3s..."
if [ -f /usr/local/bin/k3s-uninstall.sh ]; then
    sudo /usr/local/bin/k3s-uninstall.sh
fi

# Limpeza adicional
sudo rm -rf /etc/ceph /etc/cni /etc/kubernetes /opt/cni /run/calico /run/flannel \
    /run/secrets/kubernetes.io /var/lib/calico /var/lib/cni /var/lib/etcd \
    /var/lib/kubelet /var/lib/weave /var/log/containers /var/log/pods /var/run/calico 2>/dev/null || true

echo "✅ Limpeza concluída"

# 2. Instalar dependências
echo "📦 Verificando dependências..."
if ! command_exists htpasswd; then
    echo "   Instalando apache2-utils..."
    sudo apt update && sudo apt install -y apache2-utils
fi

if ! command_exists helm; then
    echo "   Instalando Helm..."
    curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
    sudo apt-get update && sudo apt-get install -y helm
fi

# 3. Instalar K3s
echo "🔧 Instalando K3s..."
curl -sfL https://get.k3s.io | sh -

# 4. Aguardar K3s ficar pronto
echo "⏳ Aguardando K3s ficar pronto..."
sudo kubectl wait --for=condition=ready node --all --timeout=120s

# 5. Gerar senha hash
echo "🔐 Gerando credenciais de autenticação..."
PASSWORD_HASH=$(htpasswd -nb "$USERNAME" "$PASSWORD")
PASSWORD_BASE64=$(echo "$PASSWORD_HASH" | base64 -w 0)

# 6. Criar configuração do Traefik com HTTPS
echo "🔒 Configurando Traefik com HTTPS..."
sudo mkdir -p /etc/rancher/k3s/server/manifests

# Configuração do Traefik
cat <<EOF | sudo tee /etc/rancher/k3s/server/manifests/traefik-config.yaml
apiVersion: helm.cattle.io/v1
kind: HelmChartConfig
metadata:
  name: traefik
  namespace: kube-system
spec:
  valuesContent: |-
    additionalArguments:
      - "--api"
      - "--api.dashboard=true"
      - "--certificatesresolvers.letsencrypt.acme.email=$EMAIL"
      - "--certificatesresolvers.letsencrypt.acme.storage=/data/acme.json"
      - "--certificatesresolvers.letsencrypt.acme.tlschallenge=true"
      - "--entrypoints.web.http.redirections.entryPoint.to=websecure"
      - "--entrypoints.web.http.redirections.entryPoint.scheme=https"
      - "--entrypoints.web.http.redirections.entrypoint.permanent=true"
    ports:
      traefik:
        expose: true
    persistence:
      enabled: true
      storageClass: "local-path"
      size: 128Mi
    providers:
      kubernetesCRD:
        allowCrossNamespace: true
EOF

# 7. Criar autenticação básica
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

# 8. Configurar dashboard com HTTPS e autenticação
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

# 9. Aplicar configuração via patch do deployment (mais confiável que HelmChartConfig)
echo "⏳ Aplicando configuração de certificados via deployment patch..."
sudo kubectl patch deployment traefik -n kube-system --type='json' -p='[
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

echo "⏳ Aguardando Traefik reiniciar com nova configuração..."
sudo kubectl rollout status deployment traefik -n kube-system --timeout=300s
sleep 60

# 10. Instalar cert-manager para o Rancher
echo "🔐 Instalando cert-manager..."
sudo kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.14.4/cert-manager.crds.yaml
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.14.4

echo "⏳ Aguardando cert-manager ficar pronto..."
sudo kubectl wait --for=condition=ready pod -l app=cert-manager -n cert-manager --timeout=300s
sudo kubectl wait --for=condition=ready pod -l app=cainjector -n cert-manager --timeout=300s
sudo kubectl wait --for=condition=ready pod -l app=webhook -n cert-manager --timeout=300s

# 11. Instalar Rancher
echo "🐄 Instalando Rancher..."
helm repo add rancher-latest https://releases.rancher.com/server-charts/latest
helm repo update

# Criar namespace para o Rancher
sudo kubectl create namespace cattle-system

# Instalar Rancher com Let's Encrypt
helm install rancher rancher-latest/rancher \
  --namespace cattle-system \
  --set hostname=$RANCHER_DOMAIN \
  --set bootstrapPassword=$RANCHER_PASSWORD \
  --set ingress.tls.source=letsEncrypt \
  --set letsEncrypt.email=$EMAIL \
  --set letsEncrypt.ingress.class=traefik

echo "⏳ Aguardando Rancher ficar pronto..."
sudo kubectl -n cattle-system rollout status deploy/rancher --timeout=600s

# 12. Verificar status
echo "🔍 Verificando status da instalação..."
echo "   Nodes:"
sudo kubectl get nodes
echo ""
echo "   Pods do sistema:"
sudo kubectl get pods -n kube-system
echo ""
echo "   Serviços do Traefik:"
sudo kubectl get svc -n kube-system | grep traefik
echo ""
echo "   IngressRoutes:"
sudo kubectl get ingressroute -n kube-system
echo ""
echo "   Rancher status:"
sudo kubectl get pods -n cattle-system
echo ""
echo "   cert-manager status:"
sudo kubectl get pods -n cert-manager

# 13. Informações finais
echo ""
echo "🎉 Instalação concluída com sucesso!"
echo ""
echo "📋 Informações de acesso:"
echo ""
echo "🔧 Traefik Dashboard:"
echo "   URL: https://$DOMAIN/dashboard/"
echo "   Usuário: $USERNAME"
echo "   Senha: $PASSWORD"
echo ""
echo "🐄 Rancher Management:"
echo "   URL: https://$RANCHER_DOMAIN"
echo "   Usuário: admin"
echo "   Senha: $RANCHER_PASSWORD"
echo ""
echo "⚠️  Notas importantes:"
echo "   - Os certificados SSL serão gerados automaticamente pelo Let's Encrypt"
echo "   - Pode levar alguns minutos para os certificados ficarem disponíveis"
echo "   - Certifique-se de que o DNS dos domínios está apontando para este servidor"
echo "   - O Rancher pode levar até 10 minutos para ficar totalmente operacional"
echo ""
echo "🔧 Comandos úteis:"
echo "   - Ver logs do Traefik: kubectl logs -n kube-system deployment/traefik"
echo "   - Ver logs do Rancher: kubectl logs -n cattle-system deployment/rancher"
echo "   - Ver certificados: kubectl get certificates -A"
echo "   - Status do cluster: kubectl get all -A"
echo "   - Reiniciar Rancher: kubectl rollout restart deployment/rancher -n cattle-system"
echo ""