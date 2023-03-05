#------------------------------------------------------------------------------#
# Generate key pair
#------------------------------------------------------------------------------#
variable "key_name" {
  description = "Generated key pair name"
  type        = string
  default     = "k8s-key"
}

resource "tls_private_key" "terrafrom_generated_private_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name   = var.key_name
  public_key = tls_private_key.terrafrom_generated_private_key.public_key_openssh

  # Store private key :  Generate and save private key(aws_keys_pairs.pem) in current directory
  provisioner "local-exec" {
    command = <<-EOT
      echo '${tls_private_key.terrafrom_generated_private_key.private_key_pem}' > ~/.ssh/${var.key_name}.pem
      chmod 400 ~/.ssh/${var.key_name}.pem
    EOT
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
# Route53 Update Hosted zone record with eip
#------------------------------------------------------------------------------#
# resource "aws_route53_zone" "primary" {
#   name = "avs-it.net"
# }

resource "aws_route53_record" "www" {
  # zone_id = aws_route53_zone.primary.zone_id
  zone_id = "Z01980993H1VZXH19ZE7R"
  name    = "avs-it.net"
  type    = "A"
  ttl     = 300
  records = [aws_eip.master.public_ip]
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
#  key_name      = "n_virginia_key"
  key_name      = var.key_name
  subnet_id     = var.subnet_id
  vpc_security_group_ids = var.vpc_security_group_ids
  user_data_replace_on_change = true
  user_data                   = <<-EOF
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
# Wait for bootstrap to finish
#------------------------------------------------------------------------------#

resource "null_resource" "wait_for_bootstrap_to_finish" {
  provisioner "local-exec" {
    command = <<-EOF
    alias ssh='ssh -q -i ~/.ssh/${var.key_name}.pem -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'
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
    alias microk8s_scp='scp -q -i ~/.ssh/${var.key_name}.pem -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'
    microk8s_scp ubuntu@${aws_eip.master.public_ip}:~/microk8s ~/.kube/microk8s
    sed -i "s/server:.*/server: https:\/\/${aws_eip.master.public_ip}:16443/g" ~/.kube/microk8s
    EOF
  }
  triggers = {
    wait_for_bootstrap_to_finish = null_resource.wait_for_bootstrap_to_finish.id
  }
}