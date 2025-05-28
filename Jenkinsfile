pipeline {
    agent any

    environment {
        DOCKER_HUB_CREDENTIALS = credentials('vigourousvigDocker')
        SSH_CREDENTIALS = credentials('vigourousvigSSH')
        BRANCH_NAME = "${env.BRANCH_NAME}"
        IMAGE_NAME = (BRANCH_NAME == 'master') ? 'vigourousvig/prod:prod' : 'vigourousvig/dev:dev'
        CONTAINER_NAME = (BRANCH_NAME == 'master') ? 'react-prod' : 'react-dev'
        HOST_PORT = "80"
        EC2_HOST = "15.207.86.242"
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
                    echo """
                    🔧 Branch: ${BRANCH_NAME}
                    🐳 Docker Image: ${IMAGE_NAME}
                    📦 Container Name: ${CONTAINER_NAME}
                    🌐 Host Port: ${HOST_PORT}
                    📡 EC2 Host: ${EC2_HOST}
                    """
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                sh "docker build -t ${IMAGE_NAME} ."
            }
        }

        stage('Push Docker Image') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'vigourousvigDocker', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    sh """
                        echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin
                        docker push ${IMAGE_NAME}
                    """
                }
            }
        }

        stage('Test SSH Connection') {
            steps {
                sshagent(['vigourousvigSSH']) {
                    sh "ssh -o StrictHostKeyChecking=no ubuntu@${EC2_HOST} 'echo ✅ SSH to EC2 works!'"
                }
            }
        }

        stage('Deploy to EC2') {
            steps {
                sshagent(['vigourousvigSSH']) {
                    sh """
                        ssh -o StrictHostKeyChecking=no ubuntu@${EC2_HOST} '
                            echo "🛑 Checking and stopping existing container on port 80..." &&
                            CONTAINER_ID=$(docker ps -q --filter "publish=80") &&
                            if [ ! -z "$CONTAINER_ID" ]; then
                                echo "🔍 Port 80 is in use by container: $CONTAINER_ID" &&
                                docker stop $CONTAINER_ID &&
                                docker rm $CONTAINER_ID;
                            else
                                echo "✅ Port 80 is free.";
                            fi &&
                            echo "⬇️ Pulling latest image..." &&
                            docker pull ${IMAGE_NAME} &&
                            echo "🚀 Running new container..." &&
                            docker run -d --name ${CONTAINER_NAME} -p 80:80 ${IMAGE_NAME} &&
                            echo "✅ Deployment complete!"
                        '
                    """
                }
            }
        }
    }

    post {
        failure {
            echo "❌ Deployment failed for branch: ${BRANCH_NAME}"
        }
        success {
            echo "✅ Deployment succeeded for branch: ${BRANCH_NAME}"
        }
    }
}
