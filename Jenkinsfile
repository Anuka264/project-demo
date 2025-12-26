pipeline {
    agent any
    
    environment {
        AWS_ACCESS_KEY_ID     = credentials('aws-access-key')
        AWS_SECRET_ACCESS_KEY = credentials('aws-secret-key')
        AWS_DEFAULT_REGION    = 'us-east-1'

        TF_IN_AUTOMATION = 'true'
        TF_CLI_ARGS      = '-no-color'
        SSH_CRED_ID      = 'aws-deployer-ssh-key'
        BRANCH_NAME      = "main"
    }

    stages {
        stage('Terraform Initialization') {
            steps {
                // This will now work because AWS credentials are in the environment
                sh 'terraform init'
                sh "cat ${env.BRANCH_NAME}.tfvars"
            }
        }

        stage('Terraform Plan') {
            steps {
                sh "terraform plan -var-file=${env.BRANCH_NAME}.tfvars"
            }
        }

        stage('Validate Apply') {
            input {
                message "Do you want to apply this plan?"
                ok "Apply"
            }
            steps {
                echo 'Apply Accepted'
            }
        }

        stage('Terraform Provisioning') {
            steps {
                script {
                    sh "terraform apply -auto-approve -var-file=${env.BRANCH_NAME}.tfvars"

                    // Extract outputs for later stages
                    env.INSTANCE_IP = sh(
                        script: 'terraform output -raw instance_public_ip',
                        returnStdout: true
                    ).trim()

                    env.INSTANCE_ID = sh(
                        script: 'terraform output -raw instance_id',
                        returnStdout: true
                    ).trim()

                    echo "Provisioned Instance IP: ${env.INSTANCE_IP}"
                    echo "Provisioned Instance ID: ${env.INSTANCE_ID}"

                    sh "echo '${env.INSTANCE_IP}' > dynamic_inventory.ini"
                }
            }
        }

        stage('Wait for AWS Instance Status') {
            steps {
                echo "Waiting for instance ${env.INSTANCE_ID} to pass health checks in ${env.AWS_DEFAULT_REGION}..."
                // Using the environment variable for region to keep it consistent
                sh "aws ec2 wait instance-status-ok --instance-ids ${env.INSTANCE_ID} --region ${env.AWS_DEFAULT_REGION}"  
                echo 'AWS instance health checks passed.'
            }
        }

        stage('Validate Ansible') {
            input {
                message "Do you want to run Ansible?"
                ok "Run Ansible"
            }
            steps {
                echo 'Ansible approved'
            }
        }

        stage('Ansible Configuration') {
            steps {
                sleep 20

                script {
                    env.ANSIBLE_HOST_KEY_CHECKING = 'False'

                    ansiblePlaybook(
                    playbook: 'playbooks/grafana.yml',
                    inventory: 'dynamic_inventory.ini',
                    credentialsId: env.SSH_CRED_ID
                )
            }
        }

        stage('Validate Destroy') {
            input {
                message "Do you want to destroy resources?"
                ok "Destroy"
            }
            steps {
                echo 'Destroy Approved'
            }
        }

        stage('Destroy') {
            steps {
                sh "terraform destroy -auto-approve -var-file=${env.BRANCH_NAME}.tfvars"
            }
        }
    }    

    post {
        always {
            // This sh step now has the 'agent any' context correctly
            sh 'rm -f dynamic_inventory.ini'
        }
        success {
            echo 'Deployment Finished Successfully!'
        }
        failure {
            // Attempt cleanup only if initialization succeeded and state exists
            sh "terraform destroy -auto-approve -var-file=${env.BRANCH_NAME}.tfvars || echo 'Cleanup skipped or failed.'"
        }
    }
}