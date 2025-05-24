pipeline {
    agent any

    environment {
        DOCKER_HUB_CREDENTIALS = credentials('vigourousvigDocker') // Your Jenkins Docker Hub credential ID
        IMAGE_NAME = 'vigourousvig/react-devops-build'
    }

    stages {
        stage('Setup Buildx') {
            steps {
                sh '''
                    docker buildx create --use || true
                    docker buildx inspect --bootstrap
                '''
            }
        }
        stage('Build & Push Multi-Arch Image') {
            steps {
                sh """
                docker login -u ${DOCKER_HUB_CREDENTIALS_USR} -p ${DOCKER_HUB_CREDENTIALS_PSW}
                docker buildx build --platform linux/amd64,linux/arm64 -t ${IMAGE_NAME}:latest --push .
                """
            }
        }
    }
}

