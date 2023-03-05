variable "aws_region" {
  description = "Please Enter AWS Region to deploy Infrastructure"
  type        = string
  default     = "us-east-1"
}

# variable "master_instance_type" {
#   type        = string
#   description = "EC2 instance type for the master node (must have at least 2 CPUs and 2 GB RAM)."
#   default     = "t2.medium"
# }
