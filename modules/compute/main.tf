resource "azurerm_public_ip" "lb-ip" {
  name                = var.lb-ip-name
  resource_group_name = var.rs-name
  location            = var.rs-loc
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_lb" "lb" {
  name                = var.lb-name
  resource_group_name = var.rs-name
  location            = var.rs-loc
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = var.lb-ip-name
    public_ip_address_id = azurerm_public_ip.lb-ip.id
  }
}

resource "azurerm_lb_backend_address_pool" "back-pool" {
  name            = "app-pool"
  loadbalancer_id = azurerm_lb.lb.id
}

resource "azurerm_linux_virtual_machine_scale_set" "organic-vmss" {
  name                            = var.vm-name
  resource_group_name             = var.rs-name
  location                        = var.rs-loc
  sku                             = var.vmsize
  instances                       = var.min-vm
  admin_username                  = var.usr
  admin_password                  = var.pwd
  disable_password_authentication = false

  os_disk {
    caching              = var.caching
    storage_account_type = var.stroage
  }

  source_image_reference {
    publisher = var.os-publisher
    offer     = var.os-offer
    sku       = var.os-sku
    version   = var.os-version
  }

  network_interface {
    name    = var.nic-name
    primary = true

    ip_configuration {
      name                                   = var.nic-ipconfig-name
      primary                                = true
      subnet_id                              = var.sub2_id
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.back-pool.id]
    }
  }
}

resource "azurerm_monitor_autoscale_setting" "autoscale" {
  name                = "autoscale-settings"
  resource_group_name = var.rs-name
  location            = var.rs-loc
  target_resource_id  = azurerm_linux_virtual_machine_scale_set.organic-vmss.id

  profile {
    name = "default"

    capacity {
      default = var.min-vm
      minimum = var.min-vm
      maximum = var.max-vm
    }
  

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.organic-vmss.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 60
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = 1 
        cooldown  = "PT5M"
      }
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.organic-vmss.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = 40
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = 1 
        cooldown  = "PT5M"
      }
    }
  }
}

resource "azurerm_servicebus_namespace" "sb" {
  name                = "${var.vm-name}-alert-bus"
  resource_group_name = var.rs-name
  location            = var.rs-loc
  sku                 = "Standard"
}

resource "azurerm_servicebus_queue" "sb-queue" {
  name         = "cpu-alert"
  namespace_id = azurerm_servicebus_namespace.sb.id
}

resource "azurerm_monitor_action_group" "action-group" {
  name                = "email-group"
  resource_group_name = var.rs-name
  location            = var.rs-loc
  short_name          = "cpu-alert"

  email_receiver {
    name                    = "SendTops"
    email_address           = var.alert-email
    use_common_alert_schema = true
  }
}

resource "azurerm_monitor_metric_alert" "cpu_alert" {
  name                = "high-alert"
  resource_group_name = var.rs-name
  scopes              = [azurerm_linux_virtual_machine_scale_set.organic-vmss.id]
  description         = "Triggers when VMSS core CPU capacity climbs"
  severity            = 2

  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachineScaleSets"
    metric_name      = "Percentage CPU"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 85
  }

  action {
    action_group_id = azurerm_monitor_action_group.action-group.id
  }
}