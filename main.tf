# --- AWS Provider Configuration ---
# Specifies the AWS provider and the region where the infrastructure will be deployed.
provider "aws" {
  region = var.aws_region
}

# --- VPC & Subnet Definitions ---
# This section defines the core network layout, including the main VPC container
# and the public/private subnets distributed across two Availability Zones for high availability.

# Defines the main Virtual Private Cloud (VPC).
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr_block
  tags = {
    Name = "Main-VPC"
  }
}

# Defines the public subnet in Availability Zone A.
resource "aws_subnet" "public_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_subnet_a_cidr
  availability_zone = "${var.aws_region}a"
  tags = {
    Name = "Public-Subnet-A"
  }
}

# Defines the public subnet in Availability Zone B.
resource "aws_subnet" "public_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_subnet_b_cidr
  availability_zone = "${var.aws_region}b"
  tags = {
    Name = "Public-Subnet-B"
  }
}

# Defines the private subnet in Availability Zone A.
resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_a_cidr
  availability_zone = "${var.aws_region}a"
  tags = {
    Name = "Private-Subnet-A"
  }
}

# Defines the private subnet in Availability Zone B.
resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_b_cidr
  availability_zone = "${var.aws_region}b"
  tags = {
    Name = "Private-Subnet-B"
  }
}

# --- Networking Gateways (IGW & NAT) ---
# This section defines the gateways responsible for managing internet connectivity for the VPC.

# Defines the Internet Gateway (IGW) to allow public internet access.
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "Main-IGW"
  }
}

# Defines an Elastic IP for the NAT Gateway, providing a static public IP.
resource "aws_eip" "nat_eip" {
  domain = "vpc"
}

# Defines the NAT Gateway to allow secure, outbound-only internet access for private subnets.
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_a.id # NAT Gateway must reside in a public subnet.
  tags = {
    Name = "Main-NAT-GW"
  }
  # Explicitly state dependency to ensure the IGW is created before the NAT Gateway.
  depends_on = [aws_internet_gateway.igw]
}

# --- Routing Configuration ---
# This section defines the route tables and associations that control the flow of traffic
# for the public and private subnets, enforcing the network segmentation.

# Defines the route table for public subnets, with a default route to the Internet Gateway.
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "Public-RT" }
}

# Associates the public subnets with the public route table.
resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public_rt.id
}
resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public_rt.id
}

# Defines the route table for private subnets, with a default route to the NAT Gateway.
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
  tags = { Name = "Private-RT" }
}

# Associates the private subnets with the private route table.
resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private_rt.id
}
resource "aws_route_table_association" "private_b" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private_rt.id
}