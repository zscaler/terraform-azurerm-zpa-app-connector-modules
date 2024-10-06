# Zscaler App Connector / Azure Network Infrastructure Module

This module has multi-purpose use and is leveraged by all other Zscaler App Connector child modules in some capacity. All network infrastructure resources pertaining to connectivity dependencies for a successful App Connector deployment in a private subnet are referenced here. Full list of resources can be found below, but in general this module will handle all Resource Group, VNet, Subnets, NAT Gateways, Public IP, and Route Table creations to build out a resilient Azure network architecture. Most resources also have "conditional create" capabilities where, by default, they will all be created unless instructed not to with various "byo" and "enabled" variables. Use cases are documented in more detail in each description in variables.tf as well as the terraform.tfvars example file for all non-base deployment types (ie: cc_lb, etc.).

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.13.7, < 2.0.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 3.113.0 |
| <a name="requirement_local"></a> [local](#requirement\_local) | ~> 2.5.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | ~> 3.2.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | ~> 3.113.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_nat_gateway.ngw](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/nat_gateway) | resource |
| [azurerm_nat_gateway_public_ip_association.ngw_association](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/nat_gateway_public_ip_association) | resource |
| [azurerm_public_ip.pip](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip) | resource |
| [azurerm_resource_group.rg](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) | resource |
| [azurerm_subnet.ac_subnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) | resource |
| [azurerm_subnet.bastion_subnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) | resource |
| [azurerm_subnet_nat_gateway_association.ac_subnet_nat_association](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_nat_gateway_association) | resource |
| [azurerm_virtual_network.vnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network) | resource |
| [azurerm_nat_gateway.ngw_selected](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/nat_gateway) | data source |
| [azurerm_public_ip.pip_selected](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/public_ip) | data source |
| [azurerm_resource_group.rg_selected](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/resource_group) | data source |
| [azurerm_subnet.ac_subnet_selected](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/subnet) | data source |
| [azurerm_virtual_network.vnet_selected](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/virtual_network) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_ac_subnets"></a> [ac\_subnets](#input\_ac\_subnets) | App Connector Subnets to create in VNet. This is only required if you want to override the default subnets that this code creates via network\_address\_space variable. | `list(string)` | `null` | no |
| <a name="input_base_only"></a> [base\_only](#input\_base\_only) | Default is false. Only applicable for base deployment type resulting in workload and bastion hosts, but no App Connector resources. Setting this to true will point workload route able to Internet | `bool` | `false` | no |
| <a name="input_bastion_enabled"></a> [bastion\_enabled](#input\_bastion\_enabled) | Configure Bastion/Public Subnet if set to true | `bool` | `false` | no |
| <a name="input_byo_nat_gw_names"></a> [byo\_nat\_gw\_names](#input\_byo\_nat\_gw\_names) | User provided existing NAT Gateway resource names. This must be populated if byo\_nat\_gws variable is true | `list(string)` | `null` | no |
| <a name="input_byo_nat_gw_rg"></a> [byo\_nat\_gw\_rg](#input\_byo\_nat\_gw\_rg) | User provided existing NAT Gateway Resource Group. This must be populated if byo\_nat\_gws variable is true | `string` | `""` | no |
| <a name="input_byo_nat_gws"></a> [byo\_nat\_gws](#input\_byo\_nat\_gws) | Bring your own Azure NAT Gateways | `bool` | `false` | no |
| <a name="input_byo_pip_names"></a> [byo\_pip\_names](#input\_byo\_pip\_names) | User provided Azure Public IP address resource names to be associated to NAT Gateway(s) | `list(string)` | `null` | no |
| <a name="input_byo_pip_rg"></a> [byo\_pip\_rg](#input\_byo\_pip\_rg) | User provided Azure Public IP address resource group name. This must be populated if byo\_pip\_names variable is true | `string` | `""` | no |
| <a name="input_byo_pips"></a> [byo\_pips](#input\_byo\_pips) | Bring your own Azure Public IP addresses for the NAT Gateway(s) association | `bool` | `false` | no |
| <a name="input_byo_rg"></a> [byo\_rg](#input\_byo\_rg) | Bring your own Azure Resource Group. If false, a new resource group will be created automatically | `bool` | `false` | no |
| <a name="input_byo_rg_name"></a> [byo\_rg\_name](#input\_byo\_rg\_name) | User provided existing Azure Resource Group name. This must be populated if byo\_rg variable is true | `string` | `""` | no |
| <a name="input_byo_subnet_names"></a> [byo\_subnet\_names](#input\_byo\_subnet\_names) | User provided existing Azure subnet name(s). This must be populated if byo\_subnets variable is true | `list(string)` | `null` | no |
| <a name="input_byo_subnets"></a> [byo\_subnets](#input\_byo\_subnets) | Bring your own Azure subnets for App Connector. If false, new subnet(s) will be created automatically. Default 1 subnet for App Connector if 1 or no zones specified. Otherwise, number of subnes created will equal number of App Connector zones | `bool` | `false` | no |
| <a name="input_byo_vnet"></a> [byo\_vnet](#input\_byo\_vnet) | Bring your own Azure VNet for App Connector. If false, a new VNet will be created automatically | `bool` | `false` | no |
| <a name="input_byo_vnet_name"></a> [byo\_vnet\_name](#input\_byo\_vnet\_name) | User provided existing Azure VNet name. This must be populated if byo\_vnet variable is true | `string` | `""` | no |
| <a name="input_byo_vnet_subnets_rg_name"></a> [byo\_vnet\_subnets\_rg\_name](#input\_byo\_vnet\_subnets\_rg\_name) | User provided existing Azure VNET Resource Group. This must be populated if either byo\_vnet or byo\_subnets variables are true | `string` | `""` | no |
| <a name="input_existing_nat_gw_pip_association"></a> [existing\_nat\_gw\_pip\_association](#input\_existing\_nat\_gw\_pip\_association) | Set this to true only if both byo\_pips and byo\_nat\_gws variables are true. This implies that there are already NAT Gateway resources with Public IP Addresses associated so we do not attempt any new associations | `bool` | `false` | no |
| <a name="input_existing_nat_gw_subnet_association"></a> [existing\_nat\_gw\_subnet\_association](#input\_existing\_nat\_gw\_subnet\_association) | Set this to true only if both byo\_nat\_gws and byo\_subnets variables are true. this implies that there are already NAT Gateway resources associated to subnets where App Connectors are being deployed to | `bool` | `false` | no |
| <a name="input_global_tags"></a> [global\_tags](#input\_global\_tags) | Populate any custom user defined tags from a map | `map(string)` | `{}` | no |
| <a name="input_location"></a> [location](#input\_location) | App Connector Azure Region | `string` | n/a | yes |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | A prefix to associate to all the network module resources | `string` | `null` | no |
| <a name="input_network_address_space"></a> [network\_address\_space](#input\_network\_address\_space) | VNet IP CIDR Range. All subnet resources that might get created (public, app connector) are derived from this /16 CIDR. If you require creating a VNet smaller than /16, you may need to explicitly define all other subnets via public\_subnets and ac\_subnets, variables | `string` | `"10.1.0.0/16"` | no |
| <a name="input_public_subnets"></a> [public\_subnets](#input\_public\_subnets) | Public/Bastion Subnets to create in VNet. This is only required if you want to override the default subnets that this code creates via network\_address\_space variable. | `list(string)` | `null` | no |
| <a name="input_resource_tag"></a> [resource\_tag](#input\_resource\_tag) | A tag to associate to all the network module resources | `string` | `null` | no |
| <a name="input_zones"></a> [zones](#input\_zones) | Specify which availability zone(s) to deploy VM resources in if zones\_enabled variable is set to true | `list(string)` | <pre>[<br>  "1"<br>]</pre> | no |
| <a name="input_zones_enabled"></a> [zones\_enabled](#input\_zones\_enabled) | Determine whether to provision App Connector VMs explicitly in defined zones (if supported by the Azure region provided in the location variable). If left false, Azure will automatically choose a zone and module will create an availability set resource instead for VM fault tolerance | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_ac_subnet_ids"></a> [ac\_subnet\_ids](#output\_ac\_subnet\_ids) | App Connector Subnet ID |
| <a name="output_bastion_subnet_ids"></a> [bastion\_subnet\_ids](#output\_bastion\_subnet\_ids) | Bastion Host Subnet ID |
| <a name="output_public_ip_address"></a> [public\_ip\_address](#output\_public\_ip\_address) | Azure Public IP Address |
| <a name="output_resource_group_name"></a> [resource\_group\_name](#output\_resource\_group\_name) | Azure Resource Group Name |
| <a name="output_virtual_network_id"></a> [virtual\_network\_id](#output\_virtual\_network\_id) | Azure Virtual Network ID |
<!-- END_TF_DOCS -->
