# Zscaler App Connector / Azure Virtual Machine Scale Sets (VMSS) Module

This module provides all required configuration parameters to create a flexible orchestration Virtual Machine Scale Set (VMSS) and scaling policies for Zscaler Ap Connector deployment.

## Accept Azure Marketplace Terms

Accept the App Connector VM image terms for the Subscription(s) where App Connector is to be deployed. This can be done via the Azure Portal, Cloud Shell or az cli / powershell with a valid admin user/service principal:

```sh
az vm image terms show --urn zscaler:zscaler-private-access:zpa-con-azure:latest
az vm image terms accept --urn zscaler:zscaler-private-access:zpa-con-azure:latest
```


<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.13.7, < 2.0.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >= 4.56.0 |
| <a name="requirement_local"></a> [local](#requirement\_local) | ~> 2.5.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | ~> 3.2.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | >= 4.56.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_monitor_autoscale_setting.vmss_autoscale_setting](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_autoscale_setting) | resource |
| [azurerm_orchestrated_virtual_machine_scale_set.ac_vmss](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/orchestrated_virtual_machine_scale_set) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_ac_nsg_id"></a> [ac\_nsg\_id](#input\_ac\_nsg\_id) | App Connector management interface nsg id | `string` | n/a | yes |
| <a name="input_ac_subnet_id"></a> [ac\_subnet\_id](#input\_ac\_subnet\_id) | App Connector subnet id | `list(string)` | n/a | yes |
| <a name="input_ac_username"></a> [ac\_username](#input\_ac\_username) | Default App Connector admin/root username | `string` | `"zsroot"` | no |
| <a name="input_acvm_image_offer"></a> [acvm\_image\_offer](#input\_acvm\_image\_offer) | Azure Marketplace Zscaler App Connector Image Offer | `string` | `"zscaler-private-access"` | no |
| <a name="input_acvm_image_publisher"></a> [acvm\_image\_publisher](#input\_acvm\_image\_publisher) | Azure Marketplace Zscaler App Connector Image Publisher | `string` | `"zscaler"` | no |
| <a name="input_acvm_image_sku"></a> [acvm\_image\_sku](#input\_acvm\_image\_sku) | Azure Marketplace Zscaler App Connector Image SKU | `string` | `"zpa-con-azure"` | no |
| <a name="input_acvm_image_version"></a> [acvm\_image\_version](#input\_acvm\_image\_version) | Azure Marketplace App Connector Image Version | `string` | `"latest"` | no |
| <a name="input_acvm_instance_type"></a> [acvm\_instance\_type](#input\_acvm\_instance\_type) | App Connector Image size. Default is Standard\_D4s\_v5 (4 vCPU Intel). AMD alternatives (Standard\_D4as\_v5) are typically 10-15% cheaper. For AppProtection workloads, use 8-core instances (Standard\_D8s\_v5 or Standard\_D8as\_v5). | `string` | `"Standard_D4s_v5"` | no |
| <a name="input_acvm_source_image_id"></a> [acvm\_source\_image\_id](#input\_acvm\_source\_image\_id) | Custom App Connector Source Image ID. Set this value to the path of a local subscription Microsoft.Compute image to override the App Connector deployment instead of using the marketplace publisher | `string` | `null` | no |
| <a name="input_backend_address_pool"></a> [backend\_address\_pool](#input\_backend\_address\_pool) | Azure LB Backend Address Pool ID for NIC association | `string` | `null` | no |
| <a name="input_encryption_at_host_enabled"></a> [encryption\_at\_host\_enabled](#input\_encryption\_at\_host\_enabled) | User input for enabling or disabling host encryption | `bool` | `true` | no |
| <a name="input_fault_domain_count"></a> [fault\_domain\_count](#input\_fault\_domain\_count) | platformFaultDomainCount must be set to 1 for max spreading or 5 for static fixed spreading. Fixed spreading with 2 or 3 fault domains isn't supported for zonal deployments | `number` | `1` | no |
| <a name="input_global_tags"></a> [global\_tags](#input\_global\_tags) | Populate any custom user defined tags from a map | `map(string)` | `{}` | no |
| <a name="input_location"></a> [location](#input\_location) | App Connector Azure Region | `string` | n/a | yes |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | A prefix to associate to all the AC VM module resources | `string` | `null` | no |
| <a name="input_resource_group"></a> [resource\_group](#input\_resource\_group) | Main Resource Group Name | `string` | n/a | yes |
| <a name="input_resource_tag"></a> [resource\_tag](#input\_resource\_tag) | A tag to associate to all the AC VM module resources | `string` | `null` | no |
| <a name="input_scale_in_cooldown"></a> [scale\_in\_cooldown](#input\_scale\_in\_cooldown) | Amount of time after scale in before scale in is evaluated again. | `string` | `"PT15M"` | no |
| <a name="input_scale_in_count"></a> [scale\_in\_count](#input\_scale\_in\_count) | Number of ACs to bring up on scale in event. | `string` | `"1"` | no |
| <a name="input_scale_in_evaluation_period"></a> [scale\_in\_evaluation\_period](#input\_scale\_in\_evaluation\_period) | Amount of time the average of scaling metric is evaluated over. | `string` | `"PT5M"` | no |
| <a name="input_scale_in_threshold"></a> [scale\_in\_threshold](#input\_scale\_in\_threshold) | Metric threshold for determining scale in. | `number` | `50` | no |
| <a name="input_scale_out_cooldown"></a> [scale\_out\_cooldown](#input\_scale\_out\_cooldown) | Amount of time after scale out before scale out is evaluated again. | `string` | `"PT15M"` | no |
| <a name="input_scale_out_count"></a> [scale\_out\_count](#input\_scale\_out\_count) | Number of ACs to bring up on scale out event. | `string` | `"1"` | no |
| <a name="input_scale_out_evaluation_period"></a> [scale\_out\_evaluation\_period](#input\_scale\_out\_evaluation\_period) | Amount of time the average of scaling metric is evaluated over. | `string` | `"PT5M"` | no |
| <a name="input_scale_out_threshold"></a> [scale\_out\_threshold](#input\_scale\_out\_threshold) | Metric threshold for determining scale out. | `number` | `70` | no |
| <a name="input_scheduled_scaling_days_of_week"></a> [scheduled\_scaling\_days\_of\_week](#input\_scheduled\_scaling\_days\_of\_week) | Days of the week to apply scheduled scaling profile. | `list(string)` | <pre>[<br/>  "Monday",<br/>  "Tuesday",<br/>  "Wednesday",<br/>  "Thursday",<br/>  "Friday"<br/>]</pre> | no |
| <a name="input_scheduled_scaling_enabled"></a> [scheduled\_scaling\_enabled](#input\_scheduled\_scaling\_enabled) | Enable scheduled scaling on top of metric scaling. | `bool` | `false` | no |
| <a name="input_scheduled_scaling_end_time_hour"></a> [scheduled\_scaling\_end\_time\_hour](#input\_scheduled\_scaling\_end\_time\_hour) | Hour to end scheduled scaling profile. | `number` | `17` | no |
| <a name="input_scheduled_scaling_end_time_min"></a> [scheduled\_scaling\_end\_time\_min](#input\_scheduled\_scaling\_end\_time\_min) | Minute to end scheduled scaling profile. | `number` | `0` | no |
| <a name="input_scheduled_scaling_start_time_hour"></a> [scheduled\_scaling\_start\_time\_hour](#input\_scheduled\_scaling\_start\_time\_hour) | Hour to start scheduled scaling profile. | `number` | `9` | no |
| <a name="input_scheduled_scaling_start_time_min"></a> [scheduled\_scaling\_start\_time\_min](#input\_scheduled\_scaling\_start\_time\_min) | Minute to start scheduled scaling profile. | `number` | `0` | no |
| <a name="input_scheduled_scaling_timezone"></a> [scheduled\_scaling\_timezone](#input\_scheduled\_scaling\_timezone) | Timezone the times for the scheduled scaling profile are specified in. | `string` | `"Pacific Standard Time"` | no |
| <a name="input_scheduled_scaling_vmss_min_acs"></a> [scheduled\_scaling\_vmss\_min\_acs](#input\_scheduled\_scaling\_vmss\_min\_acs) | Minimum number of ACs in vmss for scheduled scaling profile. | `number` | `2` | no |
| <a name="input_ssh_key"></a> [ssh\_key](#input\_ssh\_key) | SSH Key for instances | `string` | n/a | yes |
| <a name="input_user_data"></a> [user\_data](#input\_user\_data) | Cloud Init data | `string` | n/a | yes |
| <a name="input_vmss_default_acs"></a> [vmss\_default\_acs](#input\_vmss\_default\_acs) | Default number of ACs in vmss. | `number` | `2` | no |
| <a name="input_vmss_max_acs"></a> [vmss\_max\_acs](#input\_vmss\_max\_acs) | Maximum number of ACs in vmss. | `number` | `10` | no |
| <a name="input_vmss_min_acs"></a> [vmss\_min\_acs](#input\_vmss\_min\_acs) | Minimum number of ACs in vmss. | `number` | `2` | no |
| <a name="input_zones"></a> [zones](#input\_zones) | Specify which availability zone(s) to deploy VM resources in if zones\_enabled variable is set to true | `list(string)` | <pre>[<br/>  "1"<br/>]</pre> | no |
| <a name="input_zones_enabled"></a> [zones\_enabled](#input\_zones\_enabled) | Determine whether to provision App Connector VMs explicitly in defined zones (if supported by the Azure region provided in the location variable). If left false, Azure will automatically choose a zone and module will create an availability set resource instead for VM fault tolerance | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_vmss_ids"></a> [vmss\_ids](#output\_vmss\_ids) | VMSS IDs |
| <a name="output_vmss_names"></a> [vmss\_names](#output\_vmss\_names) | VMSS Names |
<!-- END_TF_DOCS -->
