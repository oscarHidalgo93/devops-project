#!/usr/bin/env bash
# Entorno de demostración del laboratorio en un cluster k3d local.
#
#   ./scripts/demo.sh up                 crea el cluster, despliega todo y espera a que esté listo
#   ./scripts/demo.sh status             muestra el estado de las Applications y las URLs
#   ./scripts/demo.sh kubeconfig [RUTA]  exporta el kubeconfig del cluster (para Lens, por ejemplo)
#   ./scripts/demo.sh down               borra el cluster
#
# Variables opcionales:
#   DEMO_REVISION      rama que despliega ArgoCD                 (por defecto: main)
#   DEMO_DOMAIN        dominio base de las URLs                  (por defecto: localtest.me)
#   DEMO_PORT          puerto local de la aplicación             (por defecto: 8080)
#   DEMO_API_PORT      puerto local del API server de Kubernetes (por defecto: 6550)
#   DEMO_WAIT_TIMEOUT  segundos de espera al despliegue          (por defecto: 600)
#   API_TOKEN          token de la API; si falta, se genera uno aleatorio
#
# Requisitos: docker, k3d, kubectl y helm.
set -euo pipefail

cd "$(dirname "$0")/.."

CLUSTER="${DEMO_CLUSTER:-devops-demo}"
REVISION="${DEMO_REVISION:-main}"
DOMAIN="${DEMO_DOMAIN:-localtest.me}"
PORT="${DEMO_PORT:-8080}"
API_PORT="${DEMO_API_PORT:-6550}"
WAIT_TIMEOUT="${DEMO_WAIT_TIMEOUT:-600}"

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

apps_ready() {
  # Listas cuando la raíz ya ha creado sus hijas y todas están Synced y Healthy.
  local states
  states=$("${KUBECTL[@]}" -n argocd get applications \
    -o jsonpath='{range .items[*]}{.status.sync.status}/{.status.health.status}{"\n"}{end}' 2>/dev/null) || return 1
  [ "$(grep -c . <<<"$states")" -gt 1 ] || return 1
  ! grep -qv '^Synced/Healthy$' <<<"$states"
}

wait_for_apps() {
  log "Esperando a que ArgoCD despliegue las Applications (máximo ${WAIT_TIMEOUT} s)"
  local deadline=$((SECONDS + WAIT_TIMEOUT))
  until apps_ready; do
    if [ "$SECONDS" -ge "$deadline" ]; then
      echo "Tiempo agotado. Estado actual:" >&2
      "${KUBECTL[@]}" get applications -n argocd >&2
      return 1
    fi
    sleep 10
  done
}

up() {
  require_tools

  if k3d cluster get "$CLUSTER" >/dev/null 2>&1; then
    echo "El cluster $CLUSTER ya existe. Bórralo antes con: $0 down" >&2
    exit 1
  fi

  # Ambos puertos se publican solo en 127.0.0.1: la demo y el API server no
  # quedan accesibles desde otras máquinas de la red.
  log "Creando el cluster k3d $CLUSTER"
  k3d cluster create "$CLUSTER" \
    --image "$K3S_IMAGE" \
    --api-port "127.0.0.1:${API_PORT}" \
    --port "127.0.0.1:${PORT}:80@loadbalancer" \
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

  wait_for_apps
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
  echo
  echo "Kubeconfig para Lens u otras herramientas: $0 kubeconfig [RUTA]"
}

kubeconfig() {
  # Contiene credenciales de administrador del cluster: no debe compartirse ni versionarse.
  local out="${1:-$HOME/.kube/${CONTEXT}.yaml}"
  mkdir -p "$(dirname "$out")"
  k3d kubeconfig get "$CLUSTER" > "$out"
  chmod 600 "$out" 2>/dev/null || true
  echo "Kubeconfig escrito en: $out"
}

down() {
  log "Borrando el cluster $CLUSTER"
  k3d cluster delete "$CLUSTER"
}

case "${1:-}" in
  up) up ;;
  status) status ;;
  kubeconfig) kubeconfig "${2:-}" ;;
  down) down ;;
  *) echo "Uso: $0 up|status|kubeconfig [RUTA]|down" >&2; exit 1 ;;
esac
