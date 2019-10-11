output "dns_name" {
  description = "The public DNS name of the load balancer"
  value       = "${module.alb.dns_name}"
}
