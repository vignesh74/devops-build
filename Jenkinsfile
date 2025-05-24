pipeline {
    agent any

    environment {
        DOCKER_CREDENTIALS_ID = 'vigourousvigDocker'
        SSH_CREDENTIALS_ID = 'vigourousvigSSH'
        IMAGE_NAME = 'vigourousvig/react-devops-build'
    }

    stages {
        stage('Clone') {
            steps {
                git branch: env.BRANCH_NAME, url: 'https://github.com/vignesh74/devops-build'
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    sh 'docker build -t $IMAGE_NAME:latest .'
                }
            }
        }

        stage('Login to Docker Hub') {
            steps {
                withCredentials([usernamePassword(credentialsId: "${DOCKER_CREDENTIALS_ID}", usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    sh 'echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin'
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                script {
                    def targetRepo = env.BRANCH_NAME == 'master' ? 'vigourousvig/prod' : 'vigourousvig/dev'
                    sh "docker tag $IMAGE_NAME:latest $targetRepo:latest"
                    sh "docker push $targetRepo:latest"
                }
            }
        }

        stage('Deploy to EC2') {
            steps {
                sshagent (credentials: ["${SSH_CREDENTIALS_ID}"]) {
                    sh "ssh -o StrictHostKeyChecking=no -i /Users/vignesh/Desktop/160525.pem ubuntu@13.127.193.148 'bash -s' < scripts/deploy.sh"
                }
            }
        }
    }
}

