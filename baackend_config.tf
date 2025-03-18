terraform {
  backend "s3" {
    bucket         = "batch26terraformbatch26"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    use_lock_table = true
    dynamodb_table = "terraform-lock"
  }
}
