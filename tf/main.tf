# Terraform state will be stored in S3
terraform {
  backend "s3" {
    bucket = "tf-state-2048-ashutau"
    key    = "terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = var.aws_region
}
#=================================
# module "cluster" {
#   source  = "weibeld/kubeadm/aws"
#   version = "0.2.6"
#   num_workers = 1
# }
#==================================

#------------------------------------------------------------------------------#
# Key pair
#------------------------------------------------------------------------------#

# # Performs 'ImportKeyPair' API operation (not 'CreateKeyPair')
# resource "aws_key_pair" "main" {
#   key_name = "${var.cluster_name}-"
#   public_key      = file(var.public_key_file)
#   tags            = local.tags
# }

# resource "aws_default_vpc" "default" {}

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
  # vpc_id      = aws_default_vpc.default.id

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

#------------------------------------------------------------------------------#
# Elastic IP for master node
#------------------------------------------------------------------------------#

# EIP for master node because it must know its public IP during initialisation
resource "aws_eip" "master" {
  vpc = true
  tags = {
    Name = "k8s-eip"
  }
}

resource "aws_eip_association" "master" {
  allocation_id = aws_eip.master.id
  instance_id   = aws_instance.master.id
}

#------------------------------------------------------------------------------#
# EC2 instances
#------------------------------------------------------------------------------#

data "aws_ami" "ubuntu" {
  # AMI owner ID of Canonical
  owners      = ["099720109477"]
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

resource "aws_instance" "master" {
  ami           = data.aws_ami.ubuntu.image_id # "ami-0dfcb1ef8550277af"
  instance_type = var.master_instance_type     # "t3.small"
  key_name      = "n_virginia_key"
  subnet_id     = aws_subnet.main.id
  #  security_groups = [aws_security_group.kubernetes-node.id]
  vpc_security_group_ids = [aws_security_group.k8s_sg.id]
  # associate_public_ip_address = true
  # user_data              = file("k8s.sh")
  user_data_replace_on_change = true
  user_data = <<-EOF
    #!/bin/bash
    sudo snap install microk8s --classic --channel=1.26
    sudo usermod -a -G microk8s ubuntu
    sudo chown -f -R ubuntu /home/ubuntu/.kube
    sed -i "/#MOREIPS/a IP.99 = ${aws_eip.master.public_ip}" /var/snap/microk8s/current/certs/csr.conf.template
    microk8s enable ingress dns cert-manager
    microk8s config > /home/ubuntu/microk8s
  EOF
  tags = {
    Name = "k8s-node"
  }
}

#------------------------------------------------------------------------------#
# Wait for bootstrap to finish on all nodes
#------------------------------------------------------------------------------#

resource "null_resource" "wait_for_bootstrap_to_finish" {
  provisioner "local-exec" {
    command = <<-EOF
    alias ssh='ssh -q -i ~/.ssh/n_virginia_key.pem -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'
    while true; do
      sleep 2
      ! ssh ubuntu@${aws_eip.master.public_ip} [[ -f /home/ubuntu/microk8s ]] >/dev/null && continue
      break
    done
    EOF
  }
  triggers = {
    instance_id = aws_instance.master.id
  }
}

#------------------------------------------------------------------------------#
# Download kubeconfig file from master node to local machine
#------------------------------------------------------------------------------#

resource "null_resource" "download_kubeconfig_file" {
  provisioner "local-exec" {
    command = <<-EOF
    alias microk8s_scp='scp -q -i ~/.ssh/n_virginia_key.pem -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'
    microk8s_scp ubuntu@${aws_eip.master.public_ip}:~/microk8s ~/.kube/microk8s
    sed -i "s/server:.*/server: https:\/\/${aws_eip.master.public_ip}:16443/g" ~/.kube/microk8s
    EOF
  }
  triggers = {
#    instance_id = aws_instance.master.id
    wait_for_bootstrap_to_finish = null_resource.wait_for_bootstrap_to_finish.id
  }
}
