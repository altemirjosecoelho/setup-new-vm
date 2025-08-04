#!/bin/bash

# Script de Limpeza de Pods - K3s + Traefik + Rancher
# Remove pods desnecessários mantendo apenas o essencial

set -e

export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

echo "🧹 Iniciando limpeza de pods..."
echo ""

# Mostrar status atual
echo "📊 Status atual:"
kubectl get pods -A --no-headers | wc -l | xargs echo "Total de pods:"

echo ""
echo "🗑️ Removendo jobs completados..."

# Remover jobs completados (seguro)
kubectl delete pods -n cattle-system --field-selector=status.phase=Succeeded 2>/dev/null || echo "   Nenhum job completado encontrado no cattle-system"
kubectl delete pods -n kube-system --field-selector=status.phase=Succeeded 2>/dev/null || echo "   Nenhum job completado encontrado no kube-system"

echo ""
echo "❓ Deseja remover componentes opcionais? (s/N)"
read -r resposta

if [[ $resposta =~ ^[Ss]$ ]]; then
    echo ""
    echo "🚀 Removendo Fleet (GitOps)..."
    kubectl delete namespace cattle-fleet-system 2>/dev/null || echo "   Fleet system já removido"
    kubectl delete namespace cattle-fleet-local-system 2>/dev/null || echo "   Fleet local já removido"
    
    echo ""
    echo "🔧 Removendo Cluster API..."
    kubectl delete namespace cattle-provisioning-capi-system 2>/dev/null || echo "   CAPI já removido"
    
    echo ""
    echo "🔄 Removendo auto-updater..."
    kubectl delete deployment system-upgrade-controller -n cattle-system 2>/dev/null || echo "   System upgrade controller já removido"
fi

echo ""
echo "✅ Limpeza concluída!"
echo ""

# Mostrar status final
echo "📊 Status final:"
kubectl get pods -A --no-headers | wc -l | xargs echo "Total de pods:"
echo ""

echo "🔍 Pods ativos por namespace:"
kubectl get pods -A --no-headers | cut -d' ' -f1 | sort | uniq -c | sort -nr

echo ""
echo "💡 Resumo da infraestrutura:"
echo "   ✅ kube-system: Core K3s + Traefik"
echo "   ✅ cert-manager: Certificados SSL"
echo "   ✅ cattle-system: Rancher Management"

if kubectl get namespace cattle-fleet-system &>/dev/null; then
    echo "   ❓ cattle-fleet-*: GitOps (opcional)"
fi

if kubectl get namespace cattle-provisioning-capi-system &>/dev/null; then
    echo "   ❓ cattle-provisioning-capi-system: Multi-cluster (opcional)"
fi

echo ""
echo "🌐 Acessos disponíveis:"
echo "   Traefik: https://traefik.testes.possoatender.com/dashboard/"
echo "   Rancher: https://rancher.testes.possoatender.com"