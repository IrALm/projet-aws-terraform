#!/usr/bin/env bash
# Test fonctionnel automatique de l'application (affichage, ajout, modification, suppression).
# Utilisable contre n'importe quel déploiement : conteneur local, ALB AWS, pipeline CI/CD.
#
# Usage : bash scripts/test-app.sh <URL>      ex. http://localhost:8080
# Code de sortie : 0 si tous les tests passent, 1 sinon.

set -uo pipefail
URL="${1:?Usage : bash scripts/test-app.sh <URL>}"
URL="${URL%/}"
NAME="Test-CI-$(date +%s)-$RANDOM"   # nom unique : plusieurs exécutions ne se gênent pas
PASS=0; FAILED=0

ok()   { printf '  \033[32mOK\033[0m   %s\n' "$*"; PASS=$((PASS + 1)); }
ko()   { printf '  \033[31mECHEC\033[0m %s\n' "$*"; FAILED=$((FAILED + 1)); }
code() { curl -s -o /dev/null -w '%{http_code}' --max-time 15 "$@"; }
list() { curl -s --max-time 15 "$URL/students/"; }

echo "Test de $URL"

# Attente que l'application réponde (démarrage du conteneur, enregistrement dans l'ALB...)
for _ in $(seq 1 30); do [[ "$(code "$URL/")" == 200 ]] && break; sleep 5; done

[[ "$(code "$URL/")" == 200 ]] && ok "page d'accueil (200)" || ko "page d'accueil injoignable"
# L'application renvoie sa page d'erreur avec un code 200 : il faut aussi vérifier le contenu
BODY="$(list)"
if [[ "$(code "$URL/students/")" == 200 ]] && ! grep -q "There was an error" <<<"$BODY"; then
  ok "liste des étudiants (200, base joignable)"
else
  ko "liste des étudiants : page d'erreur de l'application (base injoignable ?)"
fi

# Ajout
c=$(code -X POST "$URL/supplier-add" --data-urlencode "name=$NAME" -d "address=1 rue du Test&city=Paris&state=IDF&email=ci@exemple.edu&phone=0600000000")
if [[ "$c" == 302 ]] && list | grep -q "$NAME"; then ok "ajout d'un étudiant"; else ko "ajout (HTTP $c)"; fi

# Identifiant de l'étudiant créé (lien de modification sur sa ligne)
ID=$(list | grep -A12 "$NAME" | grep -oE 'supplier-update/[0-9]+' | head -1 | cut -d/ -f2)
[[ -n "$ID" ]] || ID=$(list | grep -oE 'supplier-update/[0-9]+' | tail -1 | cut -d/ -f2)

# Modification
c=$(code -X POST "$URL/supplier-update" -d "id=$ID" --data-urlencode "name=$NAME-modifie" -d "address=2 rue du Test&city=Lyon&state=ARA&email=ci@exemple.edu&phone=0600000000")
if [[ "$c" == 302 ]] && list | grep -q "$NAME-modifie"; then ok "modification (id $ID)"; else ko "modification (HTTP $c, id '$ID')"; fi

# Suppression
c=$(code -X POST "$URL/supplier-remove/$ID")
if [[ "$c" == 302 ]] && ! list | grep -q "$NAME"; then ok "suppression (id $ID)"; else ko "suppression (HTTP $c)"; fi

# Page inexistante
[[ "$(code "$URL/page-inexistante")" == 404 ]] && ok "page inexistante (404)" || ko "page inexistante sans 404"

echo "Résultat : $PASS réussi(s), $FAILED échec(s)"
[[ $FAILED -eq 0 ]]
