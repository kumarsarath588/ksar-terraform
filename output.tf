output "aws_region" {
  description = "Aws region print"
  value       = var.region
}

output "ksar_mysql_ip_address" {
  description = "Ec2 Instance public IP address"
  value       = aws_instance.ksar-mysql.public_ip
}

output "ksar_web_app_ip_address" {
  description = "Ec2 Instance public IP address"
  value       = aws_instance.ksar[*].public_ip
}
