terraform {
  required_version = ">= 1.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.0.0"
    }
  }
}

provider "azurerm" {
  features {}
}


module "network_layer" {
  source      = "../../modules/network"
  rs-name     = "rs-prod"
  rs-loc      = "South India" 
  vnet-name   = "vnet-prod"
  vnet-space  = ["172.16.0.0/16"]
  sub1-name   = "sub1-prod"
  sub1-prefix = ["172.16.10.0/24"]
  sub2-name   = "sub2-prod"
  sub2-prefix = ["172.16.20.0/24"]
  nat-name    = "nat-prod"
  nat-ip-name = "nat-prod-publicip"
}

module "compute_layer" {
  source            = "../../modules/compute"
  rs-name           = module.network_layer.resource_group_name
  rs-loc            = "South India"
  sub1_id           = module.network_layer.sub1id
  sub2_id           = module.network_layer.sub2id
  

  vm-name           = "organicvm-prod"
  vmsize            = "Standard_D2as_v5" 
  min-vm            = "4"                
  max-vm            = "12"                
  alert-email       = "noelmathews123@gmail.com"
}