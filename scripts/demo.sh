#!/usr/bin/env bash
# Entorno de demostración del laboratorio en un cluster k3d local.
#
#   ./scripts/demo.sh up       crea el cluster y despliega todo con ArgoCD
#   ./scripts/demo.sh status   muestra el estado de las Applications y las URLs
#   ./scripts/demo.sh down     borra el cluster
#
# Variables opcionales:
#   DEMO_REVISION  rama que despliega ArgoCD          (por defecto: main)
#   DEMO_DOMAIN    dominio base de las URLs           (por defecto: localtest.me)
#   DEMO_PORT      puerto local publicado por k3d      (por defecto: 8080)
#   API_TOKEN      token de la API; si falta, se genera uno aleatorio
#
# Requisitos: docker, k3d, kubectl y helm.
set -euo pipefail

cd "$(dirname "$0")/.."

CLUSTER="${DEMO_CLUSTER:-devops-demo}"
REVISION="${DEMO_REVISION:-main}"
DOMAIN="${DEMO_DOMAIN:-localtest.me}"
PORT="${DEMO_PORT:-8080}"

REPO_URL="https://github.com/oscarHidalgo93/devops-project.git"
K3S_IMAGE="rancher/k3s:v1.36.3-k3s1"
ARGOCD_CHART_VERSION="10.3.0"

# Contexto explícito en cada llamada: el script no puede actuar sobre otro
# cluster aunque el contexto activo del usuario sea distinto.
CONTEXT="k3d-${CLUSTER}"
KUBECTL=(kubectl --context "$CONTEXT")
HELM=(helm --kube-context "$CONTEXT")

log() { printf '\n==> %s\n' "$*"; }

require_tools() {
  local missing=0
  for tool in docker k3d kubectl helm; do
    if ! command -v "$tool" >/dev/null 2>&1; then
      echo "Falta la herramienta: $tool" >&2
      missing=1
    fi
  done
  [ "$missing" -eq 0 ] || exit 1
  docker info >/dev/null 2>&1 || { echo "Docker no responde: ¿está arrancado?" >&2; exit 1; }
}

random_token() {
  # od lee exactamente 16 bytes y termina por sí solo. Un "head" que cerrara la
  # tubería antes de tiempo provocaría un SIGPIPE que, con pipefail, abortaría el script.
  od -An -tx1 -N16 /dev/urandom | tr -d ' \n'
}

up() {
  require_tools

  if k3d cluster get "$CLUSTER" >/dev/null 2>&1; then
    echo "El cluster $CLUSTER ya existe. Bórralo antes con: $0 down" >&2
    exit 1
  fi

  log "Creando el cluster k3d $CLUSTER"
  k3d cluster create "$CLUSTER" \
    --image "$K3S_IMAGE" \
    --port "${PORT}:80@loadbalancer" \
    --wait

  log "Instalando ArgoCD ${ARGOCD_CHART_VERSION}"
  helm repo add argo https://argoproj.github.io/argo-helm >/dev/null 2>&1 || true
  helm repo update argo >/dev/null
  "${HELM[@]}" install argocd argo/argo-cd \
    --namespace argocd --create-namespace \
    --version "$ARGOCD_CHART_VERSION" \
    -f infra/argocd/argocd-values.yaml \
    --set global.domain="argocd.${DOMAIN}" \
    --set server.ingress.enabled=true \
    --set server.ingress.ingressClassName=traefik \
    --wait --timeout 15m

  log "Creando el Secret de la API"
  "${KUBECTL[@]}" create namespace dev --dry-run=client -o yaml | "${KUBECTL[@]}" apply -f -
  "${KUBECTL[@]}" -n dev create secret generic python-api-python-app-secret \
    --from-literal=API_TOKEN="${API_TOKEN:-$(random_token)}" \
    --dry-run=client -o yaml | "${KUBECTL[@]}" apply -f -

  log "Aplicando la Application raíz (rama: ${REVISION})"
  "${KUBECTL[@]}" apply -f - <<EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: root
  namespace: argocd
spec:
  project: default
  source:
    repoURL: ${REPO_URL}
    targetRevision: ${REVISION}
    path: infra/argocd/apps
    helm:
      valuesObject:
        repoURL: ${REPO_URL}
        revision: ${REVISION}
        domain: ${DOMAIN}
  destination:
    server: https://kubernetes.default.svc
    namespace: argocd
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
EOF

  status
}

status() {
  log "Applications"
  "${KUBECTL[@]}" get applications -n argocd

  log "URLs"
  echo "Aplicación  http://web.${DOMAIN}:${PORT}"
  echo "API         http://web.${DOMAIN}:${PORT}/api/"
  echo "ArgoCD      http://argocd.${DOMAIN}:${PORT}   (usuario: admin)"
  echo
  echo "Contraseña de ArgoCD:"
  echo "  ${KUBECTL[*]} -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
}

down() {
  log "Borrando el cluster $CLUSTER"
  k3d cluster delete "$CLUSTER"
}

case "${1:-}" in
  up) up ;;
  status) status ;;
  down) down ;;
  *) echo "Uso: $0 up|status|down" >&2; exit 1 ;;
esac
