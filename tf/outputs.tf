output "public_ip" {
  value = aws_eip.master.public_ip
}