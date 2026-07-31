resource "aws_s3_bucket" "learning" {
  bucket = "tf-learning-youssouf-2026-07-31"

  tags = {
    Name = "Terraform Learning Bucket"
    Env  = "formation"
  }
}
