pipeline {
    parameters {
        booleanParam(name: 'autoApprove', defaultValue: false, description: 'Automatically run apply after generating plan?')
    } 

    environment {
        AWS_REGION = 'us-east-1' 
        AWS_ACCOUNT_ID = '851725280627'
        IMAGE_TAG = "latest"
        TF_DIR = 'terraform'
    }

    agent any

    stages {
        stage('Checkout Code') {
            steps {
                script {
                    git branch: 'main', url: 'https://github.com/Ashu7072/Terraform-Jenkins-ECS.git'
                }
            }
        }

        stage('Terraform Init & Plan') {
            steps {
                script {
                    dir(TF_DIR) {
                        sh "terraform init"
                        sh "terraform plan -out=tfplan"
                        sh "terraform show -no-color tfplan > tfplan.txt"
                    }
                }
            }
        }

        stage('Approval Required') {
            when {
                not { equals expected: true, actual: params.autoApprove }
            }
            steps {
                script {
                    def plan = readFile("${TF_DIR}/tfplan.txt")
                    input message: "Do you approve applying the Terraform changes?",
                    parameters: [text(name: 'Plan', description: 'Please review the plan', defaultValue: plan)]
                }
            }
        }

        stage('Terraform Apply') {
            steps {
                script {
                    dir(TF_DIR) {
                        sh "terraform apply -input=false tfplan"
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
                script {
                    sh "aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin ${env.ECR_REPO}"
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
                script {
                    sh "aws ecs update-service --cluster my-ecs-cluster --service my-service --force-new-deployment"
                }
            }
        }
    }

    post {
        success {
            echo '✅ Deployment successful!'
        }
        failure {
            echo '❌ Deployment failed! Check logs for errors.'
        }
    }
}
