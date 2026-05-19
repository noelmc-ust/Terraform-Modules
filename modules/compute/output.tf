output "load_balancer_public_ip" {
  description = "The public IP address assigned to the frontend application load balancer"
  value       = azurerm_public_ip.lb-ip.ip_address
}