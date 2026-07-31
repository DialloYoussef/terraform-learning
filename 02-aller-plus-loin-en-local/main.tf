terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}

locals {
  prefixe = var.environment == "prod" ? "PROD" : "DEV"
}


resource "local_file" "note" {
  for_each = {
    intro    = "Ceci est l'introduction"
    concepts = "Ceci contient les concepts clés"
    exercice = "Ceci contient l'exercice pratique"
  }

  filename = "${path.module}/note-${each.key}.txt"
  content  = "[${local.prefixe}] ${each.value}"
}
