pipeline {
  agent any

  environment {
    DOCKER_CREDENTIALS_ID = 'vigourousvigDocker'
    SSH_CREDENTIALS_ID = 'vigourousvigSSH'
    EC2_HOST = '15.207.86.242'
    CONTAINER_PORT = '80'
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
          def branch = env.BRANCH_NAME ?: env.GIT_BRANCH?.replaceFirst(/^origin\//, '') ?: 'dev'

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

          env.FULL_IMAGE = "${env.IMAGE_NAME}:${env.IMAGE_TAG}"

          echo """
          🔧 Branch: ${branch}
          🐳 Docker Image: ${env.FULL_IMAGE}
          📦 Container Name: ${env.CONTAINER_NAME}
          🌐 Host Port: ${env.HOST_PORT}
          📡 EC2 Host: ${EC2_HOST}
          """
        }
      }
    }

    stage('Build Docker Image') {
      steps {
        script {
          docker.build(env.FULL_IMAGE)
        }
      }
    }

    stage('Push Docker Image') {
      steps {
        withCredentials([usernamePassword(credentialsId: DOCKER_CREDENTIALS_ID, usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
          sh '''
            echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
            docker push ${FULL_IMAGE}
          '''
        }
      }
    }

    stage('Test SSH Connection') {
      steps {
        sshagent([SSH_CREDENTIALS_ID]) {
          sh "ssh -o StrictHostKeyChecking=no ubuntu@${EC2_HOST} 'echo ✅ SSH to EC2 works!'"
        }
      }
    }

    stage('Deploy to EC2') {
      steps {
        sshagent([SSH_CREDENTIALS_ID]) {
          sh """
            ssh -o StrictHostKeyChecking=no ubuntu@${EC2_HOST} '
              echo "🛑 Stopping container if exists: ${CONTAINER_NAME}" &&
              docker stop ${CONTAINER_NAME} || echo "Container not running, skipping stop." &&
              echo "🗑️ Removing container if exists: ${CONTAINER_NAME}" &&
              docker rm ${CONTAINER_NAME} || echo "No container to remove." &&

              echo "⚠️ Checking for processes using port ${HOST_PORT}..." &&
              PORT_IN_USE_PID=\$(sudo lsof -t -i :${HOST_PORT} || true) &&
              if [ ! -z "\$PORT_IN_USE_PID" ]; then
                echo "⚠️ Port ${HOST_PORT} in use by PID(s): \$PORT_IN_USE_PID. Killing process(es)..." &&
                sudo kill -9 \$PORT_IN_USE_PID || echo "Failed to kill process(es) on port ${HOST_PORT}."
              else
                echo "Port ${HOST_PORT} is free."
              fi &&

              echo "⬇️ Pulling image: ${FULL_IMAGE}" &&
              docker pull ${FULL_IMAGE} &&
              echo "▶️ Starting container: ${CONTAINER_NAME}" &&
              docker run -d --name ${CONTAINER_NAME} -p ${HOST_PORT}:${CONTAINER_PORT} ${FULL_IMAGE} &&
              echo "✅ Deployment complete for container: ${CONTAINER_NAME}"
            '
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
