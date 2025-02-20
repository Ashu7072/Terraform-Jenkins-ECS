pipeline {
    agent any

    environment {
        AWS_ACCESS_KEY_ID     = credentials('AWS_ACCESS_KEY_ID')
        AWS_SECRET_ACCESS_KEY = credentials('AWS_SECRET_ACCESS_KEY')
        AWS_REGION            = 'us-east-1'  
        ECR_REPO              = 'your-ecr-repository-name'
        AWS_ACCOUNT_ID        = '851725280627'
        IMAGE_TAG             = "latest"
        IMAGE_REPO_NAME       = "node-app"
        cluster_name          = "my-ecs-cluster"
        ECS_SERVICE           = 'my-service'
        task_def_name         = "my-task"
        REPOSITORY_URI        = "851725280627.dkr.ecr.us-east-1.amazonaws.com/my-app"
    }

    stages {
        stage('git checkout') {
            steps {
                git 'https://github.com/Ashu7072/Terraform-Jenkins-ECS.git'
            }
        }
        
        stage('logging into AWS ECR') {
            steps{
                script{
                    sh """aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 851725280627.dkr.ecr.us-east-1.amazonaws.com/my-app"""
                }
            }
        }

        stage('building image') {
            steps {
                script {
                    dockerImage = docker.build "${IMAGE_REPO_NAME}:${IMAGE_TAG}"
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
                            TASK_DEFINITION=$( aws ecs describe-task-definition --task-definition ${task_def_name} --region=${AWS_REGION} )
                            NEW_TASK_DEFINITION=$( echo $TASK_DEFINITION | jq --arg IMAGE "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${IMAGE_REPO_NAME}:${BUILD_NUMBER}" '.taskDefinition | .containerDefinitions[0].image = $IMAGE | del(.taskDefinitionArn) | del(.revision) | del(.status) | del(.requiresAttributes) | del(.compatibilities) | del(.registeredAt) | del(.registeredBy)' )
                            echo $NEW_TASK_DEFINITION > task-def.json
                            NEW_TASK_INFO=$(aws ecs register-task-definition --region ${AWS_REGION} --cli-input-json file://task-def.json)
                            NEW_REVISION=$(echo $NEW_TASK_INFO | jq '.taskDefinition.revision')
                            aws ecs update-service --cluster ${cluster_name} --service ${ECS_SERVICE} --task-definition ${task_def_name}:${NEW_REVISION} --force-new-deployment
                        """
                }
            }
        }

        stage('Cleanup') {
            steps {
                sh 'rm -rf task-def.json || echo "already cleaned up"'
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