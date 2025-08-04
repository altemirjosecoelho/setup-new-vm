#!/bin/bash

# 03 - Script de Instalação Rancher
# Instala cert-manager e Rancher com HTTPS

set -e

# Configurações (modifique conforme necessário)
RANCHER_DOMAIN=${RANCHER_DOMAIN:-"rancher.testes.possoatender.com"}
EMAIL=${EMAIL:-"admin@possoatender.com"}
RANCHER_PASSWORD=${RANCHER_PASSWORD:-"RancherAdmin123!"}

echo "🐄 [03] Instalando Rancher Management..."
echo "   Domínio Rancher: $RANCHER_DOMAIN"
echo "   Email: $EMAIL"
echo "   Senha: $RANCHER_PASSWORD"

# Configurar KUBECONFIG
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

# 1. Instalar cert-manager
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

# 2. Instalar Rancher
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

# 3. Verificar status
echo "🔍 Verificando status da instalação..."
echo "   Rancher pods:"
sudo kubectl get pods -n cattle-system
echo ""
echo "   cert-manager pods:"
sudo kubectl get pods -n cert-manager
echo ""
echo "   Certificados:"
sudo kubectl get certificates -A

echo ""
echo "✅ [03] Rancher instalado com sucesso!"
echo ""
echo "📋 Informações de acesso Rancher:"
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
echo "   - Ver logs do Rancher: kubectl logs -n cattle-system deployment/rancher"
echo "   - Ver certificados: kubectl get certificates -A"
echo "   - Status do cluster: kubectl get all -A"
echo "   - Reiniciar Rancher: kubectl rollout restart deployment/rancher -n cattle-system"