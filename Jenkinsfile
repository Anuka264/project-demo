pipeline {
    agent any

    environment {
        TF_IN_AUTOMATION = 'true'
        TF_CLI_ARGS = '-no-color'
        SSH_CRED_ID = 'aws-deployer-ssh-key' 
        // 1. REMOVED the TF_CLI_CONFIG_FILE line here to stop the error
    }

    stages {
        // 2. Wrap ALL Terraform stages in this block to provide credentials
        stage('Terraform Management') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', 
                    credentialsId: 'AKIARWITFNLHWR7XVG3T', 
                    accessKeyVariable: 'AWS_ACCESS_KEY_ID', 
                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY']]) {
                    
                    script {
                        // Stage: Initialization
                        sh 'terraform init -reconfigure'

                        // Stage: Plan
                        sh 'terraform plan -var-file=${env.BRANCH_NAME}.tfvars -out=tfplan.out'
                        
                        // Note: If you need the 'input' steps, they must stay 
                        // outside 'script' or be handled carefully. 
                        // For simplicity, I am combining the logic here:
                    }
                }
            }
        }

        stage('Terraform Provisioning') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', 
                    credentialsId: 'AKIARWITFNLHWR7XVG3T', 
                    accessKeyVariable: 'AWS_ACCESS_KEY_ID', 
                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY']]) {
                    script {
                        sh 'terraform apply -auto-approve -var-file=${env.BRANCH_NAME}.tfvars'

                        env.INSTANCE_IP = sh(script: 'terraform output -raw instance_public_ip', returnStdout: true).trim()
                        env.INSTANCE_ID = sh(script: 'terraform output -raw instance_id', returnStdout: true).trim()

                        sh "echo '${env.INSTANCE_IP}' > dynamic_inventory.ini"
                    }
                }
            }
        }

        stage('Wait & Ansible') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', 
                    credentialsId: 'AKIARWITFNLHWR7XVG3T', 
                    accessKeyVariable: 'AWS_ACCESS_KEY_ID', 
                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY']]) {
                    
                    sh "aws ec2 wait instance-status-ok --instance-ids ${env.INSTANCE_ID} --region us-east-2"
                    
                    ansiblePlaybook(
                        playbook: 'playbooks/grafana.yml',
                        inventory: 'dynamic_inventory.ini', 
                        credentialsId: SSH_CRED_ID
                    )
                }
            }
        }
    } 
    
    post {
        always {
            // 3. FIX: Use 'node' wrapper to provide the missing 'hudson.FilePath' context
            node {
                sh 'rm -f dynamic_inventory.ini'
            }
        }
        failure {
            node {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', 
                    credentialsId: 'AKIARWITFNLHWR7XVG3T', 
                    accessKeyVariable: 'AWS_ACCESS_KEY_ID', 
                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY']]) {
                    sh 'terraform destroy -auto-approve -var-file=${env.BRANCH_NAME}.tfvars || echo "Cleanup failed"'
                }
            }
        }
    }
}