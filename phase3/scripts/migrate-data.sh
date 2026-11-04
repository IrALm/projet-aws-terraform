#!/usr/bin/env bash
# Chargement des données dans la base RDS de la phase 3 (équivalent du "Script-3" du sujet).
# L'import passe par une des instances du groupe Auto Scaling, seules machines autorisées
# à joindre RDS (security group de la base).
#
# Usage (depuis le dossier phase3/, dans Git Bash / Linux / macOS) :
#   bash scripts/migrate-data.sh                      # source : VM de phase 1 (IP lue dans ../phase1)
#   bash scripts/migrate-data.sh 1.2.3.4              # source : VM de phase 1, IP donnée explicitement
#   bash scripts/migrate-data.sh --file chemin.sql    # source : export existant (ex. ../phase2/backup/*.sql)
#   bash scripts/migrate-data.sh --init               # pas de source : crée seulement la table vide

set -euo pipefail
cd "$(dirname "$0")/.."

SSH_KEY="${SSH_KEY:-$HOME/.ssh/id_ed25519_phase1}"
# Les IP des VM du lab changent à chaque recréation : on ne mémorise pas leurs empreintes
SSH_OPTS=(-i "$SSH_KEY" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR -o ConnectTimeout=15)

step() { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }
fail() { printf '\n\033[1;31mERREUR : %s\033[0m\n' "$*" >&2; exit 1; }
tf_out() { terraform output -raw "$1" 2>/dev/null | tr -d '\r'; }

# ---------- 0. Paramètres ----------
MODE="migrate"; SOURCE_IP=""; DUMP=""
case "${1:-}" in
  --init) MODE="init"; DUMP="scripts/init-db.sql" ;;
  --file) MODE="file"; DUMP="${2:-}"; [[ -f "$DUMP" ]] || fail "Fichier introuvable : '$DUMP'" ;;
  "")     SOURCE_IP="$(terraform -chdir=../phase1 output -raw public_ip 2>/dev/null | tr -d '\r' || true)"
          [[ "$SOURCE_IP" =~ ^[0-9.]+$ ]] || fail "VM de phase 1 introuvable dans ../phase1.
  - Donnez son IP :              bash scripts/migrate-data.sh <IP_PHASE1>
  - Ou un export existant :      bash scripts/migrate-data.sh --file ../phase2/backup/<fichier>.sql
  - Ou partez d'une base vide :  bash scripts/migrate-data.sh --init" ;;
  *)      SOURCE_IP="$1" ;;
esac

[[ -f "$SSH_KEY" ]] || fail "Clé SSH introuvable : $SSH_KEY (définir SSH_KEY=chemin/vers/cle)"

ASG_NAME="$(tf_out asg_name)"
SECRET_NAME="$(tf_out secret_name)"
REGION="$(tf_out aws_region)"
[[ -n "$ASG_NAME" && -n "$SECRET_NAME" ]] || fail "Outputs Terraform absents : lancez d'abord 'terraform apply' dans phase3/."

# ---------- 1. Choix d'une instance du groupe Auto Scaling ----------
step "Recherche d'une instance en service dans le groupe '$ASG_NAME'"
APP_IP=""
for _ in $(seq 1 30); do
  INSTANCE_ID="$(aws autoscaling describe-auto-scaling-groups --region "$REGION" --auto-scaling-group-names "$ASG_NAME" \
    --query "AutoScalingGroups[0].Instances[?LifecycleState=='InService'].InstanceId | [0]" --output text | tr -d '\r')"
  if [[ "$INSTANCE_ID" == i-* ]]; then
    APP_IP="$(aws ec2 describe-instances --region "$REGION" --instance-ids "$INSTANCE_ID" \
      --query "Reservations[0].Instances[0].PublicIpAddress" --output text | tr -d '\r')"
    break
  fi
  echo "  aucune instance en service pour l'instant, nouvelle tentative dans 20 s..."
  sleep 20
done
[[ "$APP_IP" =~ ^[0-9.]+$ ]] || fail "Aucune instance en service dans $ASG_NAME après 10 minutes."
echo "Instance utilisée : $INSTANCE_ID ($APP_IP)"

# ---------- 2. Identifiants depuis Secrets Manager ----------
step "Lecture du secret '$SECRET_NAME' dans Secrets Manager"
SECRET_JSON="$(aws secretsmanager get-secret-value --region "$REGION" --secret-id "$SECRET_NAME" \
  --query SecretString --output text | tr -d '\r')"
json_get() { sed -E "s/.*\"$1\":\"([^\"]*)\".*/\1/" <<<"$SECRET_JSON"; }
DB_HOST="$(json_get host)"; DB_USER="$(json_get user)"; DB_PASS="$(json_get password)"; DB_NAME="$(json_get db)"
echo "Base cible : $DB_NAME sur $DB_HOST (utilisateur $DB_USER)"

# ---------- 3. Instance prête ? ----------
step "Attente de la fin de l'installation de l'instance"
# Une instance est "InService" dès son lancement, avant même que SSH ne soit démarré : on réessaie.
for i in $(seq 1 20); do
  ssh "${SSH_OPTS[@]}" "ubuntu@$APP_IP" true 2>/dev/null && break
  [[ $i -eq 20 ]] && fail "SSH injoignable sur $APP_IP (votre IP a-t-elle changé ? voir terraform.tfvars)"
  echo "  SSH pas encore disponible, nouvelle tentative dans 15 s..."
  sleep 15
done
ssh "${SSH_OPTS[@]}" "ubuntu@$APP_IP" "cloud-init status --wait >/dev/null; command -v mysql >/dev/null" \
  || fail "L'instance n'est pas prête (mysql-client absent). Voir /var/log/cloud-init-output.log"
echo "Instance prête."

# Fichier d'options MySQL temporaire (droits 600), supprimé en sortie :
# le mot de passe n'apparaît ni dans la ligne de commande ni dans la liste des processus.
cleanup() { ssh "${SSH_OPTS[@]}" "ubuntu@$APP_IP" "rm -f ~/.my.cnf" 2>/dev/null || true; }
trap cleanup EXIT
printf '[client]\nhost=%s\nuser=%s\npassword=%s\n' "$DB_HOST" "$DB_USER" "$DB_PASS" \
  | ssh "${SSH_OPTS[@]}" "ubuntu@$APP_IP" "umask 077; cat > ~/.my.cnf"

# ---------- 4. Export depuis la phase 1 (si besoin) ----------
if [[ "$MODE" == "migrate" ]]; then
  mkdir -p backup
  DUMP="backup/students-$(date +%Y%m%d-%H%M%S).sql"
  step "Export de la base STUDENTS depuis la VM de phase 1 ($SOURCE_IP)"
  ssh "${SSH_OPTS[@]}" "ubuntu@$SOURCE_IP" \
    "sudo mysqldump --databases STUDENTS --single-transaction --set-gtid-purged=OFF --no-tablespaces" > "$DUMP" \
    || fail "Export impossible depuis $SOURCE_IP (VM de phase 1 démarrée ? SSH autorisé depuis votre IP ?)"
  echo "Sauvegarde locale : phase3/$DUMP ($(wc -c < "$DUMP" | tr -d ' ') octets)"
fi

# ---------- 5. Import dans RDS ----------
step "Import de '$DUMP' dans RDS"
ssh "${SSH_OPTS[@]}" "ubuntu@$APP_IP" "mysql" < "$DUMP" || fail "Import dans RDS échoué"

# ---------- 6. Vérification ----------
step "Vérification"
COUNT="$(ssh "${SSH_OPTS[@]}" "ubuntu@$APP_IP" "mysql -N -e 'SELECT COUNT(*) FROM $DB_NAME.students'" | tr -d '\r')"
printf '\n\033[1;32mOK : %s étudiant(s) dans la table %s.students sur RDS.\033[0m\n' "$COUNT" "$DB_NAME"
echo "Application : $(tf_out application_url)"
