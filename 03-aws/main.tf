resource "aws_s3_bucket" "learning" {
  bucket = "tf-learning-youssouf-2026-07-31"

  tags = {
    Name = "Terraform Learning Bucket"
    Env  = "formation"
  }
}

resource "aws_security_group" "learning_sg" {
  name        = "tf-learning-sg"
  description = "Security group pour le module apprentissage"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "tf-learning-sg"
  }
}

resource "tls_private_key" "learning_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "learning_key" {
  key_name   = "tf-learning-key"
  public_key = tls_private_key.learning_key.public_key_openssh
}

resource "local_file" "private_key" {
  filename        = "${path.module}/tf-learning-key.pem"
  content         = tls_private_key.learning_key.private_key_pem
  file_permission = "0600"
}

