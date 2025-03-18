# AWS Provider
provider "aws" {
  region = "us-east-1"
}

# -----------------------
# S3 Backend Configuration
# -----------------------

# Create S3 Bucket for State Storage
resource "aws_s3_bucket" "terraform_state" {
  bucket        = "batch1terraformbatch12"
  force_destroy = true  # Allow bucket deletion during destroy

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

# Block public access
resource "aws_s3_bucket_public_access_block" "terraform_state_block" {
  bucket                  = aws_s3_bucket.terraform_state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# -----------------------
# DynamoDB for State Locking
# -----------------------

# Create DynamoDB Table for Locking
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

# -----------------------
# Backend Configuration
# -----------------------

terraform {
  backend "s3" {
    bucket         = "batch1terraformbatch12"   # S3 bucket name
    key            = "terraform/statefile.tfstate"  # State file path
    region         = "us-east-1"
    dynamodb_table = "terraform-lock"  # DynamoDB for locking
    encrypt        = true
  }
}

# -----------------------
# SonarQube EC2 Instance
# -----------------------

resource "aws_instance" "sonarqube" {
  ami           = "ami-04b4f1a9cf54c11d0"  # Replace with valid AMI
  instance_type = "t2.medium"     
  security_groups = [aws_security_group.sonarqube_sg.name]

  user_data = <<-EOF
    #!/bin/bash
    sudo apt update -y
    sudo apt upgrade -y

    # Install Docker
    sudo apt install -y docker.io
    sudo systemctl start docker
    sudo systemctl enable docker
    sudo usermod -aG docker ubuntu

    # Pull and run SonarQube container
    sudo docker run -d --name sonarqube -p 9000:9000 sonarqube
  EOF

  tags = {
    Name = "SonarQube-Server"
  }
}

# Security Group for SonarQube
resource "aws_security_group" "sonarqube_sg" {
  name        = "sonarqube-security-group"
  description = "Allow inbound access to SonarQube"

  ingress {
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# -----------------------
# VPC Configuration
# -----------------------

# VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "main-vpc"
  }
}

# Public Subnets
resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index)
  availability_zone       = element(data.aws_availability_zones.available.names, count.index)
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-${count.index}"
  }
}

# Get Available AZs
data "aws_availability_zones" "available" {
  state = "available"
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main-igw"
  }
}

# Route Table for Public Subnets
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public-route-table"
  }
}

# Associate Route Table with Public Subnets
resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# -----------------------
# Security Group
# -----------------------

resource "aws_security_group" "app_sg" {
  vpc_id      = aws_vpc.main.id
  name        = "app_security_group"
  description = "Allow HTTP & SSH"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
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
}

# -----------------------
# Launch Template
# -----------------------

resource "aws_launch_template" "app_template" {
  name_prefix   = "app-template"
  image_id      = var.ami_id  # Replace with your AMI ID
  instance_type = "t2.micro"

  user_data = base64encode(<<-EOF
#!/bin/bash
apt update -y
apt install -y apache2
systemctl enable apache2
systemctl start apache2

echo "<h1>Welcome to My Web Server</h1>" > /var/www/html/index.html
EOF
  )

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.app_sg.id]
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "Terraform-ASG-Instance"
    }
  }
}

# -----------------------
# Auto Scaling Group (ASG)
# -----------------------

resource "aws_autoscaling_group" "app_asg" {
  desired_capacity     = 1
  min_size            = 1
  max_size            = 3
  vpc_zone_identifier = aws_subnet.public[*].id

  launch_template {
    id      = aws_launch_template.app_template.id
    version = "$Latest"
  }
}

# -----------------------
# Load Balancer (ALB)
# -----------------------

resource "aws_lb" "app_lb" {
  name               = "app-load-balancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.app_sg.id]
  subnets           = aws_subnet.public[*].id
}

# Target Group
resource "aws_lb_target_group" "app_tg" {
  name     = "app-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
}

# ALB Listener
resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}

# Attach ASG to ALB
resource "aws_autoscaling_attachment" "asg_attachment" {
  autoscaling_group_name = aws_autoscaling_group.app_asg.id
  lb_target_group_arn    = aws_lb_target_group.app_tg.arn
}
