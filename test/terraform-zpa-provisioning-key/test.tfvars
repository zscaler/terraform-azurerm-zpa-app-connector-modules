# Test variables for ZPA Provisioning Key
# This test creates an App Connector Group first, then creates a Provisioning Key

# App Connector Group settings
app_connector_group_name         = "test-ac-group"
app_connector_group_description  = "Test App Connector Group for Terratest"
app_connector_group_enabled      = true
app_connector_group_latitude     = "37.3382082"
app_connector_group_longitude    = "-121.8863286"
app_connector_group_location     = "San Jose, CA, USA"
app_connector_group_country_code = "US"

# Provisioning Key settings
enrollment_cert                   = "Connector"
provisioning_key_name             = "test-prov-key"
provisioning_key_enabled          = true
provisioning_key_association_type = "CONNECTOR_GRP"
provisioning_key_max_usage        = "10"
byo_provisioning_key              = false
byo_provisioning_key_name         = ""
