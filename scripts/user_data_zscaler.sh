#!/bin/bash
################################################################################
# Zscaler App Connector User Data Script (Zscaler Marketplace Image - Azure)
# Supports both Fixed VMs and VM Scale Sets, and both onboarding methods:
#   - oauth            : retrieve OAuth2 user code from /etc/issue and publish it
#                        to an Azure Key Vault secret for Terraform to enroll.
#   - provisioning_key : write the ZPA provisioning key to the connector and let
#                        it self-enroll. No Key Vault interaction required.
#
# Token storage on Azure uses Key Vault + the VM's user-assigned Managed
# Identity (the Azure analog of AWS SSM Parameter Store + IAM instance profile).
# The Zscaler App Connector appliance is a hardened EL9 image that does NOT ship
# the Azure CLI, so this script installs it NON-INTERACTIVELY at boot (dnf repo,
# with the official install.py bootstrap as a fallback), then authenticates to
# Key Vault with the Managed Identity via `az login --identity`. No secrets are
# embedded in this script. NOTE: the CLI install pulls a large dependency tree
# and can take 3-5 minutes, so the Terraform-side poll window is sized for it.
#
# NOTE: This is a Terraform template file. Template variables are substituted by
# Terraform before script execution. Shellcheck warnings about undefined
# variables can be ignored.
################################################################################

%{ if onboarding_method == "provisioning_key" ~}
################################################################################
# Provisioning key onboarding
################################################################################
echo "=== ZPA Provisioning Key Registration ==="

# Stop the App Connector service which was auto-started at boot time
systemctl stop zpa-connector 2>/dev/null || true

# Write the provisioning key created via the ZPA provider to the connector.
# Keep the key between double quotes.
echo "${provisioning_key}" > /opt/zscaler/var/provision_key
chmod 644 /opt/zscaler/var/provision_key

# Start the App Connector service to enroll it in the ZPA cloud
systemctl start zpa-connector

echo "=== Provisioning Key Registration Complete, starting yum update ==="
nohup yum update -y > /var/log/yum-update.log 2>&1 &

%{ else ~}
################################################################################
# OAuth2 onboarding
################################################################################

# Key Vault and secret name are injected by Terraform. For VM Scale Sets the
# per-instance secret name is suffixed at runtime with the instance's unique
# Azure resource name so concurrent scale-out instances never collide.
KEY_VAULT_NAME="${key_vault_name}"
%{ if is_vmss ~}
# VMSS: derive a unique per-instance secret name from instance metadata. Azure
# Key Vault secret names allow only alphanumerics and dashes, so sanitize.
INSTANCE_NAME=$(curl -s -H "Metadata:true" "http://169.254.169.254/metadata/instance/compute/name?api-version=2021-02-01&format=text" 2>/dev/null)
SECRET_NAME="${secret_name_prefix}-$(echo "$INSTANCE_NAME" | tr -c 'a-zA-Z0-9' '-' | sed 's/-\+/-/g;s/^-//;s/-$//')"
%{ else ~}
# Fixed VM: pre-defined secret name from Terraform
SECRET_NAME="${secret_name}"
%{ endif ~}

# All bootstrap output is mirrored to a dedicated log so onboarding failures can
# be diagnosed over SSH (cloud-init also captures stdout in /var/log/cloud-init-output.log).
LOG=/var/log/oauth-token-registration.log
log() { echo "[$(date -u +%FT%TZ)] $*" | tee -a "$LOG"; }

# The user-assigned Managed Identity client id injected by Terraform. The
# connector authenticates to Key Vault as this identity, whose Key Vault Secrets
# Officer grant is created and propagated BEFORE this VM boots.
MANAGED_IDENTITY_CLIENT_ID="${managed_identity_client_id}"

log "=== ZPA OAuth Token Registration ==="
log "Key Vault: $KEY_VAULT_NAME, Secret: $SECRET_NAME, Identity: $MANAGED_IDENTITY_CLIENT_ID"

# Ensure zpa-connector service is running (generates OAuth token in /etc/issue)
systemctl start zpa-connector 2>/dev/null || true

################################################################################
# Install the Azure CLI (non-interactively).
#
# The hardened App Connector appliance does NOT ship the Azure CLI, and cloud-init
# runs with no TTY, a minimal PATH, and no interactive prompts available. Two
# install methods are attempted, in order:
#
#   1. Microsoft dnf/yum package repo (Microsoft's RECOMMENDED method for RHEL/EL).
#      Fully non-interactive, installs to /usr/bin/az, not coupled to the system
#      Python version.
#
#   2. Official install.py bootstrap (the `curl -L https://aka.ms/InstallAzureCli`
#      method). The aka.ms one-liner pipes the script through `bash` and reads its
#      prompts from /dev/tty, which DOES NOT EXIST under cloud-init -- this is why
#      a "manual" curl|bash works in an SSH session but fails at boot. We instead
#      download install.py and feed its four prompts on stdin so every prompt
#      takes its default (install dir ~/lib/azure-cli, exec dir ~/bin, do NOT
#      modify the shell profile). Running as root at boot, `az` lands at
#      /root/bin/az.
#
# After install we resolve `az` to an ABSOLUTE path (checking the package and
# bootstrap locations) and use that everywhere, so the rest of the script never
# depends on cloud-init's PATH.
################################################################################
install_via_dnf() {
  rpm --import https://packages.microsoft.com/keys/microsoft.asc >> "$LOG" 2>&1 || true
  cat > /etc/yum.repos.d/azure-cli.repo <<-'REPO'
[azure-cli]
name=Azure CLI
baseurl=https://packages.microsoft.com/yumrepos/azure-cli
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
REPO
  for attempt in $(seq 1 3); do
    if dnf install -y azure-cli >> "$LOG" 2>&1 || yum install -y azure-cli >> "$LOG" 2>&1; then
      log "azure-cli installed via dnf/yum repo (attempt $attempt)."
      return 0
    fi
    log "dnf/yum azure-cli install failed (attempt $attempt/3); retrying in 20s..."
    sleep 20
  done
  return 1
}

install_via_bootstrap() {
  # Native build dependencies the install.py needs to compile wheels on EL9.
  dnf install -y gcc libffi-devel openssl-devel python3-devel curl \
    >> "$LOG" 2>&1 || yum install -y gcc libffi-devel openssl-devel python3-devel curl >> "$LOG" 2>&1 || true

  local script_path=/tmp/azure_cli_install.py
  for attempt in $(seq 1 3); do
    if curl -fsSL https://azurecliprod.blob.core.windows.net/install.py -o "$script_path" >> "$LOG" 2>&1; then
      break
    fi
    log "Failed to download install.py (attempt $attempt/3); retrying in 15s..."
    sleep 15
  done
  [ -s "$script_path" ] || { log "install.py was not downloaded; bootstrap method unavailable."; return 1; }

  # Feed the four prompts on stdin so each takes its default:
  #   1) install dir  -> blank (~/lib/azure-cli)
  #   2) exec dir     -> blank (~/bin)
  #   3) modify profile to update PATH? -> n  (we resolve az by absolute path)
  #   4) (only reached if 3 == y) rc file path -> blank; sending an extra blank
  #      line is harmless if not consumed.
  local py
  py="$(command -v python3 || command -v python || echo python3)"
  if printf '\n\n\nn\n\n' | "$py" "$script_path" >> "$LOG" 2>&1; then
    log "azure-cli installed via install.py bootstrap."
    return 0
  fi
  log "install.py bootstrap install failed."
  return 1
}

resolve_az() {
  # Check PATH first, then the known package and bootstrap install locations.
  if command -v az >/dev/null 2>&1; then command -v az; return 0; fi
  for candidate in /usr/bin/az /root/bin/az "$HOME/bin/az" /usr/local/bin/az; do
    [ -x "$candidate" ] && { echo "$candidate"; return 0; }
  done
  # Last resort: search common install roots.
  find /usr /root /opt -maxdepth 4 -type f -name az 2>/dev/null | head -n 1
}

# Try the recommended package repo first; fall back to the bootstrap installer.
install_via_dnf || install_via_bootstrap || log "WARNING: both Azure CLI install methods reported failure; will still attempt to locate az."

AZ="$(resolve_az)"
if [ -z "$AZ" ] || ! "$AZ" version >> "$LOG" 2>&1; then
  log "ERROR: Azure CLI installation failed; cannot publish OAuth2 user code to Key Vault."
  log "       Inspect $LOG and /var/log/cloud-init-output.log, or switch onboarding_method to \"provisioning_key\"."
  AZ=""
else
  log "Azure CLI ready at: $AZ"
fi

# Authenticate to Azure using the user-assigned Managed Identity. User-assigned
# identities are not the implicit default, so the client id MUST be supplied to
# `az login --identity`. Retry to absorb the brief window after boot where the
# Instance Metadata Service has not yet surfaced the attached identity.
LOGIN_OK=0
if [ -n "$AZ" ]; then
  for attempt in $(seq 1 10); do
    if "$AZ" login --identity --username "$MANAGED_IDENTITY_CLIENT_ID" --allow-no-subscriptions >> "$LOG" 2>&1; then
      LOGIN_OK=1
      log "az login --identity succeeded (attempt $attempt)."
      break
    fi
    log "az login --identity failed (attempt $attempt/10); retrying in 15s..."
    sleep 15
  done
fi
if [ "$LOGIN_OK" -ne 1 ]; then
  log "WARNING: az login --identity never succeeded; check the user-assigned identity is attached and granted Key Vault access."
fi

# Wait for OAuth token to be generated (retry up to 30 times, 10s each = 5 min)
MAX_RETRIES=30
RETRY_COUNT=0
OAUTH_TOKEN=""

while [ "$RETRY_COUNT" -lt "$MAX_RETRIES" ]; do
  OAUTH_TOKEN=$(cat /etc/issue 2>/dev/null | grep -Eo '[A-Z0-9]{5}-[A-Z0-9]{5}' | head -n 1)

  if [ -n "$OAUTH_TOKEN" ]; then
    log "OAuth token retrieved from /etc/issue: $OAUTH_TOKEN"
    break
  fi

  log "Waiting for OAuth token to be generated (attempt $((RETRY_COUNT + 1))/$MAX_RETRIES)..."
  sleep 10
  RETRY_COUNT=$((RETRY_COUNT + 1))
done

# Store the OAuth token in Key Vault for Terraform to read back. Retry the write:
# even though the identity's role assignment is propagated before boot, Azure RBAC
# is eventually consistent and the data-plane can still briefly 403. A single
# best-effort write (the old behavior) is the main reason codes never appeared.
if [ -n "$OAUTH_TOKEN" ] && [ "$LOGIN_OK" -eq 1 ]; then
  WRITE_OK=0
  for attempt in $(seq 1 20); do
    if "$AZ" keyvault secret set \
      --vault-name "$KEY_VAULT_NAME" \
      --name "$SECRET_NAME" \
      --value "$OAUTH_TOKEN" >> "$LOG" 2>&1; then
      WRITE_OK=1
      log "SUCCESS: OAuth token stored in Key Vault: $KEY_VAULT_NAME/$SECRET_NAME (attempt $attempt)."
      break
    fi
    log "Key Vault write failed (attempt $attempt/20); likely RBAC propagation, retrying in 15s..."
    sleep 15
  done
  if [ "$WRITE_OK" -ne 1 ]; then
    log "ERROR: Failed to store OAuth token in Key Vault after 20 attempts. See $LOG for the az error output."
  fi
elif [ -z "$OAUTH_TOKEN" ]; then
  log "ERROR: Failed to retrieve OAuth token from /etc/issue after $MAX_RETRIES attempts."
else
  log "ERROR: OAuth token retrieved but Azure CLI login failed; cannot publish to Key Vault. See $LOG."
fi

log "=== OAuth Registration Complete, starting yum update ==="
nohup yum update -y > /var/log/yum-update.log 2>&1 &
%{ endif ~}
