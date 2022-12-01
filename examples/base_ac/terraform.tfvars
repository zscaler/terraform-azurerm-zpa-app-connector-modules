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

arm_location = "canadacentral"

## 6. App Connector Azure VM Instance size selection. Uncomment acvm_instance_type line with desired vm size to change.
##    (Default: Standard_D4s_v3)

acvm_instance_type = "Standard_D4s_v3"
#acvm_instance_type                         = "Standard_F4s_v2"

## 7. The number of App Connector appliances to provision. Each incremental App Connector will be created in alternating
##     subnets based on the zones or byo_subnet_names variable and loop through for any deployments where ac_count > zones.
##     E.g. ac_count set to 4 and 2 zones set ['1","2"] will create 2x ACs in AZ1 and 2x ACs in AZ2

ac_count = 2

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
