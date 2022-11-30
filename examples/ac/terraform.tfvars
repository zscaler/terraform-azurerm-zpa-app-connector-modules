## This is only a sample terraform.tfvars file.
## Uncomment and change the below variables according to your specific environment
#####################################################################################################################
##### Variables 5-13 are populated automically if terraform is ran via ZSAC bash script.   ##### 
##### Modifying the variables in this file will override any inputs from ZSAC              #####
#####################################################################################################################

#####################################################################################################################
##### Optional: ZPA Provider Resources. Skip to step 3. if you already have an  #####
##### App Connector Group + Provisioning Key.                                   #####
#####################################################################################################################

## 1. ZPA App Connector Provisioning Key variables. Uncomment and replace default values as desired for your deployment.
##    For any questions populating the below values, please reference: 
##    https://registry.terraform.io/providers/zscaler/zpa/latest/docs/resources/zpa_provisioning_key

#enrollment_cert                                = "Connector"
#provisioning_key_name                          = "new_key_name"
#provisioning_key_enabled                       = true
#provisioning_key_max_usage                     = 10

## 2. ZPA App Connector Group variables. Uncomment and replace default values as desired for your deployment. 
##    For any questions populating the below values, please reference: 
##    https://registry.terraform.io/providers/zscaler/zpa/latest/docs/resources/zpa_app_connector_group

#app_connector_group_name                       = "new_group_name"
#app_connector_group_description                = "group_description"
#app_connector_group_enabled                    = true
#app_connector_group_country_code               = "US"
#app_connector_group_latitude                   = "37.3382082"
#app_connector_group_longitude                  = "-121.8863286"
#app_connector_group_location                   = "San Jose, CA, USA"
#app_connector_group_upgrade_day                = "SUNDAY"
#app_connector_group_upgrade_time_in_secs       = "66600"
#app_connector_group_override_version_profile   = true
#app_connector_group_version_profile_id         = "2"
#app_connector_group_dns_query_type             = "IPV4_IPV6"


#####################################################################################################################
##### Optional: ZPA Provider Resources. Skip to step 5. if you added values for steps 1. and 2. #####
##### meaning you do NOT have a provisioning key already.                                       #####
#####################################################################################################################

## 3. By default, this script will create a new App Connector Group Provisioning Key.
##     Uncomment if you want to use an existing provisioning key (true or false. Default: false)

#byo_provisioning_key                           = true

## 4. Provide your existing provisioning key name. Only uncomment and modify if yo uset byo_provisioning_key to true

#byo_provisioning_key_name                      = "example-key-name"

#####################################################################################################################
##### Custom variables. Only change if required for your environment  #####
#####################################################################################################################

## 5. Azure region where App Connector resources will be deployed. This environment variable is automatically populated if running ZSAC script
##    and thus will override any value set here. Only uncomment and set this value if you are deploying terraform standalone. (Default: westus2)

#arm_location                               = "westus2"

## 6. App Connector Azure VM Instance size selection. Uncomment acvm_instance_type line with desired vm size to change.
##    (Default: Standard_D4s_v3)

#acvm_instance_type                         = "Standard_D4s_v3"
#acvm_instance_type                         = "Standard_F4s_v2"

## 7. The number of App Connector appliances to provision. Each incremental App Connector will be created in alternating 
##     subnets based on the zones or byo_subnet_names variable and loop through for any deployments where ac_count > zones.
##     E.g. ac_count set to 4 and 2 zones set ['1","2"] will create 2x ACs in AZ1 and 2x ACs in AZ2

#ac_count                                   = 2

## 8. By default, no zones are specified in any resource creation meaning they are either auto-assigned by Azure 
##    (Virtual Machines and NAT Gateways) or Zone-Redundant (Public IP) based on whatever default configuration is.
##    Setting this value to true will do the following:
##    1. will create zonal NAT Gateway resources in order of the zones [1-3] specified in zones variable. 1x per zone
##    2. will NOT create availability set resource nor associate App Connector VMs to one
##    3. will create zonal App Connector Virtual Machine appliances looping through and alternating per the order of the zones 
##       [1-3] specified in the zones variable AND total number of App Connectors specified in ac_count variable.
##    (Default: false)

#zones_enabled                              = true

## 9. By default, this variable is used as a count (1) for resource creation of Public IP, NAT Gateway, and AC Subnets.
##    This should only be modified if zones_enabled is also set to true
##    Doing so will change the default zone aware configuration for the 3 aforementioned resources with the values specified
##    
##    Use case: Define zone numbers "1" and "2". This will create 2x Public IPs (one in zone 1; the other in zone 2),
##              2x NAT Gateways (one in zone 1; the other in zone 2), associate the zone 1 PIP w/ zone 1 NAT GW and the zone 2
##              PIP w/ zone 2 NAT GW, create 2x AC Subnets and associate subnet 1 w/ zone 1 NAT GW and subnet 2 w/ zone 2 NAT GW,
##              then each AC created will be assigned a zone in the subnet corresponding to the same zone of the NAT GW and PIP associated.

##    Uncomment one of the desired zones configuration below.

#zones                                      = ["1"]
#zones                                      = ["1","2"]
#zones                                      = ["1","2","3"]

## 10. Network Configuration:

##    IPv4 CIDR configured with VNet creation. All Subnet resources (Workload, Public, and App Connector) will be created based off this prefix
##    /24 subnets are created assuming this cidr is a /16. If you require creating a VNet smaller than /16, you may need to explicitly define all other 
##     subnets via public_subnets, and ac_subnets variables (Default: "10.1.0.0/16")

##    Note: This variable only applies if you let Terraform create a new VNet. Custom deployment with byo_vnet enabled will ignore this

#network_address_space                      = "10.1.0.0/16"

##    Subnet space. (Minimum /28 required. Default is null). If you do not specify subnets, they will automatically be assigned based on the default cidrsubnet
##    creation within the VNet address_prefix block. Uncomment and modify if byo_vnet is set to true but byo_subnets is left false meaning you want terraform to create 
##    NEW subnets in that existing VNet. OR if you choose to modify the network_address_space from the default /16 so a smaller CIDR, you may need to edit the below variables 
##    to accommodate that address space.

##    ***** Note *****
##    It does not matter how many subnets you specify here. this script will only create in order 1 or as many as defined in the zones variable
##    Default/Minumum: 1 - Maximum: 3
##    Example: If you change network_address_space to "10.2.0.0/24", set below variables to cidrs that fit in that /24 like ac_subnets = ["10.2.0.0/27","10.2.0.32/27"] etc.

#public_subnets                             = ["10.x.y.z/24","10.x.y.z/24"]
#ac_subnets                                 = ["10.x.y.z/24","10.x.y.z/24"]

## 11. Tag attribute "Owner" assigned to all resoure creation. (Default: "zsac-admin")

#owner_tag                                  = "username@company.com"

## 12. Tag attribute "Environment" assigned to all resources created. (Default: "Development")

#environment                                = "Development"

## 13. By default, this script will apply 1 Network Security Group per App Connector instance. 
##     Uncomment if you want to use the same Network Security Group for ALL App Connectors (true or false. Default: false)

#reuse_nsg                                  = true


#####################################################################################################################
##### Custom BYO variables. Only applicable for "ac" deployment without "base" resource requirements  #####
#####################################################################################################################

## 14. By default, this script will create a new Resource Group and place all resources in this group.
##     Uncomment if you want to deploy all resources in an existing Resource Group? (true or false. Default: false)

#byo_rg                                     = true

## 15. Provide your existing Resource Group name. Only uncomment and modify if you set byo_rg to true

#byo_rg_name                                = "existing-rg"

## 16. By default, this script will create a new Azure Virtual Network in the default resource group.
##     Uncomment if you want to deploy all resources to a VNet that already exists (true or false. Default: false)

#byo_vnet                                   = true

## 17. Provide your existing VNet name. Only uncomment and modify if you set byo_vnet to true

#byo_vnet_name                              = "existing-vnet"

## 18. Provide the existing Resource Group name of your VNet. Only uncomment and modify if you set byo_vnet to true
##     Subnets depend on VNet so the same resource group is implied for subnets

#byo_vnet_subnets_rg_name                   = "existing-vnet-rg"

## 19. By default, this script will create 1 new Azure subnet in the default resource group unles the zones variable
##     specifies multiple zonal deployments in which case subnet 1 would logically map to resources in zone "1", etc.
##     Uncomment if you want to deploy all resources in subnets that already exist (true or false. Default: false)
##     Dependencies require in order to reference existing subnets, the corresponding VNet must also already exist.
##     Setting byo_subnet to true means byo_vnet must ALSO be set to true.

#byo_subnets                                = true

## 20. Provide your existing App Connector subnet names. Only uncomment and modify if you set byo_subnets to true
##     By default, management and service interfaces reside in a single subnet. Therefore, specifying multiple subnets
##     implies only that you are doing a zonal deployment with resources in separate AZs and corresponding zonal NAT
##     Gateway resources associated with the AC subnets mapped to the same respective zones.
##
##     Example: byo_subnet_names = ["subnet-az1","subnet-az2"]

#byo_subnet_names                           = ["existing-ac-subnet"]

## 21. By default, this script will create new Public IP resources to be associated with AC NAT Gateways.
##     Uncomment if you want to use your own public IP for the NAT GW (true or false. Default: false)

#byo_pips                                   = true

## 22. Provide your existing Azure Public IP resource names. Only uncomment and modify if you set byo_pips to true
##     Existing Public IP resource cannot be associated with any resource other than an existing NAT Gateway in which
##     case existing_pip_association and existing_nat_gw_association need both set to true
##
##    ***** Note *****
##    If you already have existing PIPs AND set zone_enabled to true, these resource should be configured as zonal and
##    be added here to this variable list in order of the zones specified in the "zones" variable. 
##    Example: byo_pip_names = ["pip-az1","pip-az2"]

#byo_pip_names                              = ["pip-az1","pip-az2"]

## 23. Provide the existing Resource Group name of your Azure public IPs.  Only uncomment and modify if you set byo_pips to true

#byo_pip_rg                                 = "existing-pip-rg"

## 24. By default, this script will create new NAT Gateway resources for the App Connector subnets to be associated
##    Uncomment if you want to use your own NAT Gateway (true or false. Default: false)

#byo_nat_gws                                = true

## 25. Provide your existing Azure NAT Gateway resource names. Only uncomment and modify if you set byo_nat_gws to true
##    ***** Note *****
##    If you already have existing NAT Gateways AND set zone_enabled to true these resource should be configured as zonal and
##    be added here to this variable list in order of the zones specified in the "zones" variable. 
##    Example: byo_nat_gw_names  = ["natgw-az1","natgw-az2"]

#byo_nat_gw_names                           = ["natgw-az1","natgw-az2"]

## 26. Provide the existing Resource Group name of your NAT Gateway.  Only uncomment and modify if you set byo_nat_gws to true

#byo_nat_gw_rg                              = "existing-nat-gw-rg"

## 27.  By default, this script will create a new Azure Public IP and associate it with new/existing NAT Gateways.
##      Uncomment if you are deploying App Connector to an environment where the PIP already exists AND is already asssociated to
##      an existing NAT Gateway. (true or false. Default: false). 
##      Setting existing_pip_association to true means byo_nat_gws and byo_pips must ALSO be set to true.

#existing_nat_gw_pip_association            = true

## 28.  By default this script will create a new Azure NAT Gateway and associate it with new or existing AC subnets.
##      Uncomment if you are deploying App Connector to an environment where the subnet already exists AND is already asssociated to
##      an existing NAT Gateway. (true or false. Default: false). 
##      Setting existing_nat_gw_association to true means byo_subnets AND byo_nat_gws must also be set to true.

#existing_nat_gw_subnet_association         = true

## 29. By default, this script will create new Network Security Groups for the App Connector interfaces
##     Uncomment if you want to use your own NSGs (true or false. Default: false)

#byo_nsg                                    = true

## 30. Provide your existing Network Security Group resource names. Only uncomment and modify if you set byo_nsg to true
##     ***** Note *****

##    Example: byo_nsg_names                = ["mgmt-nsg-1","mgmt-nsg-2"]

#byo_nsg_names                              = ["mgmt-nsg-1","mgmt-nsg-2"]

## 31. Provide the existing Resource Group name of your Network Security Groups.  Only uncomment and modify if you set byo_nsg to true

#byo_nsg_rg                                 = "existing-nsg-rg"
