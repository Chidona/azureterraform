# azureterraform

azure doc to log in using vscode

follow this documenttation ====https://spacelift.io/blog/terraform-jenkins#step-2-instal-terraform-binary
======https://plugins.jenkins.io/azure-credentials/
install terraform in ubuntu === https://tecadmin.net/how-to-install-terraform-on-ubuntu/
install azure cli in ubuntu(jenkins machine) === https://www.linuxtechi.com/how-to-install-azure-cli-on-ubuntu/

az login --use-device-code
az login --tenant d95caa7c-2879-4215-9f09-161979a6d611

az account list
az account set --subscription "devops-demo" to switch to a subscription
terraform init
erraform plan
terraform apply
terraform import azurerm_resource_group.resource_group /subscriptions/<subscriptionID> to be executed in powershell
terraform destroy
terraform fmt
terraform validate
terraform force-unlock <LOCK_ID>

terraform import azurerm_network_interface.main /subscriptions/eac5c2b6-c759-4a83-9ebc-75382f1147e0/resourceGroups/class-rg/providers/Microsoft.Network/networkInterfaces/class-vm581_z1


###########################################################################################
this is to create a storage account using azure cli 
###########################################################################################

RESOURCE_GROUP_NAME=tstaterg
STORAGE_ACCOUNT_NAME=tstate$RANDOM
CONTAINER_NAME=tstateblob

# Create resource group
az group create --name $RESOURCE_GROUP_NAME --location eastus

# Create storage account
az storage account create --resource-group $RESOURCE_GROUP_NAME --name $STORAGE_ACCOUNT_NAME --sku Standard_LRS --encryption-services blob

# Get storage account key
ACCOUNT_KEY=$(az storage account keys list --resource-group $RESOURCE_GROUP_NAME --account-name $STORAGE_ACCOUNT_NAME --query [0].value -o tsv)

# Create blob container
az storage container create --name $CONTAINER_NAME --account-name $STORAGE_ACCOUNT_NAME --account-key $ACCOUNT_KEY



#################################################################################
pipeline {
    agent any
    
      environment {
         MY_CRED = credentials('AzureServicePrincipal')
       }
    
    stages {
        
        stage("checkout") {
            steps {
                git branch: 'test', credentialsId: 'github', url: 'https://github.com/Chidona/azureterraform.git'
            }
        }
        
        stage('build') {
            steps {
                //  sh 'az login  --tenant d95caa7c-2879-4215-9f09-161979a6d611'
                sh 'az login --use-device-code'
              }
        }
        stage('Terraform Init') {
            steps {
                script {
                    sh "terraform init"
                }
            }
        }
        
        stage('Terraform Plan') {
            steps {
                script {
                    sh "terraform plan -out=tfplan"
                }
            }
        }
        
        stage('Terraform Apply') {
            steps {
                script {
                    sh "terraform apply --auto-approve"
                }
            }
        }
        
        stage('Terraform action') {
            steps {
                sh 'terraform ${action} --auto-approve'
            }
        }
    }
}
 ##########################################################################

 run this to creat service principal === az ad sp create-for-rbac
 you will get the below result 

 ########################################################################
{
  "appId": "75b51c69-339d-4013-821d-cc2aa912e97f",
  "displayName": "azure-cli-2024-03-12-05-18-34",
  "password": "Ay.8Q~RAjguCAuSDEcR_pchD.oPwVreuGCwfSa-A",
  "tenant": "d95caa7c-2879-4215-9f09-161979a6d611"
}
