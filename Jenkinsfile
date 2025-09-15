15/09/2025



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
    }  
}




