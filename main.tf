terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.50.0"
    }
  }
}

provider "aws" {
  region                   = var.aws_region
  shared_credentials_files = [var.credential_path]
}

locals {
  route_table_tag = {
    rt-for-public-subnet  = "rt-for-public"
    rt-for-private-subnet = "rt-for-private"
  }
}

# Creating a vpc named virtual_network
resource "aws_vpc" "virtual_network" {
  instance_tenancy = var.instance_tenacy
  cidr_block       = var.vpc_cidr_block
}

resource "aws_subnet" "public_subnet" {
  vpc_id     = aws_vpc.virtual_network.id
  cidr_block = var.public_cidr
  tags = {
    Name = var.public_subnet_tag
  }
}

resource "aws_subnet" "private_subnet" {
  vpc_id     = aws_vpc.virtual_network.id
  cidr_block = var.private_cidr
  tags = {
    Name = var.private_subnet_tag
  }
}

# Creating an internet gateway
resource "aws_internet_gateway" "virtual_network_igw" {
  vpc_id = aws_vpc.virtual_network.id

  tags = {
    Name = var.igw_name
  }

  depends_on = [aws_vpc.virtual_network]
}

# Creates an attachment b/w vpc and internet gateway 
resource "aws_internet_gateway_attachment" "example" {
  internet_gateway_id = aws_internet_gateway.virtual_network_igw.id
  vpc_id              = aws_vpc.virtual_network.id
}

# Creating a security group for public instance
resource "aws_security_group" "rule_for_public_subnet" {
  name        = var.sg_name_public
  description = "Allows ssh and http access to the associated EC2 instances and icmp outbound traffic to the private subnet"
  vpc_id      = aws_vpc.virtual_network.id
  tags = {
    Name = var.sg_name_public
  }
}

# Creating a security group for private instance
resource "aws_security_group" "rule_for_private_subnet" {
  name        = var.sg_name_private
  description = "Allows icmp, ssh and http access to the associated EC2 instances in private subnet"
  vpc_id      = aws_vpc.virtual_network.id
  tags = {
    Name = var.sg_name_private
  }
}

# Creating a port 80 inbound rule
resource "aws_vpc_security_group_ingress_rule" "http_ingress_public" {
  security_group_id = aws_security_group.rule_for_public_subnet.id
  cidr_ipv4         = var.inbound_rule_source_public
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

# Creating a port 22 inbound rule
resource "aws_vpc_security_group_ingress_rule" "ssh_ingress_public" {
  security_group_id = aws_security_group.rule_for_public_subnet.id
  cidr_ipv4         = var.inbound_rule_source_public
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

# Creating a icmp outbound rule
resource "aws_vpc_security_group_egress_rule" "icmp_traffic_public" {
  security_group_id = aws_security_group.rule_for_public_subnet.id
  cidr_ipv4         = var.outbound_rule_source_public
  from_port         = -1
  ip_protocol       = "icmp"
  to_port           = -1
}

resource "aws_vpc_security_group_egress_rule" "ssh_outbound_public" {
  security_group_id = aws_security_group.rule_for_public_subnet.id
  cidr_ipv4         = var.outbound_rule_source_public
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}


# Creating a port 80 inbound rule
resource "aws_vpc_security_group_ingress_rule" "http_ingress_private" {
  security_group_id = aws_security_group.rule_for_private_subnet.id
  cidr_ipv4         = var.inbound_rule_source_public
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

# Creating a port 22 inbound rule
resource "aws_vpc_security_group_ingress_rule" "ssh_ingress_private" {
  security_group_id = aws_security_group.rule_for_private_subnet.id
  cidr_ipv4         = var.inbound_rule_source_public
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

# Creating a icmp inbound rule
resource "aws_vpc_security_group_ingress_rule" "icmp_traffic_private" {
  security_group_id = aws_security_group.rule_for_private_subnet.id
  cidr_ipv4         = var.inbound_rule_source_public
  from_port         = -1
  ip_protocol       = "icmp"
  to_port           = -1
}

resource "aws_vpc_security_group_egress_rule" "icmp_traffic_private" {
  security_group_id = aws_security_group.rule_for_private_subnet.id
  cidr_ipv4         = var.inbound_rule_source_public
  from_port         = -1
  ip_protocol       = "icmp"
  to_port           = -1
}

resource "aws_instance" "ec2-instance" {
  ami           = "ami-0e449927258d45bc4"
  instance_type = var.instance_type
  count         = length(var.instance_tag)
  tags = {
    Name = var.instance_tag[count.index]
  }
  subnet_id                   = var.instance_tag[count.index] == "public_instance" ? aws_subnet.public_subnet.id : aws_subnet.private_subnet.id
  key_name                    = var.key_name
  associate_public_ip_address = var.instance_tag[count.index] == "public_instance" ? true : false
  vpc_security_group_ids      = [var.instance_tag[count.index] == "public_instance" ? aws_security_group.rule_for_public_subnet.id : aws_security_group.rule_for_private_subnet.id]
}

# Creating an elastic ip for NAT gateway
resource "aws_eip" "nat_ip" {
  domain = "vpc"

  tags = {
    Name = var.elastic_ip_tag
  }
}

resource "aws_nat_gateway" "nat_public" {
  allocation_id = aws_eip.nat_ip.id
  subnet_id     = aws_subnet.public_subnet.id

  tags = {
    Name = var.nat_gateway_tag
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.virtual_network_igw, aws_vpc.virtual_network, aws_subnet.public_subnet]
}

resource "aws_route_table" "rt-for-public-subnet" {
  vpc_id = aws_vpc.virtual_network.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.virtual_network_igw.id
  }

  tags = {
    Name = local.route_table_tag["rt-for-public-subnet"]
  }
}

resource "aws_route_table" "rt-for-private-subnet" {
  vpc_id = aws_vpc.virtual_network.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_public.id
  }

  tags = {
    Name = local.route_table_tag["rt-for-private-subnet"]
  }
}

resource "aws_route_table_association" "public_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.rt-for-public-subnet.id
}

resource "aws_route_table_association" "private_association" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.rt-for-private-subnet.id
}
