pipeline {
    agent any

    environment {
        AWS_REGION = "ap-south-1"
        ECR_BACKEND = "212105053723.dkr.ecr.ap-south-1.amazonaws.com/mern-backend"
        ECR_FRONTEND = "212105053723.dkr.ecr.ap-south-1.amazonaws.com/mern-frontend"
        KUBECONFIG = "/home/ubuntu/.kube/config"
    }

    stages {

        stage('Checkout Source') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/jay-2000/eks-mern.git'
            }
        }

        stage('Login to ECR') {
            steps {
                sh '''
                aws ecr get-login-password --region $AWS_REGION | \
                    docker login --username AWS --password-stdin $ECR_BACKEND
                '''
            }
        }

        stage('Build Backend Image') {
            steps {
                sh '''
                cd backend
                docker build -t mern-backend .
                docker tag mern-backend:latest $ECR_BACKEND:latest
                docker push $ECR_BACKEND:latest
                '''
            }
        }

        stage('Build Frontend Image') {
            steps {
                sh '''
                cd frontend
                docker build -t mern-frontend .
                docker tag mern-frontend:latest $ECR_FRONTEND:latest
                docker push $ECR_FRONTEND:latest
                '''
            }
        }

        stage('Deploy to EKS') {
            steps {
                sh '''
                kubectl apply -f k8s/mongodb/
                kubectl apply -f k8s/backend/
                kubectl apply -f k8s/frontend/
                kubectl apply -f k8s/ingress/
                '''
            }
        }
    }
}
