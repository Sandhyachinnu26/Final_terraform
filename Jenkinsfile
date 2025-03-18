# Provider
provider "aws" {
  region = "us-east-1"
}

# Create S3 bucket for state storage
resource "aws_s3_bucket" "terraform_state" {
  bucket = "batch26terraformbatch26"
  lifecycle {
    prevent_destroy = false
  }

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  tags = {
    Name = "Terraform State Bucket"
  }
}

# S3 Public Access Block
resource "aws_s3_bucket_public_access_block" "terraform_state_block" {
  bucket                  = aws_s3_bucket.terraform_state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# DynamoDB for locking
resource "aws_dynamodb_table" "terraform_lock" {
  name         = "terraform-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name = "Terraform Lock Table"
  }
}

# Null resource to wait for S3 propagation
resource "null_resource" "wait_for_s3" {
  provisioner "local-exec" {
    command = "sleep 60"  # Wait for S3 to propagate
  }
  depends_on = [aws_s3_bucket.terraform_state]
}
