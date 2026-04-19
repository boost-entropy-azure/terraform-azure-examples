resource "azurerm_public_ip" "db" {
  for_each            = var.db_vm_names
  name                = "${each.key}-pip"
  location            = azurerm_resource_group.generic.location
  resource_group_name = azurerm_resource_group.generic.name
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "db" {
  for_each            = var.db_vm_names
  name                = "${each.key}-nic"
  location            = azurerm_resource_group.generic.location
  resource_group_name = azurerm_resource_group.generic.name

  ip_configuration {
    name                          = "${each.key}-configuration"
    subnet_id                     = azurerm_subnet.db.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.db[each.key].id
  }
}

resource "azurerm_linux_virtual_machine" "db" {
  for_each              = var.db_vm_names
  name                  = each.key
  location              = azurerm_resource_group.generic.location
  resource_group_name   = azurerm_resource_group.generic.name
  network_interface_ids = [azurerm_network_interface.db[each.key].id]
  size                  = "Standard_DS1_v2"

  computer_name                   = each.key
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
    name                 = "${each.key}-osdisk1"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
}
