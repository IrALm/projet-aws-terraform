#!/usr/bin/env bash
# Construit l'image de l'application et la publie dans Amazon ECR.
#
# Usage (depuis le dossier phase4/, dans Git Bash / Linux / macOS) :
#   bash scripts/build-push.sh
#
# Tags publiés :
#   <sha du commit Git>  : tag immuable, permet de savoir exactement quel code tourne
#   latest               : utilisé par les instances au démarrage
# Prérequis : Docker démarré, registre créé (terraform apply dans phase4/registry).

set -euo pipefail
cd "$(dirname "$0")/.."

step() { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }
fail() { printf '\n\033[1;31mERREUR : %s\033[0m\n' "$*" >&2; exit 1; }

docker info >/dev/null 2>&1 || fail "Docker n'est pas démarré (lancer Docker Desktop)."

REPO_URL="$(terraform -chdir=registry output -raw repository_url 2>/dev/null | tr -d '\r' || true)"
REGION="$(terraform -chdir=registry output -raw aws_region 2>/dev/null | tr -d '\r' || true)"
[[ "$REPO_URL" == *.amazonaws.com/* ]] || fail "Registre introuvable : lancer d'abord 'terraform apply' dans phase4/registry."
REGISTRY="${REPO_URL%%/*}"

TAG="${TAG:-$(git rev-parse --short HEAD 2>/dev/null || date +%Y%m%d%H%M%S)}"
# Code modifié mais non commité : on le signale dans le tag
if git rev-parse --git-dir >/dev/null 2>&1 && [[ -n "$(git status --porcelain -- ../app Dockerfile 2>/dev/null)" ]]; then
  TAG="${TAG}-dirty"
fi

step "Construction de l'image ($REPO_URL:$TAG)"
# linux/amd64 : architecture des instances t3 (évite une image ARM construite sur un Mac M1/M2).
# --provenance/--sbom=false : manifeste simple (sans index d'attestations), seul format
# analysé par le scan de vulnérabilités ECR.
docker build --platform linux/amd64 --provenance=false --sbom=false -f Dockerfile -t "$REPO_URL:$TAG" -t "$REPO_URL:latest" ../app

step "Authentification auprès d'ECR ($REGISTRY)"
aws ecr get-login-password --region "$REGION" | docker login --username AWS --password-stdin "$REGISTRY"

step "Publication"
docker push "$REPO_URL:$TAG"
docker push "$REPO_URL:latest"

step "Analyse de vulnérabilités ECR (scan on push)"
REPO_NAME="${REPO_URL#*/}"
STATUS=""
for _ in $(seq 1 60); do   # jusqu'à 5 minutes
  STATUS="$(aws ecr describe-image-scan-findings --region "$REGION" --repository-name "$REPO_NAME" \
    --image-id imageTag="$TAG" --query "imageScanStatus.status" --output text 2>/dev/null | tr -d '\r' || true)"
  [[ "$STATUS" == "COMPLETE" || "$STATUS" == "FAILED" ]] && break
  sleep 5
done
if [[ "$STATUS" == "COMPLETE" ]]; then
  COUNTS="$(aws ecr describe-image-scan-findings --region "$REGION" --repository-name "$REPO_NAME" \
    --image-id imageTag="$TAG" --query "imageScanFindings.findingSeverityCounts" --output json | tr -d '\r\n ')"
  [[ "$COUNTS" == "{}" || "$COUNTS" == "null" ]] && echo "Aucune vulnérabilité détectée." || echo "Vulnérabilités par sévérité : $COUNTS"
else
  echo "Analyse non disponible (statut : ${STATUS:-absent}) : voir la console ECR."
fi

printf '\n\033[1;32mImage publiée : %s:%s (et :latest)\033[0m\n' "$REPO_URL" "$TAG"
