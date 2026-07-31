resource "aws_s3_bucket" "learning" {
  bucket = "tf-learning-youssouf-2026-07-31"

  tags = {
    Name = "Terraform Learning Bucket"
    Env  = "formation"
  }
}

resource "aws_security_group" "learning_sg" {
  name        = "tf-learning-sg"
  description = "Security group pour le module d'apprentissage"

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
