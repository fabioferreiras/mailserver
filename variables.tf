variable "mailserver_size" {
  default     = "Standard_DS2_v2"
  description = "Size of the Virtual Machine based on Azure sizing"
}

variable "data_disk_size" {
  description = "Specify the size in GB of the data disk"
  default     = "100"
}

variable "computer_info" {
  type = map(any)
  default = {
    "hostname" = "mail.recuperanfe.com.br" #"The username for the local account that will be created on the new VM."
    "username" = "mailadmin"               #The hostname for the linux server"
  }
  sensitive = true
}

variable "tags" {
  type        = map(any)
  description = "The tag values for the deployment"
}

variable "managed_disk" {
  type = map(any)
  default = {
    "standard"    = "Standard_LRS"
    "standardssd" = "StandardSSD_LRS"
    "premium"     = "Premium_LRS"
    "premiumv2"   = "PremiumV2_LRS"
    "ultrassd"    = "UltraSSD_LRS"
  }
}

variable "nsg_rules" {
  type = list(object({
    name                       = string
    priority                   = number
    direction                  = string
    access                     = string
    protocol                   = string
    source_port_range          = string
    destination_port_range     = string
    source_address_prefix      = string
    destination_address_prefix = string
  }))
  description = "The values for each NSG rule "
}

