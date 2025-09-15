pipeline {
    agent { label 'Jenkins-Agent' }

    tools {
        jdk 'Java17'
        maven 'Maven'
    }

    environment {
        DOCKER_IMAGE = "nithinnito/registration-app:${env.BUILD_NUMBER}"
        DOCKER_CREDENTIALS_ID = 'dockerhub-credentials'
    }

    stages {
        stage("Cleanup Workspace") {
            steps {
                cleanWs()
            }
        }

        stage("Checkout from SCM") {
            steps {
                git branch: 'main',
                    credentialsId: 'Github',
                    url: 'https://github.com/iamNithinT/registration-app.git'
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
                dependencyCheck additionalArguments: '',
                                nvdCredentialsId: 'nvd-api-key',
                                odcInstallation: 'OWASP-Dependency-Check',
                                stopBuild: true
            }
        }

        stage('Nexus Artifact Upload') {
            steps {
                script {
                    def pom = readMavenPom file: 'pom.xml'
                    def baseVersion = pom.version.replace('-SNAPSHOT', '')
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

        stage('Docker Image Build, & Push') {
            steps {
                script {
                    def imageTag = "${env.DOCKER_IMAGE}"

                    echo "Removing any existing Docker image: ${imageTag}"
                    sh "docker rmi ${imageTag} || true"

                    echo "Building Docker image: ${imageTag}"
                    sh "docker build -t ${imageTag} ."

                    withCredentials([usernamePassword(credentialsId: env.DOCKER_CREDENTIALS_ID, usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                        echo "Logging into Docker Hub"
                        sh "echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin"

                        echo "Pushing Docker image: ${imageTag}"
                        sh "docker push ${imageTag}"
                    }
                }
            }
        }

        stage('Docker Image Vulnerability Scan (Trivy)') {
            steps {
                script {
                    def imageTag = "${env.DOCKER_IMAGE}"
                    echo "Scanning Docker image with Trivy: ${imageTag}"

                    // Exit with failure on HIGH or CRITICAL vulnerabilities
                    sh "trivy image --exit-code 1 --severity HIGH,CRITICAL ${imageTag}"
                }
            }
        }
        stage('Update deployment.yml with new image tag') {
            steps {
                script {
                    def deploymentFile = 'kubernetes/deployment.yml'  // Adjust to your actual path if different
                    def imageTag = "${env.DOCKER_IMAGE}"               // e.g., nithinnito/registration-app:12345
            
                    echo "Updating deployment.yml with image: ${imageTag}"
            
                    // Replace the existing image line with new image tag (matches line starting with "image:")
                    sh """
                        sed -i 's#^\\s*image:.*#        image: ${imageTag}#' ${deploymentFile}
                    """
            
                    // Commit and push the update (optional)
                    sh """
                        git config user.email "ci@yourcompany.com"
                        git config user.name "Jenkins CI"
                        git add ${deploymentFile}
                        if ! git diff --cached --quiet; then
                            git commit -m "Update deployment image tag to ${imageTag}"
                            git push origin main
                        else
                            echo "No changes detected, skipping commit."
                        fi
                    """
                }
            }
        }
    }
}
