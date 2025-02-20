pipeline {
    agent any

    environment {
        AWS_ACCESS_KEY_ID     = credentials('AWS_ACCESS_KEY_ID')
        AWS_SECRET_ACCESS_KEY = credentials('AWS_SECRET_ACCESS_KEY')
        AWS_REGION            = 'us-east-1'  
        AWS_ACCOUNT_ID        = '851725280627'
        IMAGE_TAG             = "${BUILD_NUMBER}"  // Use unique tag for each build
        IMAGE_REPO_NAME       = "node-app"
        ECR_REPO              = "my-app"
        REPOSITORY_URI        = "851725280627.dkr.ecr.us-east-1.amazonaws.com/my-app"
        ECS_CLUSTER           = "my-ecs-cluster"
        ECS_SERVICE           = "my-service"
        TASK_DEFINITION       = "my-task"
    }

    stages {
        stage('Git Checkout') {
            steps {
                git 'https://github.com/Ashu7072/Terraform-Jenkins-ECS.git'
            }
        }
        
        stage('Logging into AWS ECR') {
            steps {
                script {
                    sh """
                        aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${REPOSITORY_URI}
                    """
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    sh "docker build -t ${IMAGE_REPO_NAME}:${IMAGE_TAG} ."
                }
            }
        }

        stage('Push to ECR') {
            steps {
                script {
                    sh """
                        docker tag ${IMAGE_REPO_NAME}:${IMAGE_TAG} ${REPOSITORY_URI}:${IMAGE_TAG}
                        docker push ${REPOSITORY_URI}:${IMAGE_TAG}
                    """
                }
            }
        }

        stage('Deploy to ECS') {
            steps {
                script {
                    sh """
                        TASK_DEFINITION_JSON=$(aws ecs describe-task-definition --task-definition ${TASK_DEFINITION} --region ${AWS_REGION})
                        NEW_TASK_DEFINITION=$(echo "$TASK_DEFINITION_JSON" | jq --arg IMAGE "${REPOSITORY_URI}:${IMAGE_TAG}" '.taskDefinition | .containerDefinitions[0].image = $IMAGE | del(.taskDefinitionArn, .revision, .status, .requiresAttributes, .compatibilities, .registeredAt, .registeredBy)')
                        echo "$NEW_TASK_DEFINITION" > task-def.json
                        NEW_TASK_INFO=$(aws ecs register-task-definition --region ${AWS_REGION} --cli-input-json file://task-def.json)
                        NEW_REVISION=$(echo "$NEW_TASK_INFO" | jq '.taskDefinition.revision')
                        aws ecs update-service --cluster ${ECS_CLUSTER} --service ${ECS_SERVICE} --task-definition ${TASK_DEFINITION}:${NEW_REVISION} --force-new-deployment
                    """
                }
            }
        }

        stage('Cleanup') {
            steps {
                sh 'rm -rf task-def.json || echo "Already cleaned up"'
                sh 'docker system prune -f'
            }
        }
    }

    post {
        always {
            cleanWs()
        }
    }
}
