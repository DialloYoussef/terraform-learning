terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}

resource "local_file" "hello" {
  count    = 3
  filename = "${path.module}/hello-${count.index}.txt"
  content  = var.message
}

