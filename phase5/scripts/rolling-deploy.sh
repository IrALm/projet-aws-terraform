#!/usr/bin/env bash
# Déploiement sans interruption : remplace toutes les instances du groupe Auto Scaling.
# Les nouvelles instances démarrent avec la dernière version du modèle de lancement et
# téléchargent l'image "latest" (qui vient d'être promue).
#
# L'API prévue pour cela (autoscaling:StartInstanceRefresh) est INTERDITE dans AWS Academy
# (politique de l'organisation). Le même résultat est obtenu avec des API autorisées :
#   1. augmenter la capacité désirée : de nouvelles instances sont lancées à côté des anciennes ;
#   2. attendre qu'elles soient déclarées saines par l'ALB ;
#   3. retirer les anciennes une par une (terminate-instance-in-auto-scaling-group) :
#      l'ASG les désinscrit de l'ALB et laisse finir les requêtes en cours (drainage) avant arrêt.
# La capacité saine ne descend jamais sous sa valeur initiale ("launch before terminate").
#
# Usage : bash rolling-deploy.sh <nom du groupe Auto Scaling>

set -euo pipefail
ASG="${1:?nom du groupe Auto Scaling}"
REGION="${AWS_REGION:-us-east-1}"
TIMEOUT_MIN="${TIMEOUT_MIN:-15}"   # délai maximal pour qu'un lot de nouvelles instances soit sain

asg() { aws autoscaling "$@" --region "$REGION" --output text | tr -d '\r'; }
log() { echo "$(date +%H:%M:%S)  $*"; }

read -r DESIRED MAX TG_ARN < <(asg describe-auto-scaling-groups --auto-scaling-group-names "$ASG" \
  --query 'AutoScalingGroups[0].[DesiredCapacity,MaxSize,TargetGroupARNs[0]]')
[[ "$DESIRED" =~ ^[0-9]+$ ]] || { echo "Groupe Auto Scaling $ASG introuvable" >&2; exit 1; }

healthy() {
  aws elbv2 describe-target-health --region "$REGION" --target-group-arn "$TG_ARN" \
    --query "length(TargetHealthDescriptions[?TargetHealth.State=='healthy'])" --output text | tr -d '\r'
}

# Instances à remplacer : toutes celles en service au lancement du script
read -r -a OLD < <(asg describe-auto-scaling-groups --auto-scaling-group-names "$ASG" \
  --query "AutoScalingGroups[0].Instances[?LifecycleState=='InService'].InstanceId")
log "Groupe $ASG : capacité $DESIRED, maximum $MAX, ${#OLD[@]} instance(s) à remplacer : ${OLD[*]}"

while (( ${#OLD[@]} > 0 )); do
  CURRENT="$(asg describe-auto-scaling-groups --auto-scaling-group-names "$ASG" --query 'AutoScalingGroups[0].DesiredCapacity')"
  ROOM=$(( MAX - CURRENT ))
  if (( ROOM <= 0 )); then
    # Groupe déjà au maximum (ex. pendant un pic) : on libère une place en retirant une ancienne instance
    log "Capacité maximale atteinte : retrait préalable de ${OLD[0]} (capacité réduite d'une instance quelques minutes)"
    asg terminate-instance-in-auto-scaling-group --instance-id "${OLD[0]}" --should-decrement-desired-capacity >/dev/null
    OLD=("${OLD[@]:1}")
    continue
  fi
  BATCH=$(( ROOM < ${#OLD[@]} ? ROOM : ${#OLD[@]} ))
  TARGET=$(( CURRENT + BATCH ))

  log "Lancement de $BATCH nouvelle(s) instance(s) : capacité $CURRENT -> $TARGET"
  asg set-desired-capacity --auto-scaling-group-name "$ASG" --desired-capacity "$TARGET" >/dev/null

  deadline=$(( $(date +%s) + TIMEOUT_MIN * 60 ))
  until (( $(healthy) >= TARGET )); do
    (( $(date +%s) < deadline )) || {
      log "ÉCHEC : les nouvelles instances ne sont pas saines après $TIMEOUT_MIN min. Retour à la capacité $CURRENT."
      asg set-desired-capacity --auto-scaling-group-name "$ASG" --desired-capacity "$CURRENT" >/dev/null
      exit 1
    }
    log "  cibles saines : $(healthy) / $TARGET"
    sleep 15
  done
  log "Nouvelles instances saines ($TARGET cibles). Retrait de $BATCH ancienne(s) instance(s) avec drainage."

  for ((i = 0; i < BATCH; i++)); do
    asg terminate-instance-in-auto-scaling-group --instance-id "${OLD[0]}" --should-decrement-desired-capacity >/dev/null
    log "  ${OLD[0]} : désinscription de l'ALB, puis arrêt"
    OLD=("${OLD[@]:1}")
  done
done

log "Déploiement terminé : toutes les instances ont été remplacées. Cibles saines : $(healthy)"
