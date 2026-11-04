# Module réseau : VPC, sous-réseaux publics (application) et privés (base de données).
# Pas de NAT Gateway : les ressources privées (RDS) n'ont pas besoin d'Internet,
# ce qui évite environ 32 $/mois par NAT (optimisation des coûts).

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  # On prend autant de zones que de sous-réseaux demandés (2 minimum pour RDS)
  azs = slice(data.aws_availability_zones.available.names, 0, max(length(var.public_subnet_cidrs), length(var.private_subnet_cidrs)))
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true # nécessaire pour résoudre le nom DNS du endpoint RDS

  tags = { Name = "${var.name}-vpc" }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags   = { Name = "${var.name}-igw" }
}

# ---------- Sous-réseaux publics : serveurs web ----------
resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidrs)

  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = local.azs[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.name}-public-${local.azs[count.index]}"
    Tier = "public"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = { Name = "${var.name}-public-rt" }
}

resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# ---------- Sous-réseaux privés : base de données ----------
resource "aws_subnet" "private" {
  count = length(var.private_subnet_cidrs)

  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.private_subnet_cidrs[count.index]
  availability_zone       = local.azs[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.name}-private-${local.azs[count.index]}"
    Tier = "private"
  }
}

# Table de routage privée : uniquement la route locale du VPC, aucune sortie Internet
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id
  tags   = { Name = "${var.name}-private-rt" }
}

resource "aws_route_table_association" "private" {
  count = length(aws_subnet.private)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}
