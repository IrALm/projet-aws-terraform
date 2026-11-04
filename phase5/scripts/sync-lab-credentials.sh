#!/usr/bin/env bash
# Copie les identifiants temporaires du lab AWS Academy (~/.aws/credentials, profil [default])
# dans les secrets GitHub Actions du dépôt. À relancer à chaque nouvelle session de lab :
# les identifiants AWS Academy expirent au bout de quelques heures.
#
# Prérequis : GitHub CLI installé et connecté (gh auth login).
# Usage (depuis la racine du dépôt) : bash phase5/scripts/sync-lab-credentials.sh

set -euo pipefail
CREDS="${AWS_SHARED_CREDENTIALS_FILE:-$HOME/.aws/credentials}"

command -v gh >/dev/null || { echo "GitHub CLI absent : https://cli.github.com (ou saisir les secrets à la main, voir phase5/README.md)" >&2; exit 1; }
gh auth status >/dev/null 2>&1 || { echo "GitHub CLI non connecté : lancer 'gh auth login'" >&2; exit 1; }
[[ -f "$CREDS" ]] || { echo "Fichier introuvable : $CREDS" >&2; exit 1; }

# Valeur d'une clé dans le profil [default]
get() {
  awk -F' *= *' -v key="$1" '
    /^\[/ { in_default = ($0 == "[default]") }
    in_default && $1 == key { print $2; exit }
  ' "$CREDS" | tr -d '\r'
}

for pair in AWS_ACCESS_KEY_ID:aws_access_key_id AWS_SECRET_ACCESS_KEY:aws_secret_access_key AWS_SESSION_TOKEN:aws_session_token; do
  secret="${pair%%:*}"; key="${pair##*:}"
  value="$(get "$key")"
  [[ -n "$value" ]] || { echo "Clé '$key' absente du profil [default] de $CREDS" >&2; exit 1; }
  # La valeur passe par l'entrée standard : elle n'apparaît pas dans la liste des processus
  printf '%s' "$value" | gh secret set "$secret"
  echo "Secret $secret mis à jour."
done

# Vérification : les identifiants copiés sont-ils encore valides ?
aws sts get-caller-identity --query Arn --output text >/dev/null \
  && echo "Identifiants valides. Relancer le pipeline : gh workflow run ci-cd.yml" \
  || echo "Attention : les identifiants locaux semblent expirés (refaire l'étape 'AWS Details' du lab)."
