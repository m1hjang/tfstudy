# ── VPC ───────────────────────────────────────────────────────────────────────

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name    = "${var.project}-${var.env}-vpc"
    Project = var.project
    Env     = var.env
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name    = "${var.project}-${var.env}-igw"
    Project = var.project
    Env     = var.env
  }
}

# ── Public subnets ────────────────────────────────────────────────────────────

resource "aws_subnet" "public" {
  for_each                = var.public_subnets
  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.key
  availability_zone       = each.value
  map_public_ip_on_launch = true

  tags = {
    Name    = "${var.project}-${var.env}-public-${each.value}"
    Project = var.project
    Env     = var.env
    Tier    = "public"
  }
}

resource "aws_eip" "nat" {
  for_each = var.public_subnets
  domain   = "vpc"

  tags = {
    Name    = "${var.project}-${var.env}-nat-eip-${each.value}"
    Project = var.project
    Env     = var.env
  }
}

resource "aws_nat_gateway" "main" {
  for_each      = var.public_subnets
  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = aws_subnet.public[each.key].id

  depends_on = [aws_internet_gateway.main]

  tags = {
    Name    = "${var.project}-${var.env}-nat-${each.value}"
    Project = var.project
    Env     = var.env
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name    = "${var.project}-${var.env}-public-rt"
    Project = var.project
    Env     = var.env
  }
}

resource "aws_route_table_association" "public" {
  for_each       = var.public_subnets
  subnet_id      = aws_subnet.public[each.key].id
  route_table_id = aws_route_table.public.id
}

# ── NAT route tables (one per public AZ, no private subnet RTAs here) ─────────
# Consuming modules (web, db) are responsible for associating their subnets
# to the appropriate NAT route table if outbound internet access is needed.
# Private subnets with no RTA fall back to the VPC main route table (local only).

resource "aws_route_table" "nat" {
  for_each = var.public_subnets
  vpc_id   = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[each.key].id
  }

  tags = {
    Name    = "${var.project}-${var.env}-nat-rt-${each.value}"
    Project = var.project
    Env     = var.env
  }
}

# ── Private subnets (generic — no workload tier distinction) ──────────────────

resource "aws_subnet" "private" {
  for_each          = var.private_subnets
  vpc_id            = aws_vpc.main.id
  cidr_block        = each.key
  availability_zone = each.value

  tags = {
    Name    = "${var.project}-${var.env}-private-${each.value}"
    Project = var.project
    Env     = var.env
  }
}
