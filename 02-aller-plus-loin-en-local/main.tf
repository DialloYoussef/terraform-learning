terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}

resource "local_file" "note" {
  count    = 3
  filename = "${path.module}/note-${count.index}.txt"
  content  = "Ceci est la note numéro ${count.index}"
}
