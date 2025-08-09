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
                dependencyCheck additionalArguments: '', odcInstallation: 'OWASP', stopBuild: true
            }
        }
    }
}
