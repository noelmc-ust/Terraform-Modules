# ===============================================================================
# PUBLIC IP & LOAD BALANCER CONFIGURATION
# ===============================================================================

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

resource "azurerm_lb_probe" "http_probe" {
  name            = "http-running-probe"
  loadbalancer_id = azurerm_lb.lb.id
  port            = 80
  protocol        = "Http"
  request_path    = "/"
}

resource "azurerm_lb_rule" "http_lb_rule" {
  name                           = "http-routing-rule"
  loadbalancer_id                = azurerm_lb.lb.id
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = var.lb-ip-name
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.back-pool.id]
  probe_id                       = azurerm_lb_probe.http_probe.id
}

# ===============================================================================
# NETWORK SECURITY GROUP (NSG) RULES
# ===============================================================================

resource "azurerm_network_security_group" "vmss_nsg" {
  name                = "${var.vm-name}-nsg"
  location            = var.rs-loc
  resource_group_name = var.rs-name

  security_rule {
    name                       = "Allow-LB-HTTP-Inbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "AzureLoadBalancer"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Deny-Public-Inbound"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }
}

# ===============================================================================
# VIRTUAL MACHINE SCALE SET (VMSS)
# ===============================================================================

resource "azurerm_linux_virtual_machine_scale_set" "organic-vmss" {
  name                            = var.vm-name
  resource_group_name             = var.rs-name
  location                        = var.rs-loc
  sku                             = var.vmsize
  instances                       = var.min-vm
  admin_username                  = var.usr
  admin_password                  = var.pwd
  disable_password_authentication = false
  custom_data                     = base64encode(file("${path.module}/scripts/setup.sh"))

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
    name                      = var.nic-name
    primary                   = true
    network_security_group_id = azurerm_network_security_group.vmss_nsg.id

    ip_configuration {
      name                                   = var.nic-ipconfig-name
      primary                                = true
      subnet_id                              = var.sub2_id
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.back-pool.id]
    }
  }
}

# ===============================================================================
# AUTOSCALE TARGET SETTINGS (WITH TIGHT TIME-WINDOW & EMAIL NOTIFICATION)
# ===============================================================================

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

    # Aggressive Scale-Out Rule 
    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.organic-vmss.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT2M"       # 2-Minute Window
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 40           # Lowered to 40% CPU
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = 1 
        cooldown  = "PT2M"                
      }
    }

    # Scale-In Rule
    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.organic-vmss.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = 25           # Lowered to 25% so it doesn't fight the scale-out
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = 1 
        cooldown  = "PT5M"
      }
    }
  }

  notification {
    email {
      send_to_subscription_administrator    = false
      custom_emails                         = [var.alert-email]
    }
  }
}

# ===============================================================================
# ALERTING INFRASTRUCTURE (SERVICE BUS & ACTION GROUP ALERTS)
# ===============================================================================

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
  description         = "Triggers when VMSS core CPU capacity climbs over 40%"
  severity            = 2

  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachineScaleSets"
    metric_name      = "Percentage CPU"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 40                 # Synced with your 40% autoscale validation goal
  }

  action {
    action_group_id = azurerm_monitor_action_group.action-group.id
  }
}