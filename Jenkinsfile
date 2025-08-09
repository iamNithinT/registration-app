pipeline {
    agent { label 'jenkinsslave' }
    
    tools {
        jdk 'Java17'
        maven 'Maven3'
    }

    environment {
        AWS_REGION = 'ap-south-1'
        ECR_REPO_NAME = 'project-k'        
        IMAGE_TAG = "${BUILD_NUMBER}"
        ECR_URI = "965656372503.dkr.ecr.ap-south-1.amazonaws.com/project-k"
    }

    stages {
        stage("Cleanup Workspace") {
            steps {
                cleanWs()
            }
        }

        stage("Checkout from SCM") {
            steps {
                git branch: 'main', credentialsId: 'github-token', url: 'https://github.com/nithin302001/registration-app.git'
            }
        }

        stage("Clean Target Folder and Compile") {
            steps {
                sh "mvn clean compile"
            }
        }

        stage("Unit Testing") {
            steps {
                sh "mvn test"
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('sonarqube-server') {
                    withCredentials([string(credentialsId: 'jenkins-sonarqube-token', variable: 'SONAR_TOKEN')]) {
                        sh """
                            mvn sonar:sonar \
                            -Dsonar.projectKey=Java-project \
                            -Dsonar.host.url=$SONAR_HOST_URL \
                            -Dsonar.login=$SONAR_TOKEN
                        """
                    }
                }
            }
        }

        stage("Quality Gates") {
            steps {
                script {
                    waitForQualityGate abortPipeline: false, credentialsId: 'jenkins-sonarqube-token'
                }
            }
        }

        stage("Packaging Application") {
            steps {
                sh "mvn package"
            }
        }

        stage("OWASP Dependency-Check") {
            steps {
                dependencyCheck additionalArguments: '', nvdCredentialsId: 'nvd-api-key', odcInstallation: 'OWASP', stopBuild: true
            }
        }

        stage("Nexus Artifact Upload") {
            steps {
                nexusArtifactUploader(
                    artifacts: [[
                        artifactId: 'webapp',
                        classifier: '',
                        file: 'webapp/target/webapp.war',
                        type: 'war'
                    ]],
                    credentialsId: 'nexus-credentials',
                    groupId: 'com.example.maven-project',
                    nexusUrl: '3.110.182.123:8081',
                    nexusVersion: 'nexus3',
                    protocol: 'http',
                    repository: 'maven-snapshots',
                    version: '1.0-SNAPSHOT'
                )
            }
        }

        stage("Build Docker Image") {
            steps {
                sh "docker build -t ${ECR_REPO_NAME}:${IMAGE_TAG} ."
            }
        }

        stage("Push Image To ECR") {
            steps {
                withAWS(credentials: 'aws-credentials', region: "${AWS_REGION}") {
                    sh """
                        aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_URI}
                        docker tag ${ECR_REPO_NAME}:${IMAGE_TAG} ${ECR_URI}:${IMAGE_TAG}
                        docker push ${ECR_URI}:${IMAGE_TAG}
                    """
                }
            }
        }

        stage("Trivy Image Scan") {
            steps {
                withAWS(credentials: 'aws-credentials', region: "${AWS_REGION}") {
                    sh """
                        trivy image --severity HIGH,CRITICAL \
                        --format table \
                        --output trivy-report.txt \
                        ${ECR_URI}:${IMAGE_TAG}
                    """
                }
                archiveArtifacts artifacts: 'trivy-report.txt', allowEmptyArchive: true
            }
        }
    }
}
