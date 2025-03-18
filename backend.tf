# Create S3 bucket for storing Terraform state
resource "aws_s3_bucket" "terraform_state" {
  bucket = "batch26terraformbatch26"
  force_destroy = true

  lifecycle {
    prevent_destroy = false
  }

  tags = {
    Name        = "TerraformStateBucket"
    Environment = "Dev"
  }
}

# Enable versioning for the S3 bucket
resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Create DynamoDB table for state locking
resource "aws_dynamodb_table" "terraform_locks" {
  name           = "terraform-lock"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "TerraformLockTable"
    Environment = "Dev"
  }
}

# Null resource to run backend initialization automatically after creating S3 and DynamoDB
resource "null_resource" "backend_init" {
  provisioner "local-exec" {
    command = <<EOT
      terraform init -reconfigure
    EOT
  }

  triggers = {
    always_run = "${timestamp()}"
  }

  depends_on = [
    aws_s3_bucket.terraform_state,
    aws_dynamodb_table.terraform_locks
  ]
}
