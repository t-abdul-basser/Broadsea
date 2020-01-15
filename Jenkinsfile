pipeline {
    agent any
    options {
        skipStagesAfterUnstable()
    }
    stages {
        stage('Build') {
            steps {
                //sh 'docker-compose build'
                echo 'Build'
            }
        }
        stage('Test'){
            steps {
                //junit 'reports/**/*.xml'
                echo 'Test'
                sh 'testAtlas.sh'
            }
        }
        stage('Deploy') {
            steps {
                //sh 'make publish'
                sh 'docker-compose up -d'
                echo 'Deploy'
            }
        }
    }
}