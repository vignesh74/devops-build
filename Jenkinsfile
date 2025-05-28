pipeline {
  agent any

  environment {
    DOCKER_CREDENTIALS_ID = 'vigourousvigDocker'
    SSH_CREDENTIALS_ID = 'vigourousvigSSH'
    EC2_HOST = '15.207.86.242'
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
          def branch = env.BRANCH_NAME ?: env.GIT_BRANCH?.replaceAll('origin/', '') ?: 'dev'

          if (branch == 'master') {
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

          env.CONTAINER_PORT = '80'

          echo "Branch: ${branch}"
          echo "Docker Image: ${env.IMAGE_NAME}:${env.IMAGE_TAG}"
          echo "Container Name: ${env.CONTAINER_NAME}"
          echo "Host Port: ${env.HOST_PORT}"
          echo "Deploying to EC2 Host: ${EC2_HOST}"
        }
      }
    }

    stage('Build Docker Image') {
      steps {
        script {
          docker.build("${env.IMAGE_NAME}:${env.IMAGE_TAG}")
        }
      }
    }

    stage('Push Docker Image') {
      steps {
        withCredentials([usernamePassword(credentialsId: "${DOCKER_CREDENTIALS_ID}", usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
          sh """
            echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
            docker push ${env.IMAGE_NAME}:${env.IMAGE_TAG}
          """
        }
      }
    }

    stage('Test SSH Connection') {
      steps {
        script {
          sshagent(credentials: ['vigourousvigSSH']) {
            sh "ssh -o StrictHostKeyChecking=no ubuntu@${EC2_HOST} 'echo ✅ SSH to EC2 works!'"
          }
        }
      }
    }

    stage('Deploy to EC2') {
      steps {
        sshagent([SSH_CREDENTIALS_ID]) {
          sh """
            ssh -o StrictHostKeyChecking=no ubuntu@${EC2_HOST} \\
              "docker rm -f ${env.CONTAINER_NAME} || true && \\
               docker pull ${env.IMAGE_NAME}:${env.IMAGE_TAG} && \\
               docker run -d --name ${env.CONTAINER_NAME} -p ${env.HOST_PORT}:${env.CONTAINER_PORT} ${env.IMAGE_NAME}:${env.IMAGE_TAG}"
          """
        }
      }
    }
  }

  post {
    success {
      echo "✅ Deployment successful for branch: ${env.BRANCH_NAME ?: env.GIT_BRANCH}"
    }
    failure {
      echo "❌ Deployment failed for branch: ${env.BRANCH_NAME ?: env.GIT_BRANCH}"
    }
  }
}
