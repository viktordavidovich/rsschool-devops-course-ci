output "public_address_instance_jenkins" {
  description = "The public IP address for bastion"
  value       = aws_instance.public_instance_jenkins.public_ip
}
