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
                            -Dsonar.host.url=http://3.110.212.88:9000 \
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
    }
}
