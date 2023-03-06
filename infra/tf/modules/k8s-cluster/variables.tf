variable "subnet_id" {}
variable "vpc_security_group_ids" {}

variable "master_instance_type" {
  type        = string
  description = "EC2 instance type for the master node (must have at least 2 CPUs and 2 GB RAM)."
  default     = "t2.medium"
}
