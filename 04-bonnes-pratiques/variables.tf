variable "db_password" {
  description = "Mot de passe simulé d'une base de données"
  type        = string
  sensitive   = true
  default     = "SuperSecret123"
}
