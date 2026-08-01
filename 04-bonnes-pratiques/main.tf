terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}

resource "local_file" "config" {
  filename = "${path.module}/config.txt"
  content  = "db_password=${var.db_password}"
}

module "note_bienvenue" {
  source      = "./modules/fichier-texte"
  nom_fichier = "bienvenue.txt"
  contenu     = "Bienvenue dans les modules Terraform !"
}

module "note_recap" {
  source      = "./modules/fichier-texte"
  nom_fichier = "recap.txt"
  contenu     = "Ceci est généré par le même module, appelé une deuxième fois avec des valeurs différentes."
}
