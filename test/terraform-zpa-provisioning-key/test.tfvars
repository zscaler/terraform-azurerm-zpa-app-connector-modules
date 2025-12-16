# Test variables for ZPA Provisioning Key
# NOTE: app_connector_group_id must be set to a valid App Connector Group ID
# You can get this from the ZPA Admin Portal or by running terraform-zpa-app-connector-group test first

enrollment_cert                   = "Connector"
provisioning_key_name             = "test-provisioning-key"
provisioning_key_enabled          = true
provisioning_key_association_type = "CONNECTOR_GRP"
provisioning_key_max_usage        = "10"
app_connector_group_id            = "" # Set this to a valid App Connector Group ID
byo_provisioning_key              = false
byo_provisioning_key_name         = ""
