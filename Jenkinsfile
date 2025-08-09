pipeline {
    agent { label 'jenkinsslave' }
    tools {
        jdk 'Java17'
        maven 'Maven3'
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

        
        stage("Clean Targetfolder and Compile") {
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
        stage("Quality Gates"){
            steps{
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
            steps{
                dependencyCheck additionalArguments: '', nvdCredentialsId: 'nvd-api-key', odcInstallation: 'OWASP', stopBuild: true
            }
        }
        stage("Nexus Artifact Upload") {
            steps{
                nexusArtifactUploader artifacts: [[artifactId: 'webapp', classifier: '', file: 'webapp/target/webapp.war', type: 'war']], credentialsId: 'nexus-credentials', groupId: 'com.example.maven-project', nexusUrl: '3.110.182.123:8081', nexusVersion: 'nexus3', protocol: 'http', repository: 'maven-snapshots', version: '1.0-SNAPSHOT'
            }
        }
    }
}
