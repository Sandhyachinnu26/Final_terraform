terraform {
  backend "s3" {
    bucket         = "batch26terraformbatch26"
    key            = "terraform/statefile.tfstate"
    region         = "us-east-1"
    encrypt        = true
    use_lock_table = true
    dynamodb_table = "terraform-lock"
  }
}
