terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~>3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

terraform {   
 backend "azurerm" {
 resource_group_name = "tstaterg"     
 storage_account_name  = "tstate6112"     
 container_name        = "tstateblob"     
 key                   = "terraform.tfstate"   
 } 
}
