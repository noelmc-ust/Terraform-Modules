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
  rs-name     = "rs-dev"
  rs-loc      = "Central India"
  vnet-name   = "vnet-dev"
  vnet-space  = ["10.0.0.0/16"]
  sub1-name   = "sub1-dev"
  sub1-prefix = ["10.0.10.0/24"]
  sub2-name   = "sub2-dev"
  sub2-prefix = ["10.0.20.0/24"]
  nat-name    = "nat-dev"
  nat-ip-name = "nat-dev-publicip"
}


module "compute_layer" {
  source            = "../../modules/compute"
  rs-name           = module.network_layer.resource_group_name
  rs-loc            = "Central India"
  sub1_id           = module.network_layer.sub1id
  sub2_id           = module.network_layer.sub2id
  vm-name           = "organicvm-dev"
  vmsize            = "Standard_D2s_v3" 
  min-vm            = "1"
  max-vm            = "3"
  alert-email       = "noelmathews123@gmail.com"
}