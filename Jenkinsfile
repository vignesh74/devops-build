pipeline {
    agent any

    environment {
        DOCKER_HUB_CREDENTIALS_ID = 'vigourousvigDocker'  // just the ID string here
        SSH_CREDENTIALS_ID = 'vigourousvigSSH'            // just the ID string here
        HOST_PORT = "80"
        EC2_HOST = "3.110.182.131"
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Set Variables') {
            steps {
                script {
                    env.IMAGE_NAME = (env.BRANCH_NAME == 'master') ? 'vigourousvig/prod:prod' : 'vigourousvig/dev:dev'
                    env.CONTAINER_NAME = (env.BRANCH_NAME == 'master') ? 'react-prod' : 'react-dev'

                    echo """
                    🔧 Branch: ${env.BRANCH_NAME}
                    🐳 Docker Image: ${env.IMAGE_NAME}
                    📦 Container Name: ${env.CONTAINER_NAME}
                    🌐 Host Port: ${env.HOST_PORT}
                    📡 EC2 Host: ${env.EC2_HOST}
                    """
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                sh "docker build -t ${env.IMAGE_NAME} ."
            }
        }

        stage('Push Docker Image') {
            steps {
                withCredentials([usernamePassword(credentialsId: env.DOCKER_HUB_CREDENTIALS_ID, usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    sh """
                        echo \$DOCKER_PASS | docker login -u \$DOCKER_USER --password-stdin
                        docker push ${env.IMAGE_NAME}
                    """
                }
            }
        }

        stage('Test SSH Connection') {
            steps {
                sshagent([env.SSH_CREDENTIALS_ID]) {
                    sh "ssh -o StrictHostKeyChecking=no ubuntu@${env.EC2_HOST} 'echo ✅ SSH to EC2 works!'"
                }
            }
        }

        stage('Deploy to EC2') {
            steps {
                sshagent([env.SSH_CREDENTIALS_ID]) {
                    sh """
                        ssh -o StrictHostKeyChecking=no ubuntu@${env.EC2_HOST} << EOF
                            echo '🛑 Checking for existing container named ${env.CONTAINER_NAME}...'
                            if docker ps -a --format '{{.Names}}' | grep -Eq '^${env.CONTAINER_NAME}\$'; then
                                echo '🔍 Found existing container. Removing it...'
                                docker stop ${env.CONTAINER_NAME}
                                docker rm ${env.CONTAINER_NAME}
                                echo '✅ Old container removed.'
                            else
                                echo '✅ No existing container with name ${env.CONTAINER_NAME}.'
                            fi

                            echo '⬇️ Pulling latest image...'
                            docker pull ${env.IMAGE_NAME}

                            echo '🚀 Running new container...'
                            docker run -d --name ${env.CONTAINER_NAME} -p ${env.HOST_PORT}:80 ${env.IMAGE_NAME}

                            echo '✅ Deployment complete!'
EOF
                    """
                }
            }
        }
    }

    post {
        failure {
            echo "❌ Deployment failed for branch: ${env.BRANCH_NAME}"
        }
        success {
            echo "✅ Deployment succeeded for branch: ${env.BRANCH_NAME}"
        }
    }
}
