#!/usr/bin/env bash
# Test de charge de l'application (équivalent du "Script-2" du sujet) :
#   npm install -g loadtest ; loadtest --rps 1000 -c 500 -k http://<DNS de l'ALB>
# exécuté depuis le poste local (Cloud9 non disponible dans le lab), avec un suivi en direct
# de la mise à l'échelle : CPU moyen, instances désirées / en service, cibles saines de l'ALB.
#
# Usage (depuis le dossier phase3/, dans Git Bash / Linux) :
#   bash scripts/load-test.sh
# Paramètres optionnels (variables d'environnement) :
#   DURATION=600 RPS=1000 CONCURRENCY=500 bash scripts/load-test.sh
#
# Prérequis : Node.js (npx télécharge loadtest automatiquement, aucune installation globale).

set -euo pipefail
cd "$(dirname "$0")/.."

DURATION="${DURATION:-600}"        # secondes : laisse le temps au scale-out (alarme ~3 min + démarrage ~4 min)
RPS="${RPS:-1000}"                 # requêtes par seconde (valeur du Script-2)
CONCURRENCY="${CONCURRENCY:-500}"  # clients simultanés (valeur du Script-2)
LOADTEST_VERSION="8.2.1"

fail() { printf '\n\033[1;31mERREUR : %s\033[0m\n' "$*" >&2; exit 1; }
tf_out() { terraform output -raw "$1" 2>/dev/null | tr -d '\r'; }
aws_q() { aws "$@" --region "$REGION" --output text 2>/dev/null | tr -d '\r'; }

command -v npx >/dev/null || fail "Node.js est requis (https://nodejs.org) pour lancer loadtest."

URL="$(tf_out application_url)/"
ASG_NAME="$(tf_out asg_name)"
TG_ARN="$(tf_out target_group_arn)"
REGION="$(tf_out aws_region)"
[[ -n "$ASG_NAME" ]] || fail "Outputs Terraform absents : lancez d'abord 'terraform apply' dans phase3/."

curl -s -o /dev/null -w '%{http_code}' --max-time 10 "$URL" | grep -q 200 \
  || fail "L'application ne répond pas encore sur $URL (instances en cours de démarrage ?)"

status() {
  local asg cpu healthy
  asg="$(aws_q autoscaling describe-auto-scaling-groups --auto-scaling-group-names "$ASG_NAME" \
    --query "AutoScalingGroups[0].[DesiredCapacity, length(Instances[?LifecycleState=='InService'])]")"
  healthy="$(aws_q elbv2 describe-target-health --target-group-arn "$TG_ARN" \
    --query "length(TargetHealthDescriptions[?TargetHealth.State=='healthy'])")"
  cpu="$(aws_q cloudwatch get-metric-statistics --namespace AWS/EC2 --metric-name CPUUtilization \
    --dimensions Name=AutoScalingGroupName,Value="$ASG_NAME" --statistics Average --period 60 \
    --start-time "$(date -u -d '-3 min' +%Y-%m-%dT%H:%M:%SZ)" --end-time "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --query "sort_by(Datapoints,&Timestamp)[-1].Average")"
  [[ "$cpu" =~ ^[0-9.]+$ ]] && cpu="$(printf '%.0f %%' "$cpu")" || cpu="n/d"
  printf '%s | CPU moyen : %-6s | instances désirées / en service : %-7s | cibles saines ALB : %s\n' \
    "$(date +%H:%M:%S)" "$cpu" "$(tr '\t' '/' <<<"$asg")" "$healthy"
}

mkdir -p loadtest-results
LOG="loadtest-results/loadtest-$(date +%Y%m%d-%H%M%S).log"

printf '\033[1;34m==> Test de charge : %s req/s, %s clients, %s s sur %s\033[0m\n' "$RPS" "$CONCURRENCY" "$DURATION" "$URL"
echo "Sortie complète de loadtest : phase3/$LOG"
echo "Tableau de bord CloudWatch  : $(tf_out dashboard_url)"
echo
status

npx --yes "loadtest@${LOADTEST_VERSION}" --rps "$RPS" -c "$CONCURRENCY" -k -t "$DURATION" "$URL" > "$LOG" 2>&1 &
LT_PID=$!
trap 'kill $LT_PID 2>/dev/null || true' INT TERM EXIT

while kill -0 "$LT_PID" 2>/dev/null; do
  sleep 30
  status
done
wait "$LT_PID" || true
trap - INT TERM EXIT

printf '\n\033[1;34m==> Résultats de loadtest\033[0m\n'
grep -E "Target URL|Max time|Target rps|Concurrent clients|Completed requests|Total errors|Total time|Mean latency|Effective rps|50%|90%|95%|99%" "$LOG" | tail -14 || tail -20 "$LOG"

printf '\n\033[1;34m==> Activités de mise à l échelle (les plus récentes)\033[0m\n'
aws autoscaling describe-scaling-activities --region "$REGION" --auto-scaling-group-name "$ASG_NAME" --max-items 6 \
  --query "Activities[].[StartTime,StatusCode,Description]" --output table

echo
echo "Le retour à 2 instances (scale-in) intervient environ 15 minutes après la fin de la charge."
echo "Pour le suivre : relancer la commande ci-dessus, ou consulter le tableau de bord CloudWatch."
