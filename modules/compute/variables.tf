variable "sub1_id" { type = string }
variable "sub2_id" { type = string }
variable "rs-name" { type = string }
variable "rs-loc" { type = string }

variable "lb-name" {
  type    = string
  default = "app-lb"
}

variable "lb-ip-name" {
  type    = string
  default = "lb-publicip"
}

variable "vm-name" {
  type    = string
  default = "organicvm"
}

variable "vmsize" {
  type    = string
  default = "Standard_B2ats_v2"
}

variable "usr" {
  type    = string
  default = "noelmc"
}

variable "pwd" {
  type      = string
  default   = "Noelmc@12345"
  sensitive = true
}

variable "caching" {
  type    = string
  default = "ReadWrite"
}

variable "stroage" {
  type    = string
  default = "Standard_LRS"
}

variable "os-publisher" {
  type    = string
  default = "Canonical"
}

variable "os-version" {
  type    = string
  default = "latest"
}

variable "os-offer" {
  type    = string
  default = "0001-com-ubuntu-server-jammy"
}

variable "os-sku" {
  type    = string
  default = "22_04-lts"
}

variable "nic-name" {
  type    = string
  default = "vmss-nic"
}

variable "nic-ipconfig-name" {
  type    = string
  default = "vmss-ipconfig"
}

variable "min-vm" {
  type    = string
  default = "2"
}

variable "max-vm" {
  type    = string
  default = "4"
}

variable "alert-email" {
  type    = string
  default = "noelmathews123@gmail.com"
}