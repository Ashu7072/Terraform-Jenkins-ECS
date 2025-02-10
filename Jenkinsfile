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
        repo_name       = "node-app"
        cluster_name    = "my-ecs-cluster"
        task_def_name   = "my-task"
    }

   agent  any
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
    }

        stage('Build') {
            steps {
                script {
                    sh "docker build --build-arg ENV_PROFILE=${environment} -t ${repo_name}:latest ."
                }
            }
        }

        stage('Deploy To ECR') {
            steps {
                script {
                    withAWS(credentials: "aws-${app}-${environment}", region: "${region}") {
                        sh """
                            aws ecr get-login-password --region ${region} | docker login --username AWS --password-stdin ${aws_account_id}.dkr.ecr.${region}.amazonaws.com
                            docker tag ${repo_name}:latest ${aws_account_id}.dkr.ecr.${region}.amazonaws.com/${repo_name}:${BUILD_NUMBER}
                            docker push ${aws_account_id}.dkr.ecr.${region}.amazonaws.com/${repo_name}:${BUILD_NUMBER}
                        """
                    }
                }
            }
        }

        stage('Deploy To ECS') {
            steps {
                script {
                    withAWS(credentials: "aws-${app}-${environment}", region: "${region}") {
                        sh """
                            TASK_DEFINITION=$( aws ecs describe-task-definition --task-definition ${task_def_name} --region=${region} )
                            NEW_TASK_DEFINITION=$( echo $TASK_DEFINITION | jq --arg IMAGE "${aws_account_id}.dkr.ecr.${region}.amazonaws.com/${repo_name}:${BUILD_NUMBER}" '.taskDefinition | .containerDefinitions[0].image = $IMAGE | del(.taskDefinitionArn) | del(.revision) | del(.status) | del(.requiresAttributes) | del(.compatibilities) | del(.registeredAt) | del(.registeredBy)' )
                            echo $NEW_TASK_DEFINITION > task-def.json
                            NEW_TASK_INFO=$(aws ecs register-task-definition --region ${region} --cli-input-json file://task-def.json)
                            NEW_REVISION=$(echo $NEW_TASK_INFO | jq '.taskDefinition.revision')
                            aws ecs update-service --cluster ${cluster_name} --service ${service} --task-definition ${task_def_name}:${NEW_REVISION} --force-new-deployment
                        """
                    }
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

