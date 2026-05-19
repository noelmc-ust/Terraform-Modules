resource "azurerm_resource_group" "rs" {
  name     = var.rs-name
  location = var.rs-loc
}

resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet-name
  resource_group_name = azurerm_resource_group.rs.name
  location            = azurerm_resource_group.rs.location
  address_space       = var.vnet-space
}

resource "azurerm_subnet" "sub1" {
  name                 = var.sub1-name
  resource_group_name  = azurerm_resource_group.rs.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.sub1-prefix
}

resource "azurerm_subnet" "sub2" {
  name                 = var.sub2-name
  resource_group_name  = azurerm_resource_group.rs.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.sub2-prefix
}

resource "azurerm_nat_gateway" "nat" {
  name                = var.nat-name
  resource_group_name = azurerm_resource_group.rs.name
  location            = azurerm_resource_group.rs.location
  sku_name            = "Standard"
}

resource "azurerm_public_ip" "nat-ip" {
  name                = var.nat-ip-name
  resource_group_name = azurerm_resource_group.rs.name
  location            = azurerm_resource_group.rs.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_nat_gateway_public_ip_association" "nat-ip-assoc" {
  nat_gateway_id       = azurerm_nat_gateway.nat.id
  public_ip_address_id = azurerm_public_ip.nat-ip.id
}

resource "azurerm_subnet_nat_gateway_association" "nat-sub-assoc" {
  subnet_id      = azurerm_subnet.sub2.id
  nat_gateway_id = azurerm_nat_gateway.nat.id
}

