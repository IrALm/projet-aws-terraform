# Phase 1 : Application web sur une VM unique (Terraform / AWS)

## Objectif

Mettre en place un POC qui héberge l'application de gestion des dossiers étudiants sur une seule machine virtuelle EC2, dans un VPC créé par Terraform. À la fin de cette phase, l'application est accessible depuis Internet et les opérations de base (afficher, ajouter, modifier, supprimer un étudiant) fonctionnent.

## Architecture

![Schéma d'architecture de la phase 1](architecture-phase1.png)

Éléments déployés :

- **VPC** `10.0.0.0/16` avec un sous-réseau public `10.0.1.0/24` dans la zone `us-east-1a`.
- **Internet Gateway** et **table de routage** qui envoient le trafic sortant vers Internet.
- **Security group** `universite-exemple-app-sg` :
  - port 80 (HTTP) ouvert à tout Internet ;
  - port 22 (SSH) ouvert uniquement à mon IP ;
  - port 3306 (MySQL) non ouvert : la base n'est pas accessible depuis Internet.
- **Instance EC2** `t3.small` sous Ubuntu 24.04 LTS, avec un volume gp3 de 20 Go. Le script fourni est passé en `user_data` et installe Node.js, MySQL et l'application au premier démarrage.

## Structure du code

```
phase1/
├── main.tf            # Provider AWS, région, tags communs
├── variables.tf       # Variables (région, CIDR, type d'instance, version Ubuntu, IP SSH, clé publique)
├── network.tf         # VPC, sous-réseau public, Internet Gateway, table de routage
├── security.tf        # Security group et règles (80, 22, sortie libre)
├── compute.tf         # Paire de clés SSH, AMI Ubuntu, instance EC2
├── outputs.tf         # IP publique, URL de l'application, commande SSH, IDs
├── scripts/
│   └── userdata.sh    # Script fourni, copié sans modification
├── terraform.tfvars   # Valeurs propres à mon poste (non versionné)
└── README.md
```

Le fichier `.gitignore` à la racine exclut les fichiers d'état, les dossiers `.terraform/`, les fichiers `*.tfvars` et les clés SSH.

## Prérequis

- Terraform installé.
- Identifiants AWS Academy exportés dans le terminal (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_SESSION_TOKEN`). Ils expirent : les renouveler avant chaque session.
- Une paire de clés SSH dédiée au projet :
```powershell
  ssh-keygen -t ed25519 -f $HOME\.ssh\id_ed25519_phase1 -C "phase1"
```

## Accès SSH

- **Clé publique** utilisée par Terraform : `~/.ssh/id_ed25519_phase1.pub`, indiquée dans `terraform.tfvars` via `ssh_public_key_path`.
- **Clé privée** : `~/.ssh/id_ed25519_phase1`. Elle reste sur mon poste et n'est jamais versionnée.
- **Connexion** :
```powershell
  ssh -i $HOME\.ssh\id_ed25519_phase1 ubuntu@<IP_PUBLIQUE>
```
- **Mise à jour de l'IP autorisée** : l'IP publique est renseignée dans `terraform.tfvars` sous la forme `ssh_allowed_cidr = "x.x.x.x/32"`. Pour obtenir la nouvelle IP, ouvrir https://checkip.amazonaws.com, puis lancer `terraform apply` après modification.

## Déploiement

Depuis le dossier `phase1/` :

```bash
terraform init      # Télécharge le provider AWS
terraform fmt       # Vérifie le formatage
terraform validate  # Vérifie la syntaxe
terraform plan      # Affiche les ressources à créer
terraform apply     # Crée l'infrastructure (répondre "yes")
```

Les outputs s'affichent à la fin : `application_url`, `public_ip`, `ssh_command`, `vpc_id`, `instance_id`. Relire les outputs plus tard avec `terraform output`.

**Premier démarrage** : le script d'installation prend 5 à 10 minutes. Le suivi se fait en SSH :

```bash
cloud-init status
sudo tail -f /var/log/cloud-init-output.log
```

L'application est prête lorsque le log affiche `Server is running on port 80`.

## Tests effectués

| Test | Résultat |
|---|---|
| Connexion SSH avec la clé dédiée | OK |
| Installation du script (`cloud-init status: done`) | OK |
| Accès à l'application depuis le navigateur (`application_url`) | OK |
| Affichage de la liste des étudiants | OK |
| Ajout d'un étudiant | OK |
| Modification d'un étudiant | OK |
| Suppression d'un étudiant | OK |
| Port 3306 inaccessible depuis Internet | OK (security group) |

## Difficultés rencontrées

1. **Descriptions refusées par AWS** : les descriptions des règles de security group n'acceptent ni accents ni apostrophes. Le premier `apply` a échoué pour cette raison ; les descriptions ont été corrigées.
2. **Espace dans `terraform.tfvars`** : une valeur `46.193.67.188 /32` (avec un espace) a fait échouer le `plan`. Le fichier a été recréé proprement.
3. **Passphrase de la clé SSH** : une passphrase saisie incorrectement produit `Permission denied (publickey)`, qui ressemble à une erreur de clé publique. Vérification faite avec `ssh-keygen -y -f`.
4. **Remplacement de la clé SSH** : changer la paire de clés dans Terraform ne modifie pas la VM existante, car la clé est installée à la création de l'instance. Il a fallu recréer la VM avec `terraform apply -replace="aws_instance.app"`.
5. **Configuration MySQL du script** : le script passe `bind-address` à `0.0.0.0`, ce qui expose MySQL sur toutes les interfaces. La protection repose ici uniquement sur le security group, qui bloque le port 3306 depuis Internet.

## Points d'attention et limites

- **Identifiants en clair** : le mot de passe de la base est écrit dans le script fourni. Ce n'est pas acceptable en production, et la phase 2 doit l'externaliser dans AWS Secrets Manager.
- **Avertissement Secrets Manager au démarrage** : l'application affiche « Secrets not found, proceeding with default values ». Elle fonctionne avec ses valeurs par défaut, mais cela confirme que le code fourni n'utilise pas encore Secrets Manager.
- **SDK obsolète** : le code utilise AWS SDK for JavaScript v2, en fin de support. À migrer vers la v3 dans une phase ultérieure.
- **Adresse IP changeante** : l'IP publique change à chaque recréation de la VM. Il faut relire les outputs après chaque `apply -replace`.
- **Disponibilité** : une seule VM dans une seule zone, donc pas de tolérance à la panne. C'est le sujet de la phase 3.

## Nettoyage

Pour supprimer toutes les ressources et arrêter la consommation des crédits Academy :

```bash
terraform destroy
```

## Suite

- **Phase 2** : séparer la base de données (RDS MySQL) et l'application, et stocker les identifiants dans Secrets Manager.