resource "aws_s3_bucket" "lambda_bucket" {
  bucket        = "test-bucket-gkr"
  force_destroy = true
}
