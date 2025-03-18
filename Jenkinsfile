pipeline {
    agent any

    environment {
        AWS_DEFAULT_REGION = 'us-east-1'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Terraform Init (No Backend)') {
            steps {
                echo "Initializing Terraform without backend..."
                sh 'terraform init'
            }
        }

        stage('Apply S3 and DynamoDB') {
            steps {
                echo "Applying S3 and DynamoDB..."
                sh 'terraform apply -auto-approve'
            }
        }

        stage('Wait for S3 Propagation') {
            steps {
                echo "Waiting for S3 propagation..."
                sleep 60  // Ensure S3 propagates before configuring backend
            }
        }

        stage('Terraform Init with Backend') {
            steps {
                echo "Reinitializing Terraform with backend..."
                sh 'terraform init -reconfigure'
            }
        }

        stage('Apply Backend') {
            steps {
                echo "Applying backend configuration..."
                sh 'terraform apply -auto-approve'
            }
        }
    }
