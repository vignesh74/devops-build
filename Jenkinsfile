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
                withCredentials([usernamePassword(credentialsId: 'vigourousvigDocker', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    sh """
                        echo \$DOCKER_PASS | docker login -u \$DOCKER_USER --password-stdin
                        docker push ${env.IMAGE_NAME}
                    """
                }
            }
        }

        stage('Test SSH Connection') {
            steps {
                sshagent(['vigourousvigSSH']) {
                    sh "ssh -o StrictHostKeyChecking=no ubuntu@${env.EC2_HOST} 'echo ✅ SSH to EC2 works!'"
                }
            }
        }

        stage('Deploy to EC2') {
            steps {
                sshagent(['vigourousvigSSH']) {
                    sh """
                        ssh -o StrictHostKeyChecking=no ubuntu@${env.EC2_HOST} << EOF
                            echo '🛑 Checking for existing container named ${env.CONTAINER_NAME}...'
                            if [ \$(docker ps -a -q -f name=${env.CONTAINER_NAME}) ]; then
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