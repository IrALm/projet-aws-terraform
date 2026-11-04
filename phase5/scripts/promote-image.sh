#!/usr/bin/env bash
# Ajoute un tag (ex. "latest") à une image déjà présente dans ECR, sans la retélécharger.
# Seule une image qui a passé les tests de qualité ET le test de charge est promue :
# tant que ce n'est pas le cas, "latest" (utilisé par les instances) désigne l'ancienne version.
#
# Usage : bash promote-image.sh <dépôt> <tag source> <tag cible>
#   ex.   bash promote-image.sh universite-exemple-app 1a2b3c4 latest

set -euo pipefail
REPO="${1:?dépôt ECR}"; SRC="${2:?tag source}"; DST="${3:?tag cible}"
REGION="${AWS_REGION:-us-east-1}"

# Le manifeste doit être republié À L'OCTET PRÈS, sinon ECR calcule une autre empreinte
# (digest) et "latest" ne désigne plus exactement l'image testée. Sous Windows, l'AWS CLI
# convertit les fins de ligne en \r\n : on les retire.
MEDIA_TYPE="$(aws ecr batch-get-image --region "$REGION" --repository-name "$REPO" \
  --image-ids imageTag="$SRC" --query 'images[0].imageManifestMediaType' --output text | tr -d '\r')"
MANIFEST="$(aws ecr batch-get-image --region "$REGION" --repository-name "$REPO" \
  --image-ids imageTag="$SRC" --query 'images[0].imageManifest' --output text | tr -d '\r')"
[[ -n "$MANIFEST" && "$MANIFEST" != "None" ]] || { echo "Image $REPO:$SRC introuvable" >&2; exit 1; }

if OUT="$(aws ecr put-image --region "$REGION" --repository-name "$REPO" --image-tag "$DST" \
      --image-manifest "$MANIFEST" --image-manifest-media-type "$MEDIA_TYPE" 2>&1)"; then
  echo "$REPO:$SRC promue en $REPO:$DST"
elif grep -q ImageAlreadyExistsException <<<"$OUT"; then
  echo "$REPO:$DST désigne déjà cette image (rien à faire)"
else
  echo "$OUT" >&2; exit 1
fi

# Vérification : les deux tags doivent désigner la même empreinte
digest() {
  aws ecr describe-images --region "$REGION" --repository-name "$REPO" --image-ids imageTag="$1" \
    --query 'imageDetails[0].imageDigest' --output text | tr -d '\r'
}
SRC_DIGEST="$(digest "$SRC")"; DST_DIGEST="$(digest "$DST")"
if [[ "$SRC_DIGEST" != "$DST_DIGEST" ]]; then
  echo "Empreintes différentes : $SRC=$SRC_DIGEST, $DST=$DST_DIGEST" >&2
  exit 1
fi
echo "Empreinte : $DST_DIGEST"
