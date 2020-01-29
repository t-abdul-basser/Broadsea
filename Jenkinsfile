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
                //sh './testAtlas.sh'
            }
        }
        stage('Sanity check') {
             steps {
                input "Does the staging environment look ok?"
             }
        }
        stage('Deliver') {
             steps {
                //sh './jenkins/scripts/deliver.sh'
             }
        }
        stage('Deploy') {
            steps {
                // './deploy production'
                //sh 'docker-compose up -d'
                echo 'Deploy'
            }
        }
    }
}