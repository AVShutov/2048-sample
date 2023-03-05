#------------------------------------------------------------------------------#
# Create network
#------------------------------------------------------------------------------#

# Create a VPC
resource "aws_vpc" "main" {
  cidr_block           = var.cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "k8s-vpc"
  }
}

# Create a subnet
resource "aws_subnet" "main" {
  cidr_block = var.cidr_block
  vpc_id     = aws_vpc.main.id
  tags = {
    Name = "k8s-subnet"
  }
}

# Create an internet gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "k8s-igw"
  }
}

resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags = {
    Name = "k8s-route-table"
  }
}

resource "aws_route_table_association" "main" {
  route_table_id = aws_route_table.main.id
  subnet_id      = aws_subnet.main.id
}

#------------------------------------------------------------------------------#
# Security groups
#------------------------------------------------------------------------------#

resource "aws_security_group" "k8s_sg" {
  name   = "k8s-sg"
  vpc_id = aws_vpc.main.id

  dynamic "ingress" {
    for_each = ["16443", "22", "80", "443"] # Allow Kubernetes API, SSH, HTTP, HTTPS
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  # Allow all outbound traffic to the VPC
  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    #    cidr_blocks = [aws_vpc.k8s_vpc.cidr_block]
    cidr_blocks = ["0.0.0.0/0"]
  }
}
