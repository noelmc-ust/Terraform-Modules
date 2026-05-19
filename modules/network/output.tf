output "resource_group_name" {
  value = azurerm_resource_group.rs.name
}

output "sub1id" {
  value = azurerm_subnet.sub1.id
}

output "sub2id" {
  value = azurerm_subnet.sub2.id
}