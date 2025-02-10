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
                git branch: 'main', url: 'https://github.com/Ashu7072/Jenkins-CICD.git'
            }
        }

        stage('Check Terraform Directory') {
            steps {
                script {
                    def dirExists = sh(script: "[ -d terraform ] && echo 'Exists' || echo 'Not Found'", returnStdout: true).trim()
                    if (dirExists == "Not Found") {
                        error "Terraform directory not found! Check if the repository is correctly cloned."
                    }
                }
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
                        sh "terraform plan -out=tfplan"
                    }
                }
            }
        }

        stage('Approval Required') {
            when {
                not {
                    equals expected: true, actual: params.autoApprove
                }
            }
            steps {
                script {
                    def plan = readFile "${TF_DIR}/tfplan.txt"
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
