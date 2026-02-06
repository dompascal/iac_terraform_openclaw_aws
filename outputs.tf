output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.openclaw.id
}

output "instance_public_ip" {
  description = "Public IP address of the instance"
  value       = aws_instance.openclaw.public_ip
}

output "instance_private_ip" {
  description = "Private IP address of the instance"
  value       = aws_instance.openclaw.private_ip
}

output "elastic_ip" {
  description = "Elastic IP address (if created)"
  value       = var.use_elastic_ip ? aws_eip.openclaw_eip[0].public_ip : null
}

output "security_group_id" {
  description = "Security group ID"
  value       = aws_security_group.openclaw_sg.id
}

output "tailscale_hostname" {
  description = "Tailscale hostname (check Tailscale admin console)"
  value       = "Check your Tailscale admin console for the assigned hostname"
}
