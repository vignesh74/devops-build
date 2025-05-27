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
          // Normalize branch name (handle both env.GIT_BRANCH and env.BRANCH_NAME)
          def branchName = env.BRANCH_NAME ?: env.GIT_BRANCH?.replaceAll('origin/', '') ?: 'dev'

          if (branchName == 'master') {
            env.IMAGE_NAME = 'vigourousvig/prod'
            env.IMAGE_TAG = 'prod'
            env.CONTAINER_NAME = 'react-prod'
            env.HOST_PORT = '80'
          } else {
            env.IMAGE_NAME = 'vigourousvig/dev'
            env.IMAGE_TAG = 'latest'
            env.CONTAINER_NAME = 'react-dev'
            env.HOST_PORT = '3000'
          }

          env.EC2_HOST = '3.109.32.221'  // Your EC2 IP

          echo "🚀 Branch: ${branchName}"
          echo "📦 Image: ${env.IMAGE_NAME}:${env.IMAGE_TAG}"
          echo "📦 Container: ${env.CONTAINER_NAME}"
          echo "🌐 EC2 Host: ${env.EC2_HOST} (Port: ${env.HOST_PORT})"
        }
      }
    }

    stage('Docker Build & Push') {
      steps {
        script {
          sh """
            docker build -t ${env.IMAGE_NAME}:${env.IMAGE_TAG} .
            echo ${DOCKERHUB_CREDENTIALS_PSW} | docker login -u ${DOCKERHUB_CREDENTIALS_USR} --password-stdin
            docker push ${env.IMAGE_NAME}:${env.IMAGE_TAG}
          """
        }
      }
    }

    stage('Deploy to EC2') {
      steps {
        script {
          def remote = [
            name: 'EC2',
            host: env.EC2_HOST,
            user: 'ubuntu',
            identityFile: env.SSH_CREDENTIALS,
            allowAnyHosts: true
          ]

          sshCommand remote: remote, command: """
            docker rm -f ${env.CONTAINER_NAME} || true
            docker pull ${env.IMAGE_NAME}:${env.IMAGE_TAG}
            docker run -d --name ${env.CONTAINER_NAME} -p ${env.HOST_PORT}:80 ${env.IMAGE_NAME}:${env.IMAGE_TAG}
          """
        }
      }
    }
  }

  post {
    always {
      echo "✅ Pipeline completed for branch: ${env.BRANCH_NAME ?: env.GIT_BRANCH}"
    }
  }
}

