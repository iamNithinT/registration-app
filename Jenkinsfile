pipeline {
    agent { label 'Jenkins-Agent' }
    
    tools {
        jdk 'Java17'
        maven 'Maven'
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
                            -Dsonar.host.url=http://172.31.36.129:9000 \
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
                    // Read Maven POM to get groupId and base version
                    def pom = readMavenPom file: 'pom.xml'

                    // Create dynamic version by appending build number to base version
                    def dynamicVersion = "${pom.version}-${env.BUILD_NUMBER}"

                    // Upload server module artifact
                    nexusArtifactUploader(
                        nexusVersion: 'nexus3',
                        protocol: 'http',
                        nexusUrl: '3.110.182.123:8081',
                        repository: 'maven-snapshots',
                        credentialsId: 'nexus-credentials',
                        groupId: pom.groupId,
                        version: dynamicVersion,
                        artifacts: [[
                            artifactId: 'server',
                            classifier: '',
                            file: 'server/target/server.jar',
                            type: 'jar'
                        ]]
                    )

                    // Upload webapp module artifact
                    nexusArtifactUploader(
                        nexusVersion: 'nexus3',
                        protocol: 'http',
                        nexusUrl: '3.110.182.123:8081',
                        repository: 'maven-snapshots',
                        credentialsId: 'nexus-credentials',
                        groupId: pom.groupId,
                        version: dynamicVersion,
                        artifacts: [[
                            artifactId: 'webapp',
                            classifier: '',
                            file: 'webapp/target/webapp.war',
                            type: 'war'
                        ]]
                    )
                }
            }
        }  
    }
}
