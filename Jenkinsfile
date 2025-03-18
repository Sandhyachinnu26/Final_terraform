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
                sleep 30  // Wait for 30 seconds to ensure S3 bucket is fully available
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
            sh 'terraform destroy -auto-approve'
        }
    }
}
