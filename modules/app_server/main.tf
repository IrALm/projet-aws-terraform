# Module serveur d'application : une instance EC2 Ubuntu qui exécute l'application Node.js.
# L'instance lit ses identifiants de base dans Secrets Manager grâce à son profil IAM :
# aucune clé AWS ni mot de passe n'est présent sur la machine.

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd*/ubuntu-*-${var.ubuntu_version}-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_key_pair" "this" {
  key_name   = "${var.name}-key"
  public_key = file(pathexpand(var.ssh_public_key_path))
}

resource "aws_instance" "this" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = var.security_group_ids
  key_name               = aws_key_pair.this.key_name

  # Profil IAM fourni par AWS Academy (création de rôles interdite dans le lab).
  # LabRole autorise secretsmanager:GetSecretValue.
  iam_instance_profile = var.iam_instance_profile

  user_data                   = file(var.user_data_path)
  user_data_replace_on_change = true

  # IMDSv2 obligatoire (amélioration par rapport à la phase 1) :
  # le SDK AWS de l'application gère les jetons IMDSv2 nativement.
  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

  root_block_device {
    volume_type = "gp3"
    volume_size = 20
    encrypted   = true
  }

  tags = { Name = "${var.name}-app-server" }

  # Le secret doit exister avant le premier démarrage : l'application le lit une seule fois,
  # au lancement, et se rabat sur "localhost" s'il est absent.
  depends_on = [terraform_data.wait_for]
}

# Ancre de dépendance : permet à l'appelant d'imposer un ordre de création
# (ici : secret créé avant l'instance) sans coupler le module au module secret.
resource "terraform_data" "wait_for" {
  input = var.depends_on_ids
}
