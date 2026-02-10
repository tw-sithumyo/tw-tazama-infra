#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KUBECONFIG_PATH="${KUBECONFIG:-$HOME/.kube/config}"

export KUBECONFIG="$KUBECONFIG_PATH"

echo "Using KUBECONFIG=$KUBECONFIG"
kubectl get nodes >/dev/null

echo "Applying base-utils (helm-enabled kustomize)"
kubectl kustomize --enable-helm "$ROOT_DIR/apps/base-utils" | kubectl apply -f -

echo "Applying remaining apps"
for app in \
  tazama-platform \
  tazama-config \
  tazama-auth \
  tazama-core \
  tazama-rules \
  tazama-relay \
  tazama-observability \
  tazama-ui \
  tazama-utils
  do
  echo "  - $app"
  kubectl apply -k "$ROOT_DIR/apps/$app"
done

echo "Deployment manifests applied. Current namespaces:"
kubectl get ns

echo "Top-level workload status in tazama namespace:"
kubectl -n tazama get deploy,sts,pod
