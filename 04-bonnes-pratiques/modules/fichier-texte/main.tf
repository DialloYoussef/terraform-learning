resource "local_file" "fichier" {
  filename = "${path.module}/${var.nom_fichier}"
  content  = var.contenu
}
