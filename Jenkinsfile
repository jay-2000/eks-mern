// pipeline {
//     agent any

//     environment {
//         AWS_REGION = "ap-south-1"
//         AWS_ACCOUNT_ID = "212105053723"
//         ECR_REGISTRY = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

//         BACKEND_REPO = "mern-backend"
//         FRONTEND_REPO = "mern-frontend"

//         IMAGE_TAG = "${BUILD_NUMBER}"
//     }

//     stages {

//         stage("Checkout Source") {
//             steps {
//                 checkout scm
//             }
//         }

//         stage("Login to ECR") {
//             steps {
//                 sh '''
//                 aws ecr get-login-password --region $AWS_REGION \
//                 | docker login --username AWS --password-stdin $ECR_REGISTRY
//                 '''
//             }
//         }

//         stage("Build & Push Backend Image") {
//             steps {
//                 sh '''
//                 cd backend
//                 docker build -t $BACKEND_REPO:$IMAGE_TAG .
//                 docker tag $BACKEND_REPO:$IMAGE_TAG $ECR_REGISTRY/$BACKEND_REPO:$IMAGE_TAG
//                 docker push $ECR_REGISTRY/$BACKEND_REPO:$IMAGE_TAG
//                 '''
//             }
//         }

//         stage("Build & Push Frontend Image") {
//             steps {
//                 sh '''
//                 cd frontend
//                 docker build -t $FRONTEND_REPO:$IMAGE_TAG .
//                 docker tag $FRONTEND_REPO:$IMAGE_TAG $ECR_REGISTRY/$FRONTEND_REPO:$IMAGE_TAG
//                 docker push $ECR_REGISTRY/$FRONTEND_REPO:$IMAGE_TAG
//                 '''
//             }
//         }

//         stage("Deploy to EKS") {
//             steps {
//                 sh '''
//                 echo "Updating Kubernetes manifests with image tag ${IMAGE_TAG}"

//                 sed -i "s|IMAGE_TAG|${IMAGE_TAG}|g" k8s/backend/backend-deployment.yaml
//                 sed -i "s|IMAGE_TAG|${IMAGE_TAG}|g" k8s/frontend/frontend-deployment.yaml

//                 kubectl apply -f k8s/mongo/
//                 kubectl apply -f k8s/backend/
//                 kubectl apply -f k8s/frontend/
//                 kubectl apply -f k8s/ingress/
//                 '''
//             }
//         }
//     }

//     post {
//         success {
//             echo "✅ CI/CD Pipeline completed successfully with IMAGE_TAG=${IMAGE_TAG}"
//         }
//         failure {
//             echo "❌ CI/CD Pipeline failed"
//         }
//     }
// }


// pipeline {
//     agent any

//     options {
//         timestamps()
//         ansiColor('xterm')
//     }

//     environment {
//         AWS_REGION     = "ap-south-1"
//         AWS_ACCOUNT_ID = "212105053723"
//         ECR_REGISTRY   = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

//         BACKEND_REPO   = "mern-backend"
//         FRONTEND_REPO  = "mern-frontend"

//         IMAGE_TAG      = "${BUILD_NUMBER}"
//         K8S_NAMESPACE  = "default"
//     }

//     stages {

//         stage("Checkout Source") {
//             steps {
//                 checkout scm
//             }
//         }

//         stage("Login to Amazon ECR") {
//             steps {
//                 sh '''
//                 set -e
//                 aws ecr get-login-password --region $AWS_REGION \
//                   | docker login --username AWS --password-stdin $ECR_REGISTRY
//                 '''
//             }
//         }

//         stage("Build & Push Backend Image") {
//             steps {
//                 sh '''
//                 set -e
//                 cd backend
//                 docker build -t $BACKEND_REPO:$IMAGE_TAG .
//                 docker tag  $BACKEND_REPO:$IMAGE_TAG \
//                             $ECR_REGISTRY/$BACKEND_REPO:$IMAGE_TAG
//                 docker push $ECR_REGISTRY/$BACKEND_REPO:$IMAGE_TAG
//                 '''
//             }
//         }

//         stage("Build & Push Frontend Image") {
//             steps {
//                 sh '''
//                 set -e
//                 cd frontend
//                 docker build -t $FRONTEND_REPO:$IMAGE_TAG .
//                 docker tag  $FRONTEND_REPO:$IMAGE_TAG \
//                             $ECR_REGISTRY/$FRONTEND_REPO:$IMAGE_TAG
//                 docker push $ECR_REGISTRY/$FRONTEND_REPO:$IMAGE_TAG
//                 '''
//             }
//         }

//         stage("Deploy to EKS") {
//             steps {
//                 sh '''
//                 set -e
//                 echo "🚀 Deploying IMAGE_TAG=${IMAGE_TAG}"

//                 sed -i "s|IMAGE_TAG|${IMAGE_TAG}|g" \
//                     k8s/backend/backend-deployment.yaml \
//                     k8s/frontend/frontend-deployment.yaml

//                 kubectl apply -f k8s/mongo/
//                 kubectl apply -f k8s/backend/
//                 kubectl apply -f k8s/frontend/
//                 kubectl apply -f k8s/ingress/
//                 '''
//             }
//         }

//         stage("Verify Kubernetes Rollout") {
//             steps {
//                 sh '''
//                 set -e
//                 echo "🔍 Waiting for backend rollout..."
//                 kubectl rollout status deployment/backend \
//                   -n $K8S_NAMESPACE --timeout=300s

//                 echo "🔍 Waiting for frontend rollout..."
//                 kubectl rollout status deployment/frontend \
//                   -n $K8S_NAMESPACE --timeout=300s

//                 echo "📦 Checking pod status..."
//                 kubectl get pods -n $K8S_NAMESPACE

//                 echo "✅ Kubernetes deployment successful"
//                 '''
//             }
//         }
//     }

//     post {
//         success {
//             echo "✅ CI/CD pipeline completed successfully with IMAGE_TAG=${IMAGE_TAG}"
//         }

//         failure {
//             echo "❌ CI/CD pipeline failed — collecting diagnostics"

//             sh '''
//             kubectl get deploy -n $K8S_NAMESPACE
//             kubectl get pods -n $K8S_NAMESPACE
//             kubectl describe pods -n $K8S_NAMESPACE | tail -n 100
//             '''
//         }
//     }
// }
// pipeline {
//     agent any

//     options {
//         timestamps()
//         ansiColor('xterm')
//         disableConcurrentBuilds()
//     }

//     environment {
//         AWS_REGION     = "ap-south-1"
//         AWS_ACCOUNT_ID = "212105053723"
//         ECR_REGISTRY   = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

//         BACKEND_REPO   = "mern-backend"
//         FRONTEND_REPO  = "mern-frontend"

//         IMAGE_TAG      = "${BUILD_NUMBER}"
//         K8S_NAMESPACE  = "default"
//         EKS_CLUSTER    = "mern-eks"
//     }

//     stages {

//         stage("Checkout Source") {
//             steps {
//                 checkout scm
//             }
//         }

//         stage("Configure kubeconfig") {
//             steps {
//                 sh '''
//                 set -e
//                 aws eks update-kubeconfig \
//                   --region $AWS_REGION \
//                   --name $EKS_CLUSTER
//                 kubectl config current-context
//                 '''
//             }
//         }

//         stage("Login to Amazon ECR") {
//             steps {
//                 sh '''
//                 set -e
//                 aws ecr get-login-password --region $AWS_REGION \
//                   | docker login --username AWS --password-stdin $ECR_REGISTRY
//                 '''
//             }
//         }

//         stage("Build & Push Backend Image") {
//             steps {
//                 sh '''
//                 set -e
//                 cd backend
//                 docker build -t $ECR_REGISTRY/$BACKEND_REPO:$IMAGE_TAG .
//                 docker push $ECR_REGISTRY/$BACKEND_REPO:$IMAGE_TAG
//                 '''
//             }
//         }

//         stage("Build & Push Frontend Image") {
//             steps {
//                 sh '''
//                 set -e
//                 cd frontend
//                 docker build -t $ECR_REGISTRY/$FRONTEND_REPO:$IMAGE_TAG .
//                 docker push $ECR_REGISTRY/$FRONTEND_REPO:$IMAGE_TAG
//                 '''
//             }
//         }

//         stage("Deploy to EKS") {
//             steps {
//                 sh '''
//                 set -e
//                 export IMAGE_TAG=$IMAGE_TAG

//                 envsubst < k8s/backend/backend-deployment.yaml | kubectl apply -f -
//                 envsubst < k8s/frontend/frontend-deployment.yaml | kubectl apply -f -

//                 kubectl apply -f k8s/mongo/
//                 kubectl apply -f k8s/ingress/
//                 '''
//             }
//         }

//         stage("Verify Kubernetes Rollout") {
//             steps {
//                 sh '''
//                 set -e
//                 kubectl rollout status deployment/backend -n $K8S_NAMESPACE --timeout=300s
//                 kubectl rollout status deployment/frontend -n $K8S_NAMESPACE --timeout=300s
//                 kubectl get pods -n $K8S_NAMESPACE
//                 '''
//             }
//         }
//     }

//     post {
//         always {
//             sh 'docker system prune -af || true'
//         }

//         success {
//             echo "✅ CI/CD pipeline completed successfully with IMAGE_TAG=${IMAGE_TAG}"
//         }

//         failure {
//             echo "❌ CI/CD pipeline failed"
//             sh '''
//             kubectl get pods -n $K8S_NAMESPACE
//             kubectl describe pods -n $K8S_NAMESPACE | tail -n 50
//             '''
//         }
//     }
// }
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

        stage("Deploy MongoDB") {
            steps {
                sh '''
                set -e
                kubectl apply -f k8s/mongo/
                kubectl rollout status statefulset/mongodb -n default --timeout=300s
                '''
            }
        }

        stage("Deploy Backend & Frontend") {
            steps {
                sh '''
                set -e
                export IMAGE_TAG=$IMAGE_TAG

                envsubst < k8s/backend/backend-deployment.yaml | kubectl apply -n $K8S_NAMESPACE -f -
                envsubst < k8s/frontend/frontend-deployment.yaml | kubectl apply -n $K8S_NAMESPACE -f -

                kubectl apply -f k8s/ingress/ -n $K8S_NAMESPACE
                '''
            }
        }

        stage("Verify Kubernetes Rollout") {
            steps {
                sh '''
                set -e
                kubectl rollout status deployment/backend -n $K8S_NAMESPACE --timeout=600s
                kubectl rollout status deployment/frontend -n $K8S_NAMESPACE --timeout=300s
                kubectl get pods -n $K8S_NAMESPACE -o wide
                '''
            }
        }
    }

    post {
        always {
            sh 'docker system prune -af || true'
        }

        success {
            echo "✅ CI/CD pipeline completed successfully with IMAGE_TAG=${IMAGE_TAG}"
        }

        failure {
            echo "❌ CI/CD pipeline failed"
            sh '''
            kubectl get pods -n $K8S_NAMESPACE
            kubectl describe pods -n $K8S_NAMESPACE | tail -n 80
            '''
        }
    }
}
