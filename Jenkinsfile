pipeline {
    agent any

    environment {
        AWS_REGION = 'us-east-1' 
        AWS_ACCOUNT_ID = '851725280627'
        IMAGE_TAG = "latest"
        TF_DIR = 'terraform'
    }

    stages {
        stage('Clean Workspace') {
            steps {
                cleanWs()
            }
        }

        stage('Checkout Code') {
            steps {
                checkout scm
            }
        }

        stage('Terraform Init') {
            steps {
                script {
                    dir(TF_DIR) {
                        sh "terraform init"
                    }
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                script {
                    dir(TF_DIR) {
                        def planResult = sh(script: "terraform plan -out=tfplan", returnStatus: true)
                        if (planResult != 0) {
                            error "Terraform plan failed! Check logs."
                        }
                    }
                }
            }
        }

        stage('Approval Required') {
            steps {
                script {
                    input message: "Do you approve applying the Terraform changes?", ok: "Yes, Apply"
                }
            }
        }

        stage('Terraform Apply (ECR & ECS Creation)') {
            steps {
                script {
                    dir(TF_DIR) {
                        sh "terraform apply tfplan"
                    }
                }
            }
        }

        stage('Fetch ECR Repository Name') {
            steps {
                script {
                    dir(TF_DIR) {
                        def repo_url = sh(script: "terraform output -raw ecr_repo_url", returnStdout: true).trim()
                        if (!repo_url?.trim()) {
                            error "ECR_REPO is empty! Make sure Terraform applied successfully."
                        }
                        env.ECR_REPO = repo_url
                    }
                    echo "ECR Repository: ${env.ECR_REPO}"
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    sh "docker build -t ${env.ECR_REPO}:${IMAGE_TAG} ."
                }
            }
        }

        stage('Login to AWS ECR') {
            steps {
                withAWS(credentials: 'aws-ecs-creds', region: AWS_REGION) {
                    script {
                        sh "aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin ${env.ECR_REPO}"
                    }
                }
            }
        }

        stage('Push Docker Image to ECR') {
            steps {
                script {
                    sh "docker push ${env.ECR_REPO}:${IMAGE_TAG}"
                }
            }
        }

        stage('Update ECS Service') {
            steps {
                withAWS(credentials: 'aws-ecs-creds', region: AWS_REGION) {
                    script {
                        sh "aws ecs update-service --cluster my-ecs-cluster --service my-service --force-new-deployment"
                    }
                }
            }
        }
    }

    post {
        success {
            echo 'Deployment successful!'
        }
        failure {
            echo 'Deployment failed!'
        }
    }
}
