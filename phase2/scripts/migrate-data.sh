#!/usr/bin/env bash
# Migration des données de la VM de la phase 1 (MySQL local) vers Amazon RDS.
# Équivalent automatisé du "Script-3" du sujet (mysqldump puis import dans RDS),
# exécuté depuis le poste local car Cloud9 n'est pas autorisé dans le lab.
#
# Usage (depuis le dossier phase2/, dans Git Bash / Linux / macOS) :
#   bash scripts/migrate-data.sh             # IP de la phase 1 lue dans ../phase1 (terraform output)
#   bash scripts/migrate-data.sh 1.2.3.4     # IP publique de la VM de phase 1 donnée explicitement
#   bash scripts/migrate-data.sh --init      # pas de phase 1 : crée seulement la table vide
#
# Fonctionnement :
#   1. le mot de passe RDS est lu dans Secrets Manager (jamais écrit dans un fichier versionné) ;
#   2. la base STUDENTS de la phase 1 est exportée via SSH (mysqldump) dans backup/ ;
#   3. le fichier est importé dans RDS depuis le serveur web (seul hôte autorisé à joindre RDS).

set -euo pipefail
cd "$(dirname "$0")/.."

SSH_KEY="${SSH_KEY:-$HOME/.ssh/id_ed25519_phase1}"
# Les IP des VM du lab changent à chaque recréation : on ne mémorise pas leurs empreintes
SSH_OPTS=(-i "$SSH_KEY" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR -o ConnectTimeout=15)

step() { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }
fail() { printf '\n\033[1;31mERREUR : %s\033[0m\n' "$*" >&2; exit 1; }
tf_out() { terraform output -raw "$1" 2>/dev/null | tr -d '\r'; }

# ---------- 0. Paramètres ----------
MODE="migrate"
SOURCE_IP=""
case "${1:-}" in
  --init) MODE="init" ;;
  "")     SOURCE_IP="$(terraform -chdir=../phase1 output -raw public_ip 2>/dev/null | tr -d '\r' || true)"
          [[ "$SOURCE_IP" =~ ^[0-9.]+$ ]] || fail "VM de phase 1 introuvable dans ../phase1.
  - Donnez son IP :            bash scripts/migrate-data.sh <IP_PHASE1>
  - Ou partez d'une base vide : bash scripts/migrate-data.sh --init" ;;
  *)      SOURCE_IP="$1" ;;
esac

[[ -f "$SSH_KEY" ]] || fail "Clé SSH introuvable : $SSH_KEY (définir SSH_KEY=chemin/vers/cle)"

APP_IP="$(tf_out public_ip)"
SECRET_NAME="$(tf_out secret_name)"
REGION="$(tf_out aws_region)"
[[ -n "$APP_IP" && -n "$SECRET_NAME" ]] || fail "Outputs Terraform absents : lancez d'abord 'terraform apply' dans phase2/."

# ---------- 1. Identifiants depuis Secrets Manager ----------
step "Lecture du secret '$SECRET_NAME' dans Secrets Manager"
SECRET_JSON="$(aws secretsmanager get-secret-value --region "$REGION" --secret-id "$SECRET_NAME" \
  --query SecretString --output text | tr -d '\r')"
json_get() { sed -E "s/.*\"$1\":\"([^\"]*)\".*/\1/" <<<"$SECRET_JSON"; }
DB_HOST="$(json_get host)"; DB_USER="$(json_get user)"; DB_PASS="$(json_get password)"; DB_NAME="$(json_get db)"
echo "Base cible : $DB_NAME sur $DB_HOST (utilisateur $DB_USER)"

# ---------- 2. Serveur web prêt ? ----------
step "Attente de la fin de l'installation du serveur web ($APP_IP)"
# Juste après l'apply, SSH n'est pas encore démarré sur l'instance : on réessaie.
for i in $(seq 1 20); do
  ssh "${SSH_OPTS[@]}" "ubuntu@$APP_IP" true 2>/dev/null && break
  [[ $i -eq 20 ]] && fail "SSH injoignable sur $APP_IP (votre IP a-t-elle changé ? voir terraform.tfvars)"
  echo "  SSH pas encore disponible, nouvelle tentative dans 15 s..."
  sleep 15
done
ssh "${SSH_OPTS[@]}" "ubuntu@$APP_IP" "cloud-init status --wait >/dev/null; command -v mysql >/dev/null" \
  || fail "Le serveur web n'est pas prêt (mysql-client absent). Voir /var/log/cloud-init-output.log"
echo "Serveur web prêt."

# Fichier d'options MySQL temporaire sur le serveur web (droits 600), supprimé en sortie :
# le mot de passe n'apparaît ni dans la ligne de commande ni dans la liste des processus.
cleanup() { ssh "${SSH_OPTS[@]}" "ubuntu@$APP_IP" "rm -f ~/.my.cnf" 2>/dev/null || true; }
trap cleanup EXIT
printf '[client]\nhost=%s\nuser=%s\npassword=%s\n' "$DB_HOST" "$DB_USER" "$DB_PASS" \
  | ssh "${SSH_OPTS[@]}" "ubuntu@$APP_IP" "umask 077; cat > ~/.my.cnf"

# ---------- 3. Export depuis la phase 1 (ou schéma vide) ----------
mkdir -p backup
if [[ "$MODE" == "migrate" ]]; then
  DUMP="backup/students-$(date +%Y%m%d-%H%M%S).sql"
  step "Export de la base STUDENTS depuis la VM de phase 1 ($SOURCE_IP)"
  ssh "${SSH_OPTS[@]}" "ubuntu@$SOURCE_IP" \
    "sudo mysqldump --databases STUDENTS --single-transaction --set-gtid-purged=OFF --no-tablespaces" > "$DUMP" \
    || fail "Export impossible depuis $SOURCE_IP (VM de phase 1 démarrée ? SSH autorisé depuis votre IP ?)"
  echo "Sauvegarde locale : phase2/$DUMP ($(wc -c < "$DUMP" | tr -d ' ') octets)"
else
  DUMP="scripts/init-db.sql"
  step "Création du schéma vide (pas de migration)"
fi

# ---------- 4. Import dans RDS ----------
step "Import dans RDS ($DB_HOST)"
ssh "${SSH_OPTS[@]}" "ubuntu@$APP_IP" "mysql" < "$DUMP" || fail "Import dans RDS échoué"

# ---------- 5. Vérification ----------
step "Vérification"
COUNT="$(ssh "${SSH_OPTS[@]}" "ubuntu@$APP_IP" "mysql -N -e 'SELECT COUNT(*) FROM $DB_NAME.students'" | tr -d '\r')"
printf '\n\033[1;32mOK : %s étudiant(s) dans la table %s.students sur RDS.\033[0m\n' "$COUNT" "$DB_NAME"
echo "Application : $(tf_out application_url)"
