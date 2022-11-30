# Zscaler App Connector / Azure VM (App Connector) Module

This module creates all the necessary VM, Network Interface, and NSG associations for a successful App Connector deployment. This module is for standalone VMs that can be deployed as an independent cluster. This resource is not intended for Azure automatic scaling (Scale Sets).

## Accept Azure Marketplace Terms

This module will attempt to automatically accept the App Connector VM image terms for the Subscription(s) where App Connector is to be deployed. This can also be performaned and verified via the Azure Portal, Cloud Shell or az cli / powershell with a valid admin user/service principal:

```sh
az vm image terms show --urn zscaler:zscaler-private-access:zpa-con-azure:latest
az vm image terms accept --urn zscaler:zscaler-private-access:zpa-con-azure:latest
```


<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.13.7, < 2.0.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 3.31.0 |
| <a name="requirement_local"></a> [local](#requirement\_local) | ~> 2.2.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | ~> 3.1.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | ~> 3.31.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_availability_set.ac_availability_set](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/availability_set) | resource |
| [azurerm_linux_virtual_machine.ac_vm](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_virtual_machine) | resource |
| [azurerm_marketplace_agreement.zs_image_agreement](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/marketplace_agreement) | resource |
| [azurerm_network_interface.ac_nic](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface) | resource |
| [azurerm_network_interface_security_group_association.ac_nic_association](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface_security_group_association) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_ac_count"></a> [ac\_count](#input\_ac\_count) | The number of App Connectors to deploy.  Validation assumes max for /24 subnet but could be smaller or larger as long as subnet can accommodate | `number` | `1` | no |
| <a name="input_ac_nsg_id"></a> [ac\_nsg\_id](#input\_ac\_nsg\_id) | App Connector management interface nsg id | `list(string)` | n/a | yes |
| <a name="input_ac_subnet_id"></a> [ac\_subnet\_id](#input\_ac\_subnet\_id) | App Connector subnet id | `list(string)` | n/a | yes |
| <a name="input_ac_username"></a> [ac\_username](#input\_ac\_username) | Default App Connector admin/root username | `string` | `"zsroot"` | no |
| <a name="input_acvm_image_offer"></a> [acvm\_image\_offer](#input\_acvm\_image\_offer) | Azure Marketplace Zscaler App Connector Image Offer | `string` | `"zscaler-private-access"` | no |
| <a name="input_acvm_image_publisher"></a> [acvm\_image\_publisher](#input\_acvm\_image\_publisher) | Azure Marketplace Zscaler App Connector Image Publisher | `string` | `"zscaler"` | no |
| <a name="input_acvm_image_sku"></a> [acvm\_image\_sku](#input\_acvm\_image\_sku) | Azure Marketplace Zscaler App Connector Image SKU | `string` | `"zpa-con-azure"` | no |
| <a name="input_acvm_image_version"></a> [acvm\_image\_version](#input\_acvm\_image\_version) | Azure Marketplace App Connector Image Version | `string` | `"latest"` | no |
| <a name="input_acvm_instance_type"></a> [acvm\_instance\_type](#input\_acvm\_instance\_type) | App Connector Image size | `string` | `"Standard_D4s_v3"` | no |
| <a name="input_global_tags"></a> [global\_tags](#input\_global\_tags) | Populate any custom user defined tags from a map | `map(string)` | `{}` | no |
| <a name="input_location"></a> [location](#input\_location) | App Connector Azure Region | `string` | n/a | yes |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | A prefix to associate to all the AC VM module resources | `string` | `null` | no |
| <a name="input_resource_group"></a> [resource\_group](#input\_resource\_group) | Main Resource Group Name | `string` | n/a | yes |
| <a name="input_resource_tag"></a> [resource\_tag](#input\_resource\_tag) | A tag to associate to all the AC VM module resources | `string` | `null` | no |
| <a name="input_ssh_key"></a> [ssh\_key](#input\_ssh\_key) | SSH Key for instances | `string` | n/a | yes |
| <a name="input_user_data"></a> [user\_data](#input\_user\_data) | Cloud Init data | `string` | n/a | yes |
| <a name="input_zones"></a> [zones](#input\_zones) | Specify which availability zone(s) to deploy VM resources in if zones\_enabled variable is set to true | `list(string)` | <pre>[<br>  "1"<br>]</pre> | no |
| <a name="input_zones_enabled"></a> [zones\_enabled](#input\_zones\_enabled) | Determine whether to provision App Connector VMs explicitly in defined zones (if supported by the Azure region provided in the location variable). If left false, Azure will automatically choose a zone and module will create an availability set resource instead for VM fault tolerance | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_ac_hostname"></a> [ac\_hostname](#output\_ac\_hostname) | Instance Host Name |
| <a name="output_private_ip"></a> [private\_ip](#output\_private\_ip) | Instance Management Interface Private IP Address |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
