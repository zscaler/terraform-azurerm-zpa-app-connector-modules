# Zscaler "base_ac_vmss" deployment type

This deployment type is intended for greenfield/pov/lab purposes. It will deploy a fully functioning sandbox environment in a new Resource Group/VNet with test public access via a public bastion host. Full set of resources provisioned listed below; Effectively, this will create all network infrastructure dependencies for an Azure environment. Everything from "Base" deployment type (Creates 1 new Resource Group; 1 VNet with 1 public subnet and 1 private/workload subnet; 1 Bastion Host in the public subnet assigned a Public IP; and generates local key pair .pem file for ssh access).<br>

Additionally: Depending on the configuration, creates 1 or more Flexible Orchestration Virtual Machine Scale Sets (VMSS) and scaling policies for App Connector in private subnet(s).

We are leveraging the [Zscaler ZPA Provider](https://github.com/zscaler/terraform-provider-zpa) to connect to your ZPA Admin console and provision a new App Connector Group + Provisioning Key. You can still run this template if deploying to an existing App Connector Group rather than creating a new one, but using the conditional create functionality from variable byo_provisioning_key and supplying to name of your provisioning key to variable byo_provisioning_key_name. In either deployment, this is fed directly into the userdata for bootstrapping.<br>

There are conditional create options for almost all dependent resources should they already exist (VNet, subnets, NAT Gateways, Public IPs, NSGs, etc.)


## Caveats/Considerations
- WSL2 DNS bug: If you are trying to run these Azure terraform deployments specifically from a Windows WSL2 instance like Ubuntu and receive an error containing a message similar to this "dial tcp: lookup management.azure.com on 172.21.240.1:53: cannot unmarshal DNS message" please refer here for a WSL2 resolv.conf fix. https://github.com/microsoft/WSL/issues/5420#issuecomment-646479747.

## How to deploy:

### Option 1 (guided):
Optional: Edit the terraform.tfvars file under your desired deployment type (ie: ac_vmss) to setup your App Connector Group (Details are documented inside the file)
From the examples directory, run the zsac bash script that walks to all required inputs.
- ./zsac up
- enter "brownfield"
- enter "ac_vmss"
- follow the remainder of the authentication and configuration input prompts.
- script will detect client operating system and download/run a specific version of terraform in a temporary bin directory
- inputs will be validated and terraform init/apply will automatically exectute.
- verify all resources that will be created/modified and enter "yes" to confirm

### Option 2 (manual):
Modify/populate any required variable input values in ac_vmss/terraform.tfvars file and save.

From ac_vmss directory execute:
- terraform init
- terraform apply

## How to destroy:

### Option 1 (guided):
From the examples directory, run the zsac bash script that walks to all required inputs.
- ./zsac destroy

### Option 2 (manual):
From ac_vmss directory execute:
- terraform destroy

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.13.7, < 2.0.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >= 4.56.0 |
| <a name="requirement_local"></a> [local](#requirement\_local) | ~> 2.5.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | ~> 3.2.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.6.0 |
| <a name="requirement_tls"></a> [tls](#requirement\_tls) | ~> 4.0.0 |
| <a name="requirement_zpa"></a> [zpa](#requirement\_zpa) | ~> 4.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_local"></a> [local](#provider\_local) | ~> 2.5.0 |
| <a name="provider_random"></a> [random](#provider\_random) | ~> 3.6.0 |
| <a name="provider_tls"></a> [tls](#provider\_tls) | ~> 4.0.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_ac_nsg"></a> [ac\_nsg](#module\_ac\_nsg) | ../../modules/terraform-zsac-nsg-azure | n/a |
| <a name="module_ac_vmss"></a> [ac\_vmss](#module\_ac\_vmss) | ../../modules/terraform-zsac-acvmss-azure | n/a |
| <a name="module_bastion"></a> [bastion](#module\_bastion) | ../../modules/terraform-zsac-bastion-azure | n/a |
| <a name="module_network"></a> [network](#module\_network) | ../../modules/terraform-zsac-network-azure | n/a |
| <a name="module_zpa_app_connector_group"></a> [zpa\_app\_connector\_group](#module\_zpa\_app\_connector\_group) | ../../modules/terraform-zpa-app-connector-group | n/a |
| <a name="module_zpa_provisioning_key"></a> [zpa\_provisioning\_key](#module\_zpa\_provisioning\_key) | ../../modules/terraform-zpa-provisioning-key | n/a |

## Resources

| Name | Type |
|------|------|
| [local_file.private_key](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [local_file.testbed](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [local_file.user_data_file](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [random_string.suffix](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |
| [tls_private_key.key](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_ac_subnets"></a> [ac\_subnets](#input\_ac\_subnets) | App Connector Subnets to create in VNet. This is only required if you want to override the default subnets that this code creates via network\_address\_space variable. | `list(string)` | `null` | no |
| <a name="input_acvm_image_offer"></a> [acvm\_image\_offer](#input\_acvm\_image\_offer) | Azure Marketplace Zscaler App Connector Image Offer | `string` | `"zscaler-private-access"` | no |
| <a name="input_acvm_image_publisher"></a> [acvm\_image\_publisher](#input\_acvm\_image\_publisher) | Azure Marketplace Zscaler App Connector Image Publisher | `string` | `"zscaler"` | no |
| <a name="input_acvm_image_sku"></a> [acvm\_image\_sku](#input\_acvm\_image\_sku) | Azure Marketplace Zscaler App Connector Image SKU | `string` | `"zpa-con-azure"` | no |
| <a name="input_acvm_image_version"></a> [acvm\_image\_version](#input\_acvm\_image\_version) | Azure Marketplace App Connector Image Version | `string` | `"latest"` | no |
| <a name="input_acvm_instance_type"></a> [acvm\_instance\_type](#input\_acvm\_instance\_type) | App Connector Image size | `string` | `"Standard_D4s_v5"` | no |
| <a name="input_app_connector_group_country_code"></a> [app\_connector\_group\_country\_code](#input\_app\_connector\_group\_country\_code) | Optional: Country code of this App Connector Group. example 'US' | `string` | `"US"` | no |
| <a name="input_app_connector_group_description"></a> [app\_connector\_group\_description](#input\_app\_connector\_group\_description) | Optional: Description of the App Connector Group | `string` | `"This App Connector Group belongs to: "` | no |
| <a name="input_app_connector_group_dns_query_type"></a> [app\_connector\_group\_dns\_query\_type](#input\_app\_connector\_group\_dns\_query\_type) | Whether to enable IPv4 or IPv6, or both, for DNS resolution of all applications in the App Connector Group | `string` | `"IPV4_IPV6"` | no |
| <a name="input_app_connector_group_enabled"></a> [app\_connector\_group\_enabled](#input\_app\_connector\_group\_enabled) | Whether this App Connector Group is enabled or not | `bool` | `true` | no |
| <a name="input_app_connector_group_latitude"></a> [app\_connector\_group\_latitude](#input\_app\_connector\_group\_latitude) | Latitude of the App Connector Group. Integer or decimal. With values in the range of -90 to 90 | `string` | `"37.33874"` | no |
| <a name="input_app_connector_group_location"></a> [app\_connector\_group\_location](#input\_app\_connector\_group\_location) | location of the App Connector Group in City, State, Country format. example: 'San Jose, CA, USA' | `string` | `"San Jose, CA, USA"` | no |
| <a name="input_app_connector_group_longitude"></a> [app\_connector\_group\_longitude](#input\_app\_connector\_group\_longitude) | Longitude of the App Connector Group. Integer or decimal. With values in the range of -90 to 90 | `string` | `"-121.8852525"` | no |
| <a name="input_app_connector_group_override_version_profile"></a> [app\_connector\_group\_override\_version\_profile](#input\_app\_connector\_group\_override\_version\_profile) | Optional: Whether the default version profile of the App Connector Group is applied or overridden. Default: false | `bool` | `true` | no |
| <a name="input_app_connector_group_upgrade_day"></a> [app\_connector\_group\_upgrade\_day](#input\_app\_connector\_group\_upgrade\_day) | Optional: App Connectors in this group will attempt to update to a newer version of the software during this specified day. Default value: SUNDAY. List of valid days (i.e., SUNDAY, MONDAY, etc) | `string` | `"SUNDAY"` | no |
| <a name="input_app_connector_group_upgrade_time_in_secs"></a> [app\_connector\_group\_upgrade\_time\_in\_secs](#input\_app\_connector\_group\_upgrade\_time\_in\_secs) | Optional: App Connectors in this group will attempt to update to a newer version of the software during this specified time. Default value: 66600. Integer in seconds (i.e., 66600). The integer should be greater than or equal to 0 and less than 86400, in 15 minute intervals | `string` | `"66600"` | no |
| <a name="input_app_connector_group_version_profile_id"></a> [app\_connector\_group\_version\_profile\_id](#input\_app\_connector\_group\_version\_profile\_id) | Optional: ID of the version profile. To learn more, see Version Profile Use Cases. https://help.zscaler.com/zpa/configuring-version-profile | `string` | `"2"` | no |
| <a name="input_arm_location"></a> [arm\_location](#input\_arm\_location) | The Azure Region where resources are to be deployed | `string` | `"westus2"` | no |
| <a name="input_bastion_nsg_source_prefix"></a> [bastion\_nsg\_source\_prefix](#input\_bastion\_nsg\_source\_prefix) | User input for locking down SSH access to bastion to a specific IP or CIDR range. Defaults to any IP | `string` | `"*"` | no |
| <a name="input_byo_provisioning_key"></a> [byo\_provisioning\_key](#input\_byo\_provisioning\_key) | Bring your own App Connector Provisioning Key. Setting this variable to true will effectively instruct this module to not create any resources and only reference data resources from values provided in byo\_provisioning\_key\_name | `bool` | `false` | no |
| <a name="input_byo_provisioning_key_name"></a> [byo\_provisioning\_key\_name](#input\_byo\_provisioning\_key\_name) | Existing App Connector Provisioning Key name | `string` | `"provisioning-key-tf"` | no |
| <a name="input_custom_name"></a> [custom\_name](#input\_custom\_name) | The full name of the resource. If provided, this will override name\_prefix and resource\_tag. | `string` | `null` | no |
| <a name="input_encryption_at_host_enabled"></a> [encryption\_at\_host\_enabled](#input\_encryption\_at\_host\_enabled) | User input for enabling or disabling host encryption | `bool` | `true` | no |
| <a name="input_enrollment_cert"></a> [enrollment\_cert](#input\_enrollment\_cert) | Get name of ZPA enrollment cert to be used for App Connector provisioning | `string` | `"Connector"` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Customer defined environment tag. ie: Dev, QA, Prod, etc. | `string` | `"Development"` | no |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | The name prefix for all your resources | `string` | `"zsac"` | no |
| <a name="input_network_address_space"></a> [network\_address\_space](#input\_network\_address\_space) | VNet IP CIDR Range. All subnet resources that might get created (public, app connector) are derived from this /16 CIDR. If you require creating a VNet smaller than /16, you may need to explicitly define all other subnets via public\_subnets and ac\_subnets variables | `string` | `"10.1.0.0/16"` | no |
| <a name="input_owner_tag"></a> [owner\_tag](#input\_owner\_tag) | Customer defined owner tag value. ie: Org, Dept, username, etc. | `string` | `"zsac-admin"` | no |
| <a name="input_provisioning_key_association_type"></a> [provisioning\_key\_association\_type](#input\_provisioning\_key\_association\_type) | Specifies the provisioning key type for App Connectors or ZPA Private Service Edges. The supported values are CONNECTOR\_GRP and SERVICE\_EDGE\_GRP | `string` | `"CONNECTOR_GRP"` | no |
| <a name="input_provisioning_key_enabled"></a> [provisioning\_key\_enabled](#input\_provisioning\_key\_enabled) | Whether the provisioning key is enabled or not. Default: true | `bool` | `true` | no |
| <a name="input_provisioning_key_max_usage"></a> [provisioning\_key\_max\_usage](#input\_provisioning\_key\_max\_usage) | The maximum number of instances where this provisioning key can be used for enrolling an App Connector or Service Edge | `number` | `10` | no |
| <a name="input_public_subnets"></a> [public\_subnets](#input\_public\_subnets) | Public/Bastion Subnets to create in VNet. This is only required if you want to override the default subnets that this code creates via network\_address\_space variable. | `list(string)` | `null` | no |
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
| <a name="input_tls_key_algorithm"></a> [tls\_key\_algorithm](#input\_tls\_key\_algorithm) | algorithm for tls\_private\_key resource | `string` | `"RSA"` | no |
| <a name="input_vmss_default_acs"></a> [vmss\_default\_acs](#input\_vmss\_default\_acs) | Default number of ACs in vmss. | `number` | `2` | no |
| <a name="input_vmss_max_acs"></a> [vmss\_max\_acs](#input\_vmss\_max\_acs) | Maximum number of ACs in vmss. | `number` | `10` | no |
| <a name="input_vmss_min_acs"></a> [vmss\_min\_acs](#input\_vmss\_min\_acs) | Minimum number of ACs in vmss. | `number` | `2` | no |
| <a name="input_zones"></a> [zones](#input\_zones) | Specify which availability zone(s) to deploy VM resources in if zones\_enabled variable is set to true | `list(string)` | <pre>[<br/>  "1"<br/>]</pre> | no |
| <a name="input_zones_enabled"></a> [zones\_enabled](#input\_zones\_enabled) | Determine whether to provision App Connector VMs explicitly in defined zones (if supported by the Azure region provided in the location variable). If left false, Azure will automatically choose a zone and module will create an availability set resource instead for VM fault tolerance | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_testbedconfig"></a> [testbedconfig](#output\_testbedconfig) | Azure Testbed results |
<!-- END_TF_DOCS -->
