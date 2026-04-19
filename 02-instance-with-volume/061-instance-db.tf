resource "azurerm_public_ip" "db" {
  name                = "db-pip"
  location            = azurerm_resource_group.generic.location
  resource_group_name = azurerm_resource_group.generic.name
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "db" {
  name                = "db-nic"
  location            = azurerm_resource_group.generic.location
  resource_group_name = azurerm_resource_group.generic.name

  ip_configuration {
    name                          = "testconfiguration1"
    subnet_id                     = azurerm_subnet.http.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.db.id
  }
}

resource "azurerm_linux_virtual_machine" "db" {
  name                  = var.db_vm_name
  location              = azurerm_resource_group.generic.location
  resource_group_name   = azurerm_resource_group.generic.name
  network_interface_ids = [azurerm_network_interface.db.id]
  size                  = "Standard_DS1_v2"

  computer_name                   = "hostname"
  admin_username                  = "testadmin"
  admin_password                  = "Password1234!"
  disable_password_authentication = false
  custom_data                     = filebase64("scripts/first-boot.sh")

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }

  os_disk {
    name                 = "db-osdisk1"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
}

resource "azurerm_managed_disk" "db" {
  name                 = "db-volume"
  location             = azurerm_resource_group.generic.location
  resource_group_name  = azurerm_resource_group.generic.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = 15
}

resource "azurerm_virtual_machine_data_disk_attachment" "db" {
  managed_disk_id    = azurerm_managed_disk.db.id
  virtual_machine_id = azurerm_linux_virtual_machine.db.id
  lun                = "10"
  caching            = "ReadWrite"
}
