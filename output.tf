output "instance_public_ip" {
  description = "The public IP address of the instance"
  value       = aws_instance.web_server[0].public_ip
}
output "instance_id" {
  value = aws_instance.web_server[0].id
  description = "The ID of the provisioned EC2 instance"
}