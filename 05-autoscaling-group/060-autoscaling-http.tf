resource "azurerm_linux_virtual_machine_scale_set" "http" {
  name                = "http-scale-set"
  location            = azurerm_resource_group.generic.location
  resource_group_name = azurerm_resource_group.generic.name
  sku                 = "Standard_F2s_v2"
  instances           = 2
  upgrade_mode        = "Manual"

  computer_name_prefix            = "http-vm"
  admin_username                  = "testadmin"
  admin_password                  = "Password1234!"
  disable_password_authentication = false
  custom_data                     = filebase64("scripts/first-boot-http.sh")

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  network_interface {
    name    = "internal"
    primary = true

    ip_configuration {
      name                                   = "internal"
      subnet_id                              = azurerm_subnet.http.id
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.http.id]
      primary                                = true
    }
  }
}

resource "azurerm_monitor_autoscale_setting" "http" {
  name                = "HttpAutoscaleSetting"
  resource_group_name = azurerm_resource_group.generic.name
  location            = azurerm_resource_group.generic.location
  target_resource_id  = azurerm_linux_virtual_machine_scale_set.http.id

  profile {
    name = "defaultProfile"

    capacity {
      default = var.autoscaling_http.desired_capacity
      minimum = var.autoscaling_http.min_size
      maximum = var.autoscaling_http.max_size
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.http.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 75
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT1M"
      }
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.http.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = 25
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT1M"
      }
    }
  }
}
