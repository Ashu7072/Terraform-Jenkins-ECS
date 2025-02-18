pipeline {

    parameters {
        booleanParam(name: 'autoApprove', defaultValue: false, description: 'Automatically run apply after generating plan?')
    } 
    environment {
        AWS_ACCESS_KEY_ID     = credentials('AWS_ACCESS_KEY_ID')
        AWS_SECRET_ACCESS_KEY = credentials('AWS_SECRET_ACCESS_KEY')
        AWS_REGION = 'us-east-1' 
        AWS_ACCOUNT_ID = '851725280627'
        IMAGE_TAG = "latest"
        TF_DIR = 'terraform'
        IMAGE_REPO_NAME       = "node-app"
        cluster_name    = "my-ecs-cluster"
        task_def_name   = "my-task"
        REPOSITORY_URI  = "851725280627.dkr.ecr.us-east-1.amazonaws.com/node-app"
    }

    agent any
    stages {
        stage('checkout') {
            steps {
                 script{
                        dir("terraform")
                        {
                            git "https://github.com/Ashu7072/Terraform-Jenkins-ECS.git"
                        }
                    }
                }
            }
        stage('Plan') {
            steps {
                sh 'pwd;cd terraform/ ; terraform init'
                sh "pwd;cd terraform/ ; terraform plan -out tfplan"
                sh 'pwd;cd terraform/ ; terraform show -no-color tfplan > tfplan.txt'
            }
        }
        stage('Approval') {
           when {
               not {
                   equals expected: true, actual: params.autoApprove
               }
           }

           steps {
               script {
                    def plan = readFile 'terraform/tfplan.txt'
                    input message: "Do you want to apply the plan?",
                    parameters: [text(name: 'Plan', description: 'Please review the plan', defaultValue: plan)]
               }
           }
       }

        stage('Apply') {
            steps {
                sh "pwd;cd terraform/ ; terraform apply -input=false tfplan"
            }
        }

        stage('logging into AWS ECR') {
            steps{
                script{
                    sh """aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 851725280627.dkr.ecr.us-east-1.amazonaws.com"""
                }
            }
        }

        stage('building image') {
            steps {
                script {
                    dockerImage = docker.build "${REPO_NAME}:${IMAGE_TAG}"
                }
            }
        }

        stage('Push to ECR') {
            steps {
                script {
                    sh """docker tag ${IMAGE_REPO_NAME}:${IMAGE_TAG} ${REPOSITORY_URI}:$IMAGE_TAG"""
                    sh """docker push ${IMAGE_REPO_NAME}.dkr.ecr.${AWS_REGION}.amazonaws.com/${IMAGE_REPO_NAME}:${IMAGE_TAG}"""
                }
            }
        }

        stage('Deploy To ECS') {
            steps {
                script {
                        sh """
                            TASK_DEFINITION=\$( aws ecs describe-task-definition --task-definition ${app}-${environment}-ecs-task --region=${AWS_REGION} )
                            NEW_TASK_DEFINITION=\$( echo \$TASK_DEFINITION | jq --arg IMAGE "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${app}-${environment}-ecr-repo:${BUILD_NUMBER}" '.taskDefinition | .containerDefinitions[0].image = \$IMAGE | del(.taskDefinitionArn) | del(.revision) | del(.status) | del(.requiresAttributes) | del(.compatibilities) |  del(.registeredAt)  | del(.registeredBy)' )
                            echo \$NEW_TASK_DEFINITION > task-def.json
                            NEW_TASK_INFO=\$(aws ecs register-task-definition --region ${AWS_REGION} --cli-input-json file://task-def.json)
                            NEW_REVISION=\$(echo \$NEW_TASK_INFO | jq '.taskDefinition.revision')
                            aws ecs update-service --cluster ${app}-${environment}-cluster --service ${app}-${environment}-ecs-service --task-definition ${app}-${environment}-ecs-task:\${NEW_REVISION} --force-new-deployment
                        """
                }
            }
        }
    }   
}


