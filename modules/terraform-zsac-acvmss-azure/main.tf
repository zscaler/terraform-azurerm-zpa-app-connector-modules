################################################################################
# Create App Connector VMSS
################################################################################
# Create VMSS
resource "azurerm_orchestrated_virtual_machine_scale_set" "ac_vmss" {
  count                       = local.zones_supported ? length(var.zones) : 1
  name                        = "${var.name_prefix}-acvmss-${count.index + 1}-${var.resource_tag}"
  location                    = var.location
  resource_group_name         = var.resource_group
  platform_fault_domain_count = var.fault_domain_count
  sku_name                    = var.acvm_instance_type
  encryption_at_host_enabled  = var.encryption_at_host_enabled
  zones                       = local.zones_supported ? [element(var.zones, count.index)] : null
  zone_balance                = false
  termination_notification {
    enabled = true
    timeout = "PT5M"
  }

  network_interface {
    name                          = "${var.name_prefix}-acvmss-nic-${var.resource_tag}"
    enable_accelerated_networking = false
    primary                       = true
    network_security_group_id     = var.ac_nsg_id

    ip_configuration {
      name      = "${var.name_prefix}-acvmss-nic-conf-${var.resource_tag}"
      primary   = true
      subnet_id = element(var.ac_subnet_id, count.index)
    }
  }

  os_profile {
    custom_data = base64encode(var.user_data)
    linux_configuration {
      admin_username = var.ac_username
      admin_ssh_key {
        username   = var.ac_username
        public_key = "${trimspace(var.ssh_key)} ${var.ac_username}@me.io"
      }
    }
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  dynamic "source_image_reference" {
    for_each = var.acvm_source_image_id == null ? [var.acvm_image_publisher] : []

    content {
      publisher = var.acvm_image_publisher
      offer     = var.acvm_image_offer
      sku       = var.acvm_image_sku
      version   = var.acvm_image_version
    }
  }

  dynamic "plan" {
    for_each = var.acvm_source_image_id == null ? [var.acvm_image_publisher] : []

    content {
      publisher = var.acvm_image_publisher
      name      = var.acvm_image_sku
      product   = var.acvm_image_offer
    }
  }

  source_image_id = var.acvm_source_image_id != null ? var.acvm_source_image_id : null

  tags = var.global_tags

  depends_on = [
    var.backend_address_pool
  ]
}


# Create scaleset profiles and thresholds
resource "azurerm_monitor_autoscale_setting" "vmss_autoscale_setting" {
  count               = length(azurerm_orchestrated_virtual_machine_scale_set.ac_vmss[*].id)
  name                = "custom-scale-rule-az-${count.index + 1}"
  resource_group_name = var.resource_group
  location            = var.location
  target_resource_id  = element(azurerm_orchestrated_virtual_machine_scale_set.ac_vmss[*].id, count.index)

  profile {
    name = "defaultProfile"

    capacity {
      default = var.vmss_default_acs
      minimum = var.vmss_min_acs
      maximum = var.vmss_max_acs
    }

    # Add a scale out rule that adds a vm when the average cpu load on the vms in the scale set was above 70% for 5 minutes
    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = element(azurerm_orchestrated_virtual_machine_scale_set.ac_vmss[*].id, count.index)
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = var.scale_out_evaluation_period
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = var.scale_out_threshold
        metric_namespace   = "microsoft.compute/virtualmachinescalesets"
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = var.scale_out_count
        cooldown  = var.scale_out_cooldown
      }
    }

    # Add a scale in rule that removes a vm when the average cpu load on the vms in the scale set was below 30% for 5 minutes
    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = element(azurerm_orchestrated_virtual_machine_scale_set.ac_vmss[*].id, count.index)
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = var.scale_in_evaluation_period
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = var.scale_in_threshold
        metric_namespace   = "microsoft.compute/virtualmachinescalesets"
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = var.scale_in_count
        cooldown  = var.scale_in_cooldown
      }
    }

    dynamic "recurrence" {
      for_each = var.scheduled_scaling_enabled != false ? ["apply"] : []
      content {
        timezone = var.scheduled_scaling_timezone
        days     = ["Saturday", "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]
        hours    = [var.scheduled_scaling_end_time_hour]
        minutes  = [var.scheduled_scaling_end_time_min]
      }
    }
  }

  dynamic "profile" {
    for_each = var.scheduled_scaling_enabled ? ["apply"] : []
    content {
      name = "ScheduledProfile"

      capacity {
        default = var.scheduled_scaling_vmss_min_acs
        minimum = var.scheduled_scaling_vmss_min_acs
        maximum = var.vmss_max_acs
      }

      # Add a scale out rule that adds a vm when the average cpu load on the vms in the scale set was above 70% for 5 minutes
      rule {
        metric_trigger {
          metric_name        = "Percentage CPU"
          metric_resource_id = element(azurerm_orchestrated_virtual_machine_scale_set.ac_vmss[*].id, count.index)
          time_grain         = "PT1M"
          statistic          = "Average"
          time_window        = var.scale_out_evaluation_period
          time_aggregation   = "Average"
          operator           = "GreaterThan"
          threshold          = var.scale_out_threshold
          metric_namespace   = "microsoft.compute/virtualmachinescalesets"
        }

        scale_action {
          direction = "Increase"
          type      = "ChangeCount"
          value     = var.scale_out_count
          cooldown  = var.scale_out_cooldown
        }
      }

      # Add a scale in rule that removes a vm when the average cpu load on the vms in the scale set was below 30% for 5 minutes
      rule {
        metric_trigger {
          metric_name        = "Percentage CPU"
          metric_resource_id = element(azurerm_orchestrated_virtual_machine_scale_set.ac_vmss[*].id, count.index)
          time_grain         = "PT1M"
          statistic          = "Average"
          time_window        = var.scale_in_evaluation_period
          time_aggregation   = "Average"
          operator           = "LessThan"
          threshold          = var.scale_in_threshold
          metric_namespace   = "microsoft.compute/virtualmachinescalesets"
        }

        scale_action {
          direction = "Decrease"
          type      = "ChangeCount"
          value     = var.scale_in_count
          cooldown  = var.scale_in_cooldown
        }
      }

      recurrence {
        timezone = var.scheduled_scaling_timezone
        days     = var.scheduled_scaling_days_of_week
        hours    = [var.scheduled_scaling_start_time_hour]
        minutes  = [var.scheduled_scaling_start_time_min]
      }
    }
  }
}
