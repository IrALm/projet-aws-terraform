#!/bin/bash -xe
# Serveur d'application de la phase 2 (code de la solution "serveur d'application").
# Différences avec la phase 1 :
#   - plus de mysql-server : la base est sur Amazon RDS ;
#   - mysql-client installé : sert à la migration des données (Script-3) ;
#   - aucune variable APP_DB_* : l'application lit ses identifiants dans
#     Secrets Manager (secret "Mydbsecret") grâce au profil IAM de l'instance.
apt update -y
apt install nodejs unzip wget npm mysql-client -y
wget https://aws-tc-largeobjects.s3.us-west-2.amazonaws.com/CUR-TF-200-ACCAP1-1-91571/1-lab-capstone-project-1/code.zip -P /home/ubuntu
cd /home/ubuntu
unzip code.zip -x "resources/codebase_partner/node_modules/*"
cd resources/codebase_partner
npm install aws aws-sdk
export APP_PORT=80
npm start &
echo '#!/bin/bash -xe
cd /home/ubuntu/resources/codebase_partner
export APP_PORT=80
npm start' > /etc/rc.local
chmod +x /etc/rc.local
