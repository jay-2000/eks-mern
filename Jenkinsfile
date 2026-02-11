pipeline {
    agent any

    options {
        timestamps()
        disableConcurrentBuilds()
    }

    environment {
        AWS_REGION     = "ap-south-1"
        AWS_ACCOUNT_ID = "212105053723"
        AWS_PAGER      = ""

        ECR_REGISTRY   = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
        BACKEND_REPO   = "mern-backend"
        FRONTEND_REPO  = "mern-frontend"
        IMAGE_TAG      = "${BUILD_NUMBER}"
        K8S_NAMESPACE  = "default"
        EKS_CLUSTER    = "mern-eks"
    }

    stages {

        stage("Checkout Source") {
            steps {
                checkout scm
            }
        }

        stage("Configure kubeconfig") {
            steps {
                sh '''
                set -e
                aws eks update-kubeconfig \
                  --region $AWS_REGION \
                  --name $EKS_CLUSTER

                kubectl config current-context
                kubectl get nodes
                '''
            }
        }

        stage("Login to Amazon ECR") {
            steps {
                sh '''
                set -e
                aws ecr get-login-password --region $AWS_REGION \
                  | docker login --username AWS --password-stdin $ECR_REGISTRY
                '''
            }
        }

        stage("Build & Push Backend Image") {
            steps {
                sh '''
                set -e
                cd backend
                docker build -t $ECR_REGISTRY/$BACKEND_REPO:$IMAGE_TAG .
                docker push $ECR_REGISTRY/$BACKEND_REPO:$IMAGE_TAG
                '''
            }
        }

        stage("Build & Push Frontend Image") {
            steps {
                sh '''
                set -e
                cd frontend
                docker build -t $ECR_REGISTRY/$FRONTEND_REPO:$IMAGE_TAG .
                docker push $ECR_REGISTRY/$FRONTEND_REPO:$IMAGE_TAG
                '''
            }
        }

        stage("Deploy Backend & Frontend") {
            steps {
                sh '''
                set -e
                export IMAGE_TAG=$IMAGE_TAG

                # Deploy Backend
                envsubst < k8s/backend/backend-deployment.yaml \
                  | kubectl apply -n $K8S_NAMESPACE -f -

                # Deploy Frontend
                envsubst < k8s/frontend/frontend-deployment.yaml \
                  | kubectl apply -n $K8S_NAMESPACE -f -

                # Apply Services (idempotent)
                kubectl apply -f k8s/backend/backend-service.yaml -n $K8S_NAMESPACE
                kubectl apply -f k8s/frontend/frontend-service.yaml -n $K8S_NAMESPACE

                # Apply Ingress
                kubectl apply -f k8s/ingress/mern-ingress.yaml -n $K8S_NAMESPACE
                '''
            }
        }

        stage("Verify Rollouts") {
            steps {
                sh '''
                set -e
                kubectl rollout status deployment/backend -n $K8S_NAMESPACE --timeout=600s
                kubectl rollout status deployment/frontend -n $K8S_NAMESPACE --timeout=300s
                '''
            }
        }

        stage("Verify ALB Health Endpoint") {
            steps {
                sh '''
                set -e

                echo "Waiting for ALB DNS..."
                sleep 30

                ALB_DNS=$(kubectl get ingress mern-ingress -n $K8S_NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

                echo "ALB DNS: $ALB_DNS"

                if [ -z "$ALB_DNS" ]; then
                  echo "ALB not provisioned"
                  exit 1
                fi

                echo "Checking Backend Health via ALB..."
                curl -f http://$ALB_DNS/api/healthz || exit 1
                '''
            }
        }
    }

    post {
        always {
            sh 'docker system prune -af || true'
        }

        success {
            echo "✅ CI/CD completed successfully. IMAGE_TAG=${IMAGE_TAG}"
        }

        failure {
            echo "❌ CI/CD failed. Debug info:"
            sh '''
            kubectl get pods -n $K8S_NAMESPACE -o wide
            kubectl describe pods -n $K8S_NAMESPACE | tail -n 100
            '''
        }
    }
}
