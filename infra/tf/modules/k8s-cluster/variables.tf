# variable "aws_region" {
#   description = "Please Enter AWS Region to deploy Infrastructure"
#   type        = string
#   default     = "us-east-1"
# }

# variable "cidr_block" {
#   type        = string
#   description = "CIDR block for the VPC and subnet. This value will determine the private IP addresses of the Kubernetes cluster nodes."
#   #  default     = "172.31.0.0/16"
#   default = "10.0.0.0/16"
# }

variable "subnet_id" {}
variable "vpc_security_group_ids" {}

variable "master_instance_type" {
  type        = string
  description = "EC2 instance type for the master node (must have at least 2 CPUs and 2 GB RAM)."
  default     = "t2.medium"
}
