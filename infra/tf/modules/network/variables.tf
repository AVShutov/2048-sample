variable "cidr_block" {
  type        = string
  description = "CIDR block for the VPC and subnet. This value will determine the private IP addresses of the Kubernetes cluster nodes."
  #  default     = "172.31.0.0/16"
  default = "10.0.0.0/16"
}