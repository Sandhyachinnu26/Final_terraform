#ami_id = "ami-04b4f1a9cf54c11d0"
ami_id = "ami-04b4f1a9cf54c11d0"  # Replace with a valid AMI ID

instance_type = "t2.micro"
aws_region = "us-east-1"
app_asg = "lt-063d5ac86004626fe"
terraform apply -var="ami-04b4f1a9cf54c11d0"
