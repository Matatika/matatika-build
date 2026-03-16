output "catalog_postgres_address" {
  description = "The catalog and warehouse PostgreSQL Flexible Server endpoint"
  value       = azurerm_postgresql_flexible_server.db.fqdn
}

output "nat_gateway_eip" {
  description = "The static egress IP for outbound traffic"
  value       = azurerm_public_ip.nat.ip_address
}
