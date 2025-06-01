pipeline {
    agent any

    environment {
        DOCKER_HUB_CREDENTIALS_ID = 'vigourousvigDocker'  // just the ID string here
        SSH_CREDENTIALS_ID = 'vigourousvigSSH'            // just the ID string here
        EC2_HOST = "3.110.182.131"
    }

    stages {
        stage('Checkout') {
            steps {
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: "*/${env.BRANCH_NAME}"]],
                    userRemoteConfigs: [[url: 'https://github.com/vignesh74/devops-build.git']],
                    extensions: [[$class: 'CloneOption', noTags: false, shallow: false, depth: 0]]
                ])
            }
        }

        stage('Set Environment Variables') {
            steps {
                script {
                    if (env.BRANCH_NAME == 'master') {
                        env.IMAGE_NAME = 'vigourousvig/prod:prod'
                        env.CONTAINER_NAME = 'react-prod'
                        env.HOST_PORT = '80'
                    } else {
                        env.IMAGE_NAME = 'vigourousvig/dev:dev'
                        env.CONTAINER_NAME = 'react-dev'
                        env.HOST_PORT = '3001'
                    }

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

        stage('Show Commit Message') {
            steps {
                script {
                    def commitMessage = sh(script: "git log -1 --pretty=%B", returnStdout: true).trim()
                    echo "📨 Latest Commit Message: ${commitMessage}"
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
        success {
            echo "✅ Successfully deployed ${env.CONTAINER_NAME} on branch ${env.BRANCH_NAME}"
        }
        failure {
            echo "❌ Deployment failed on branch ${env.BRANCH_NAME}"
        }
    }
}
