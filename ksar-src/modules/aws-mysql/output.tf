output "mysql_instance_id" {
  value       = aws_instance.aws-mysql.id
}

output "mysql_private_ip_address" {
  description = "Ec2 Instance public IP address"
  value       = aws_instance.aws-mysql.private_ip
}

output "mysql_public_ip_address" {
  description = "Ec2 Instance public IP address"
  value       = aws_instance.aws-mysql.public_ip
}