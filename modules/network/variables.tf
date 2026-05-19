variable "rs-name" {
  description = "Resource group name"
  type        = string
}

variable "rs-loc" {
  description = "Resource group location"
  type        = string
}

variable "vnet-name" {
  description = "Virtual network name"
  type        = string
}

variable "vnet-space" {
  description = "VNET address space"
  type        = list(string)
}

variable "sub1-name" {
  description = "Subnet 1 name"
  type        = string
}

variable "sub1-prefix" {
  description = "Subnet 1 address prefix"
  type        = list(string)
}

variable "sub2-name" {
  description = "Subnet 2 name"
  type        = string
}

variable "sub2-prefix" {
  description = "Subnet 2 address prefix"
  type        = list(string)
}

variable "nat-name" {
  description = "NAT gateway name"
  type        = string
}

variable "nat-ip-name" {
  description = "NAT public IP name"
  type        = string
}