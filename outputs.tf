output "public_ip" {
  value = azurerm_public_ip.pubip.ip_address
}

output "username" {
  value = var.admin_username
}

output "password" {
  value = var.admin_password
}
