# modules/app-server/outputs.tf
output "app_instance_id" {
  description = "The ID of the application EC2 instance"
  value       = aws_instance.app.id
}

output "app_instance_public_ip" {
  description = "The public IP of the application EC2 instance"
  value       = aws_instance.app.public_ip
}
