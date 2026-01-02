pipeline {
    agent any

    environment {
        AWS_REGION = "ap-south-1"
        AWS_ACCOUNT_ID = "212105053723"
        ECR_REGISTRY = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

        BACKEND_REPO = "mern-backend"
        FRONTEND_REPO = "mern-frontend"

        IMAGE_TAG = "${BUILD_NUMBER}"
    }

    stages {

        stage("Checkout Source") {
            steps {
                checkout scm
            }
        }

        stage("Login to ECR") {
            steps {
                sh '''
                aws ecr get-login-password --region $AWS_REGION \
                | docker login --username AWS --password-stdin $ECR_REGISTRY
                '''
            }
        }

        stage("Build & Push Backend Image") {
            steps {
                sh '''
                cd backend
                docker build -t $BACKEND_REPO:$IMAGE_TAG .
                docker tag $BACKEND_REPO:$IMAGE_TAG $ECR_REGISTRY/$BACKEND_REPO:$IMAGE_TAG
                docker push $ECR_REGISTRY/$BACKEND_REPO:$IMAGE_TAG
                '''
            }
        }

        stage("Build & Push Frontend Image") {
            steps {
                sh '''
                cd frontend
                docker build -t $FRONTEND_REPO:$IMAGE_TAG .
                docker tag $FRONTEND_REPO:$IMAGE_TAG $ECR_REGISTRY/$FRONTEND_REPO:$IMAGE_TAG
                docker push $ECR_REGISTRY/$FRONTEND_REPO:$IMAGE_TAG
                '''
            }
        }

        stage("Deploy to EKS") {
            steps {
                sh '''
                echo "Updating Kubernetes manifests with image tag ${IMAGE_TAG}"

                sed -i "s|IMAGE_TAG|${IMAGE_TAG}|g" k8s/backend/backend-deployment.yaml
                sed -i "s|IMAGE_TAG|${IMAGE_TAG}|g" k8s/frontend/frontend-deployment.yaml

                kubectl apply -f k8s/mongo/
                kubectl apply -f k8s/backend/
                kubectl apply -f k8s/frontend/
                kubectl apply -f k8s/ingress/
                '''
            }
        }
    }

    post {
        success {
            echo "✅ CI/CD Pipeline completed successfully with IMAGE_TAG=${IMAGE_TAG}"
        }
        failure {
            echo "❌ CI/CD Pipeline failed"
        }
    }
}
