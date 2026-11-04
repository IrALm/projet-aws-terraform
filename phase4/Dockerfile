# syntax=docker/dockerfile:1
#
# Image de l'application "dossiers des étudiants" (code fourni dans app/, non modifié).
# Construction depuis la racine du dépôt :
#   docker build -f phase4/Dockerfile -t universite-exemple-app app
#
# Équivalent conteneurisé du script user_data des phases 2 et 3 :
#   apt install nodejs npm  ->  image de base Node.js officielle
#   npm install aws aws-sdk ->  npm ci (versions verrouillées) + aws-sdk
#   npm start               ->  CMD ["node", "index.js"]

# ---------- Étape 1 : dépendances ----------
FROM node:24-alpine AS deps
WORKDIR /app

COPY package.json package-lock.json ./
# npm ci : installe exactement les versions du package-lock (build reproductible).
# aws-sdk (v2) est requis par app/config/config.js mais absent de package.json :
# il est ajouté ici avec une version figée (le script d'origine faisait "npm install aws-sdk").
RUN npm ci --omit=dev --no-audit --no-fund \
 && npm install --omit=dev --no-save --no-audit --no-fund aws-sdk@2.1692.0 \
 && npm cache clean --force

# ---------- Étape 2 : image finale ----------
FROM node:24-alpine
ENV NODE_ENV=production \
    APP_PORT=8080
WORKDIR /app

# Dépendances de l'étape 1, puis code de l'application (sans node_modules local)
COPY --from=deps --chown=node:node /app/node_modules ./node_modules
COPY --chown=node:node . .

# Utilisateur non privilégié "node" (uid 1000, fourni par l'image) : un port > 1024 est donc
# nécessaire. Le port 80 reste exposé côté hôte (docker run -p 80:8080).
# UID numérique : vérifiable par les orchestrateurs (ex. Kubernetes runAsNonRoot).
USER 1000:1000
EXPOSE 8080

# La page d'accueil ne dépend pas de la base : même logique que le health check de l'ALB.
# Forme exec + sh -c : la variable APP_PORT est développée au moment du test.
HEALTHCHECK --interval=15s --timeout=5s --start-period=10s --retries=3 \
  CMD ["sh", "-c", "wget -q -O /dev/null http://127.0.0.1:${APP_PORT}/ || exit 1"]

CMD ["node", "index.js"]
