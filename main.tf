# Create public IPs
resource "azurerm_public_ip" "mailserver_public_ip" {
  name                = "MailServer_PublicIP"
  location            = data.azurerm_resource_group.ONERGY_rg.location
  resource_group_name = data.azurerm_resource_group.ONERGY_rg.name
  allocation_method   = "Dynamic"
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "mailserver_nsg" {
  name                = "MailServer_SecurityGroup"
  location            = data.azurerm_resource_group.ONERGY_rg.location
  resource_group_name = data.azurerm_resource_group.ONERGY_rg.name

  dynamic "security_rule" {
    for_each = var.nsg_rules
    content {
      name                       = security_rule.value["name"]
      priority                   = security_rule.value["priority"]
      direction                  = security_rule.value["direction"]
      access                     = security_rule.value["access"]
      protocol                   = security_rule.value["protocol"]
      source_port_range          = security_rule.value["source_port_range"]
      destination_port_range     = security_rule.value["destination_port_range"]
      source_address_prefix      = security_rule.value["source_address_prefix"]
      destination_address_prefix = security_rule.value["destination_address_prefix"]
    }
  }

  tags = var.tags
}

# Create network interface
resource "azurerm_network_interface" "mailserver_terraform_nic" {
  name                = "MailServer_NIC"
  location            = data.azurerm_resource_group.ONERGY_rg.location
  resource_group_name = data.azurerm_resource_group.ONERGY_rg.name

  ip_configuration {
    name                          = "MailServer_nic_configuration"
    subnet_id                     = data.azurerm_subnet.Onergy_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.mailserver_public_ip.id
  }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "taxfymail_nisg" {
  network_interface_id      = azurerm_network_interface.mailserver_terraform_nic.id
  network_security_group_id = azurerm_network_security_group.mailserver_nsg.id
}

# Generate random text for a unique storage account name
resource "random_id" "random_id" {
  keepers = {
    # Generate a new ID only when a new resource group is defined
    resource_group = data.azurerm_resource_group.ONERGY_rg.name
  }
  byte_length = 8
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "taxfymail_storage_account" {
  name                     = "diag${random_id.random_id.hex}"
  location                 = data.azurerm_resource_group.ONERGY_rg.location
  resource_group_name      = data.azurerm_resource_group.ONERGY_rg.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Create virtual machine
resource "azurerm_linux_virtual_machine" "mailserver_vm" {
  name                  = "MailServer-VM"
  location              = data.azurerm_resource_group.ONERGY_rg.location
  resource_group_name   = data.azurerm_resource_group.ONERGY_rg.name
  network_interface_ids = [azurerm_network_interface.mailserver_terraform_nic.id]
  size                  = var.mailserver_size

  tags = var.tags

  os_disk {
    name                 = "MailServer_OS_Disk"
    caching              = "ReadWrite"
    storage_account_type = var.managed_disk["standardssd"]
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts-gen2"
    version   = "latest"
  }

  computer_name  = var.computer_info["hostname"]
  admin_username = var.computer_info["username"]

  admin_ssh_key {
    username   = var.computer_info["username"]
    public_key = jsondecode(azapi_resource_action.ssh_public_key_gen.output).publicKey
  }

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.taxfymail_storage_account.primary_blob_endpoint
  }
}

resource "azurerm_managed_disk" "maildata_disk" {
  name                 = "${azurerm_linux_virtual_machine.mailserver_vm.name}-data"
  location             = data.azurerm_resource_group.ONERGY_rg.location
  resource_group_name  = data.azurerm_resource_group.ONERGY_rg.name
  storage_account_type = var.managed_disk["standardssd"]
  create_option        = "Empty"
  disk_size_gb         = var.data_disk_size

  tags = {
    source      = "terraform"
    service     = "mail-service"
    environment = "staging"
  }
}

resource "azurerm_virtual_machine_data_disk_attachment" "maildata-disk" {
  managed_disk_id    = azurerm_managed_disk.maildata_disk.id
  virtual_machine_id = azurerm_linux_virtual_machine.mailserver_vm.id
  lun                = "10"
  caching            = "ReadWrite"
}