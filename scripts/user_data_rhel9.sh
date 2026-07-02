#!/usr/bin/bash
################################################################################
# RHEL9 App Connector User Data Script (Azure)
# Supports both Fixed VMs and VM Scale Sets, and both onboarding methods:
#   - oauth            : retrieve OAuth2 user code from /etc/issue and publish it
#                        to an Azure Key Vault secret for Terraform to enroll.
#   - provisioning_key : write the ZPA provisioning key to the connector and let
#                        it self-enroll. No Key Vault interaction required.
#
# Token storage on Azure uses Key Vault + the VM's system-assigned Managed
# Identity. The VM authenticates with `az login --identity`, so no secrets are
# embedded in this script.
#
# NOTE: This is a Terraform template file. Template variables are substituted by
# Terraform before script execution. Shellcheck warnings about undefined
# variables can be ignored.
################################################################################

# Sleep to allow the system to initialize
sleep 15

# Create the Zscaler repository file
touch /etc/yum.repos.d/zscaler.repo
cat > /etc/yum.repos.d/zscaler.repo <<-EOT
[zscaler]
name=Zscaler Private Access Repository
baseurl=https://yum.private.zscaler.com/yum/el9
enabled=1
gpgcheck=1
gpgkey=https://yum.private.zscaler.com/yum/el9/gpg
EOT

# Sleep to allow the repo file to be registered
sleep 60

# Install App Connector packages
yum install -y zpa-connector

%{ if onboarding_method == "provisioning_key" ~}
################################################################################
# Provisioning key onboarding
################################################################################

# Stop the App Connector service which was auto-started at boot time
systemctl stop zpa-connector

# Write the provisioning key created via the ZPA provider to the connector.
# Keep the key between double quotes.
echo "${provisioning_key}" > /opt/zscaler/var/provision_key
chmod 644 /opt/zscaler/var/provision_key

# Run a yum update to apply the latest patches
yum update -y

# Start the App Connector service to enroll it in the ZPA cloud
systemctl start zpa-connector

# Wait for the App Connector to download the latest build, then restart
sleep 60
systemctl stop zpa-connector
systemctl start zpa-connector

%{ else ~}
################################################################################
# OAuth2 onboarding
################################################################################

# Install the Azure CLI (used to publish the OAuth token to Key Vault via MSI)
rpm --import https://packages.microsoft.com/keys/microsoft.asc
dnf install -y https://packages.microsoft.com/config/rhel/9.0/packages-microsoft-prod.rpm
dnf install -y azure-cli

# Verify Azure CLI installation
az --version || echo "WARNING: az CLI installation may have failed"

# Key Vault and secret name are injected by Terraform.
KEY_VAULT_NAME="${key_vault_name}"
%{ if is_vmss ~}
# VMSS: derive a unique per-instance secret name from instance metadata.
INSTANCE_NAME=$(curl -s -H "Metadata:true" "http://169.254.169.254/metadata/instance/compute/name?api-version=2021-02-01&format=text" 2>/dev/null)
SECRET_NAME="${secret_name_prefix}-$(echo "$INSTANCE_NAME" | tr -c 'a-zA-Z0-9' '-' | sed 's/-\+/-/g;s/^-//;s/-$//')"
%{ else ~}
# Fixed VM: Pre-defined secret name from Terraform
SECRET_NAME="${secret_name}"
%{ endif ~}
echo "Key Vault: $KEY_VAULT_NAME, Secret: $SECRET_NAME"

# Start zpa-connector service to generate the OAuth token in /etc/issue
systemctl start zpa-connector

# Authenticate to Azure using a Managed Identity. Fixed VMs use a
# system-assigned identity; orchestrated VM Scale Sets only support
# user-assigned identities, so the identity's client id is injected by Terraform.
%{ if is_vmss ~}
az login --identity --username "${managed_identity_client_id}" --allow-no-subscriptions > /var/log/oauth-token-registration.log 2>&1 || \
  echo "WARNING: az login --identity failed; check that the user-assigned identity is attached and granted Key Vault access"
%{ else ~}
az login --identity --allow-no-subscriptions > /var/log/oauth-token-registration.log 2>&1 || \
  echo "WARNING: az login --identity failed; check that a system-assigned identity and Key Vault access are configured"
%{ endif ~}

# Wait for OAuth token to be generated (retry up to 30 times, 10s each = 5 min)
MAX_RETRIES=30
RETRY_COUNT=0
OAUTH_TOKEN=""

while [ "$RETRY_COUNT" -lt "$MAX_RETRIES" ]; do
  OAUTH_TOKEN=$(cat /etc/issue 2>/dev/null | grep -Eo '[A-Z0-9]{5}-[A-Z0-9]{5}' | head -n 1)

  if [ -n "$OAUTH_TOKEN" ]; then
    echo "OAuth token retrieved: $OAUTH_TOKEN"
    break
  fi

  echo "Waiting for OAuth token to be generated (attempt $((RETRY_COUNT + 1))/$MAX_RETRIES)..."
  sleep 10
  RETRY_COUNT=$((RETRY_COUNT + 1))
done

# Store the OAuth token in Key Vault for Terraform to read back
if [ -n "$OAUTH_TOKEN" ]; then
  az keyvault secret set \
    --vault-name "$KEY_VAULT_NAME" \
    --name "$SECRET_NAME" \
    --value "$OAUTH_TOKEN" >> /var/log/oauth-token-registration.log 2>&1

  if [ $? -eq 0 ]; then
    echo "SUCCESS: OAuth token stored in Key Vault: $KEY_VAULT_NAME/$SECRET_NAME"
  else
    echo "ERROR: Failed to store OAuth token in Key Vault"
  fi
else
  echo "ERROR: Failed to retrieve OAuth token after $MAX_RETRIES attempts"
fi

# Now do yum update (takes a long time, but OAuth token already stored)
yum update -y
%{ endif ~}
