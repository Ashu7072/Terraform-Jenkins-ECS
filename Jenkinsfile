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

        stage('Terraform Init') {
            steps {
                script {
                    sh "terraform -chdir=${TF_DIR} init"
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                script {
                    sh "terraform -chdir=${TF_DIR} plan -out=tfplan"
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
                    sh "terraform -chdir=${TF_DIR} apply -input=false tfplan"
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
