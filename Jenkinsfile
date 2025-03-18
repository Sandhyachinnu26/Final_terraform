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

        stage('Terraform Init') {
            steps {
                sh 'terraform init'
            }
        }

        stage('Terraform Apply') {
            steps {
                sh 'terraform apply -auto-approve'
            }
        }

        stage('Wait for S3 Propagation') {
            steps {
                echo "Waiting for S3 propagation..."
                sleep 30  // Ensure S3 bucket is available before reconfigure
            }
        }

        stage('Terraform Reconfigure Backend') {
            steps {
                sh 'terraform init -reconfigure'
            }
        }
    }

    post {
        always {
            echo "Cleaning up resources"
            sh 'terraform destroy -auto-approve'
        }
    }
}
