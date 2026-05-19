output "app_frontend_ip" {
  description = "Public entrance IP for this environment"
  value       = module.compute_layer.load_balancer_public_ip
}