output "catalog_rds_address" {
  description = "The catalog and warehouse rds endpoint"
  value       = module.db.db_instance_address
}

output "nat_gateway_eip" {
  description = "The static egress IP for outbound traffic"
  value       = module.vpc.nat_public_ips
}

output "acm_dns_validation_records" {
  value = module.acm.acm_certificate_domain_validation_options
}

output "acm_arn" {
  value = module.acm.acm_certificate_arn
}
