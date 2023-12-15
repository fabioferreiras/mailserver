data "azurerm_subnet" "Onergy_subnet" {
  name                 = "default"
  virtual_network_name = "OnergyNetwork"
  resource_group_name  = "Onergy"
}

data "azurerm_resource_group" "ONERGY_rg" {
  name = "ONERGY"
}

