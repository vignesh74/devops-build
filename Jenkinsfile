pipeline {
  agent any

  environment {
    DOCKERHUB_CREDENTIALS = credentials('vigourousvigDocker')
    SSH_CREDENTIALS = credentials('vigourousvigSSH')
    IMAGE_NAME = 'vigourousvig/dev'
    CONTAINER_NAME = 'react-app'
  }

  stages {
    stage('Checkout') {
      steps {
        git branch: 'dev', url: 'https://github.com/vignesh74/devops-build.git'
      }
    }

    stage('Docker Build & Push') {
      steps {
        script {
          def tag = "latest"
          sh """
            docker build -t $IMAGE_NAME:$tag .
            echo $DOCKERHUB_CREDENTIALS_PSW | docker login -u $DOCKERHUB_CREDENTIALS_USR --password-stdin
            docker push $IMAGE_NAME:$tag
          """
        }
      }
    }

    stage('Deploy to EC2') {
      steps {
        script {
          def remote = [
            name: 'EC2',
            host: '3.109.32.221',
            user: 'ubuntu',
            identityFile: SSH_CREDENTIALS,
            allowAnyHosts: true
          ]
          sshCommand remote: remote, command: """
            docker rm -f $CONTAINER_NAME || true
            docker pull $IMAGE_NAME:latest
            docker run -d --name $CONTAINER_NAME -p 80:80 $IMAGE_NAME:latest
          """
        }
      }
    }
  }

  post {
    always {
      echo "✅ Pipeline completed for branch: dev"
    }
  }
}

