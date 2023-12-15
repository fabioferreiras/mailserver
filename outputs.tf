output "resource_group_name" {
  value = data.azurerm_resource_group.ONERGY_rg.name
}

output "id" {
  value = data.azurerm_resource_group.ONERGY_rg.id
}

output "public_ip_address" {
  value = azurerm_linux_virtual_machine.mailserver_vm.public_ip_address
}

output "subnet_id" {
  value = data.azurerm_subnet.Onergy_subnet.id
}
