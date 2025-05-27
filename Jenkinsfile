pipeline {
  agent any

  environment {
    DOCKERHUB_CREDENTIALS = credentials('vigourousvigDocker')
    SSH_CREDENTIALS = credentials('vigourousvigSSH')
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
          BRANCH_NAME = env.GIT_BRANCH?.replaceAll('origin/', '') ?: 'dev'

          if (BRANCH_NAME == 'master') {
            IMAGE_NAME = 'vigourousvig/prod'
            IMAGE_TAG = 'prod'
            CONTAINER_NAME = 'react-prod'
            HOST_PORT = '80'
          } else {
            IMAGE_NAME = 'vigourousvig/dev'
            IMAGE_TAG = 'latest'
            CONTAINER_NAME = 'react-dev'
            HOST_PORT = '3000'
          }

          EC2_HOST = '3.109.32.221'  // Your EC2 instance IP

          echo "🚀 Branch: ${BRANCH_NAME}"
          echo "📦 Image: ${IMAGE_NAME}:${IMAGE_TAG}"
          echo "📦 Container: ${CONTAINER_NAME}"
          echo "🌐 EC2 Host: ${EC2_HOST} (Port: ${HOST_PORT})"
        }
      }
    }

    stage('Docker Build & Push') {
      steps {
        script {
          sh """
            docker build -t $IMAGE_NAME:$IMAGE_TAG .
            echo $DOCKERHUB_CREDENTIALS_PSW | docker login -u $DOCKERHUB_CREDENTIALS_USR --password-stdin
            docker push $IMAGE_NAME:$IMAGE_TAG
          """
        }
      }
    }

    stage('Deploy to EC2') {
      steps {
        script {
          def remote = [
            name: 'EC2',
            host: EC2_HOST,
            user: 'ubuntu',
            identityFile: SSH_CREDENTIALS,
            allowAnyHosts: true
          ]

          sshCommand remote: remote, command: """
            docker rm -f $CONTAINER_NAME || true
            docker pull $IMAGE_NAME:$IMAGE_TAG
            docker run -d --name $CONTAINER_NAME -p $HOST_PORT:80 $IMAGE_NAME:$IMAGE_TAG
          """
        }
      }
    }
  }

  post {
    always {
      echo "✅ Pipeline completed for branch: ${env.GIT_BRANCH}"
    }
  }
}

