resource "azurerm_network_interface" "http" {
  for_each = var.vm_names

  name                = "nic-${each.value}"
  resource_group_name = azurerm_resource_group.generic.name
  location            = azurerm_resource_group.generic.location

  ip_configuration {
    name                          = "ip-config-${each.value}"
    subnet_id                     = azurerm_subnet.http.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "http" {
  for_each = var.vm_names

  name                  = each.value
  location              = azurerm_resource_group.generic.location
  resource_group_name   = azurerm_resource_group.generic.name
  network_interface_ids = [azurerm_network_interface.http[each.key].id]
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
    name                 = "myosdisk-${each.value}"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
}
