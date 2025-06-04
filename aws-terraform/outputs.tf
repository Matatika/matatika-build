output "nat_gateway_eip" {
  description = "The static egress IP for outbound traffic"
  value       = module.vpc.nat_public_ips
}
