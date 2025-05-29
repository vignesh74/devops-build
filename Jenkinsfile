pipeline {
    agent any

    environment {
        DOCKER_HUB_CREDENTIALS = credentials('vigourousvigDocker')
        SSH_CREDENTIALS = credentials('vigourousvigSSH')
        HOST_PORT = "80"
        EC2_HOST = "43.205.239.244"
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
                withCredentials([usernamePassword(credentialsId: "${env.DOCKER_HUB_CREDENTIALS}", usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    sh """
                        echo \$DOCKER_PASS | docker login -u \$DOCKER_USER --password-stdin
                        docker push ${env.IMAGE_NAME}
                    """
                }
            }
        }

        stage('Test SSH Connection') {
            steps {
                sshagent([env.SSH_CREDENTIALS]) {
                    sh "ssh -o StrictHostKeyChecking=no ubuntu@${env.EC2_HOST} 'echo ✅ SSH to EC2 works!'"
                }
            }
        }

        stage('Deploy to EC2') {
            steps {
                sshagent([env.SSH_CREDENTIALS]) {
                    sh """
                        ssh -o StrictHostKeyChecking=no ubuntu@${env.EC2_HOST} << 'EOF'
                            echo '🛑 Checking for existing container named ${CONTAINER_NAME}...'
                            if docker ps -a --format '{{.Names}}' | grep -Eq '^${CONTAINER_NAME}\$'; then
                                echo '🔍 Found existing container. Removing it...'
                                docker stop ${CONTAINER_NAME}
                                docker rm ${CONTAINER_NAME}
                                echo '✅ Old container removed.'
                            else
                                echo '✅ No existing container with name ${CONTAINER_NAME}.'
                            fi

                            echo '⬇️ Pulling latest image...'
                            docker pull ${IMAGE_NAME}

                            echo '🚀 Running new container...'
                            docker run -d --name ${CONTAINER_NAME} -p ${HOST_PORT}:80 ${IMAGE_NAME}

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
