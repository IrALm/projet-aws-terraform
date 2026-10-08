# Clé publique SSH installée sur la VM.
# pathexpand() transforme le ~ en chemin réel, que file() ne sait pas faire seul.
resource "aws_key_pair" "app" {
  key_name   = "${var.project_name}-key"
  public_key = file(pathexpand(var.ssh_public_key_path))
}

# Image Ubuntu officielle (éditeur Canonical) dans la version choisie
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd*/ubuntu-*-${var.ubuntu_version}-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# VM qui héberge l'application et MySQL
resource "aws_instance" "app" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.app.id]
  key_name                    = aws_key_pair.app.key_name
  associate_public_ip_address = true

  # Le script est passé tel quel, sans modification (exigence du sujet)
  user_data = file("${path.module}/scripts/userdata.sh")

  # Si le script change, Terraform recrée la VM pour le rejouer
  user_data_replace_on_change = true

  # Le script lit l'IP privée via le service de métadonnées (169.254.169.254, IMDSv1).
  # Ce réglage autorise les requêtes sans jeton, nécessaire pour ce script.
  metadata_options {
    http_tokens = "optional"
  }

  root_block_device {
    volume_type = "gp3"
    volume_size = 20
  }

  tags = {
    Name = "${var.project_name}-app-vm"
  }
}