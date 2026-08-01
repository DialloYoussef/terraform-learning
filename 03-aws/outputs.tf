output "instance_public_ip" {
  description = "Adresse IP publique de la VM"
  value       = aws_instance.learning_server.public_ip
}
