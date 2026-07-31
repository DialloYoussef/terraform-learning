output "fichier_cree" {
  description = "Chemin du fichier généré"
  value       = local_file.hello.filename
}

output "hash_du_contenu" {
  description = "Empreinte SHA256 du contenu"
  value       = local_file.hello.content_sha256
}
