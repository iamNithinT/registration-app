pipeline {
    agent { label 'Jenkins-Agent' }
    
    tools {
        jdk 'Java17'
        maven 'Maven'
    }
     environment {
        DOCKER_IMAGE = "nithinnito/registration-app:${env.BUILD_NUMBER}"
        DOCKER_CREDENTIALS_ID = 'dockerhub-credentials'  // Jenkins credentials ID for Docker Hub
    }
    
    stages {
        stage("Cleanup Workspace") {
            steps {
                cleanWs()
            }
        }
        
        stage("Checkout from SCM") {
            steps {
                git branch: 'main', credentialsId: 'Github', url: 'https://github.com/iamNithinT/registration-app.git'
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
                            mvn clean verify sonar:sonar \
                            -Dsonar.projectKey=registration-app \
                            -Dsonar.projectName='registration-app' \
                            -Dsonar.host.url=http://172.31.8.50:9000 \
                            -Dsonar.login=$SONAR_TOKEN
                        """
                    }
                }
            }
        }
        stage("Quality Gates") {
            steps {
                script {
                    waitForQualityGate abortPipeline: true, credentialsId: 'jenkins-sonarqube-token'
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
                dependencyCheck additionalArguments: '', nvdCredentialsId: 'nvd-api-key', odcInstallation: 'OWASP-Dependency-Check', stopBuild: true
            }
        }
        stage('Nexus Artifact Upload') {
            steps {
                script {
                    def pom = readMavenPom file: 'pom.xml'

                    // Ensure SNAPSHOT is preserved at the end
                    def baseVersion = pom.version.replace('-SNAPSHOT','')
                    def dynamicVersion = "${baseVersion}-${env.BUILD_NUMBER}-SNAPSHOT"

                    echo "Uploading artifacts with version: ${dynamicVersion}"

                    nexusArtifactUploader(
                        nexusVersion: 'nexus3',
                        protocol: 'http',
                        nexusUrl: '172.31.8.50:8081',
                        repository: 'maven-snapshots',
                        credentialsId: 'nexus-credentials',
                        groupId: pom.groupId,
                        version: dynamicVersion,
                        artifacts: [[
                            artifactId: 'server',
                            file: 'server/target/server.jar',
                            type: 'jar'
                        ]]
                    )

                    nexusArtifactUploader(
                        nexusVersion: 'nexus3',
                        protocol: 'http',
                        nexusUrl: '172.31.8.50:8081',
                        repository: 'maven-snapshots',
                        credentialsId: 'nexus-credentials',
                        groupId: pom.groupId,
                        version: dynamicVersion,
                        artifacts: [[
                            artifactId: 'webapp',
                            file: 'webapp/target/webapp.war',
                            type: 'war'
                        ]]
                    )
                }
            }
        }
        stage('Docker Build, Login & Push') {
            steps {
                script {
                    def imageTag = "${env.DOCKER_IMAGE}"
                    echo "Cleaning up any existing Docker image: ${imageTag}"
                    sh "docker rmi ${imageTag} || true"
            
                    echo "Building and pushing Docker image: ${imageTag}"
                    withCredentials([usernamePassword(credentialsId: 'dockerhub-credentials', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                        sh """
                            # Login to Docker Hub
                            echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin
                    
                            # Build Docker image
                            docker build -t ${imageTag} .
                    
                            # Push Docker image to Docker Hub
                            docker push ${imageTag}
                        """
                    }
                }
            }
        }
    }
}
