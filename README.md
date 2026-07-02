![GitHub release (latest by date)](https://img.shields.io/github/v/release/zscaler/terraform-azurerm-zpa-app-connector-modules?style=flat-square)
![GitHub](https://img.shields.io/github/license/zscaler/terraform-azurerm-zpa-app-connector-modules?style=flat-square)
![GitHub pull requests](https://img.shields.io/github/issues-pr/zscaler/terraform-azurerm-zpa-app-connector-modules?style=flat-square)
![Terraform registry downloads total](https://img.shields.io/badge/dynamic/json?color=green&label=downloads%20total&query=data.attributes.total&url=https%3A%2F%2Fregistry.terraform.io%2Fv2%2Fmodules%2Fzscaler%2Fzpa-app-connector-modules%2Fazurerm%2Fdownloads%2Fsummary&style=flat-square)
![Terraform registry download month](https://img.shields.io/badge/dynamic/json?color=green&label=downloads%20this%20month&query=data.attributes.month&url=https%3A%2F%2Fregistry.terraform.io%2Fv2%2Fmodules%2Fzscaler%2Fzpa-app-connector-modules%2Fazurerm%2Fdownloads%2Fsummary&style=flat-square)
[![Zscaler Community](https://img.shields.io/badge/zscaler-community-blue)](https://community.zscaler.com/)

# Zscaler App Connector Azure Terraform Modules

## Support Disclaimer

-> **Disclaimer:** Please refer to our [General Support Statement](docs/guides/support.md) before proceeding with the use of this provider.

## Description
This repository contains various modules and deployment configurations that can be used to deploy Zscaler App Connector appliances to securely connect to workloads within Microsoft Azure via the Zscaler Zero Trust Exchange. The examples directory contains complete automation scripts for both greenfield/POV and brownfield/production use.

These deployment templates are intended to be fully functional and self service for both greenfield/pov as well as production use. All modules may also be utilized as design recommendations based on Zscaler's Official [Zero Trust Access to Private Apps in Azure with ZPA](https://help.zscaler.com/downloads/zpa/reference-architecture/zero-trust-access-private-apps-microsoft-azure-zscaler-private-access/Zero-Trust-Access-to-Private-Apps-in-Azure-with-Zscaler-Private-Access.pdf).

~> **IMPORTANT** As of version 1.1.0 of this module, all App Connectors are deployed using the new [Red Hat Enterprise Linux 9](https://help.zscaler.com/zpa/app-connector-red-hat-enterprise-linux-9-migration)

## Prerequisites

Our Deployment scripts are leveraging Terraform v1.1.9 that includes full binary and provider support for MacOS M1 chips, but any Terraform version 0.13.7 should be generally supported.

- provider registry.terraform.io/hashicorp/azurerm v4.56.x
- provider registry.terraform.io/hashicorp/random v3.6.x
- provider registry.terraform.io/hashicorp/local v2.5.x
- provider registry.terraform.io/hashicorp/null v3.2.x
- provider registry.terraform.io/providers/hashicorp/tls v4.0.x
- provider registry.terraform.io/providers/zscaler/zpa v4.x

### Azure Requirements
1. Azure Subscription Id
[link to Azure subscriptions](https://portal.azure.com/#blade/Microsoft_Azure_Billing/SubscriptionsBlade)
2. Have/Create a Service Principal. [See](https://docs.microsoft.com/en-us/azure/active-directory/develop/howto-create-service-principal-portal). Then Collect:
   1. Application (client) ID
   2. Directory (tenant) ID
   3. Client Secret Value
3. Azure Region (e.g. westus2) where App Connector resources are to be deployed

### Zscaler requirements
This module leverages the Zscaler Private Access [ZPA Terraform Provider](https://registry.terraform.io/providers/zscaler/zpa/latest/docs) for the automated onboarding process. Before proceeding make sure you have the following pre-requistes ready.

## Legacy ZPA API Authentication Framework

1. A valid Zscaler Private Access subscription and portal access
2. Zscaler ZPA API Keys. Details on how to find and generate ZPA API keys can be located [here](https://registry.terraform.io/providers/zscaler/zpa/latest/docs#legacy-api-framework)
- `zpa_client_id`
- `zpa_client_secret`
- `zpa_customer_id`
- `zpa_cloud` - This authentication parameter is optional and only required if authenticating to a non-production cloud i.e `BETA`, `GOV`, `GOVUS`, `ZPATWO`
- `use_legacy_client` - This parameter MUST be set to `true` if your tenant is NOT migrated to Zidentity.

```hcl
provider "zpa" {
  zpa_client_id            = "zpa_client_id" # pragma: allowlist secret
  zpa_client_secret        = "zpa_client_secret" # pragma: allowlist secret
  zpa_customer_id          = "zpa_client_secret" # pragma: allowlist secret
  zpa_cloud                = "zpa_cloud" # pragma: allowlist secret
  use_legacy_client        = "true" # pragma: allowlist secret
}
```

3. (Optional) An existing App Connector Group and Provisioning Key. Otherwise, you can follow the prompts in the examples terraform.tfvars to create a new Connector Group and Provisioning Key

See: [Zscaler App Connector Azure Deployment Guide](https://help.zscaler.com/zpa/connector-deployment-guide-microsoft-azure) for additional prerequisite provisioning steps.

## ZPA OneAPI Authentication Framework (OneAPI)

1. A valid Zscaler Private Access subscription and portal access
2. Zscaler tenant MUST be migrated to Zidentity platform.
2. Details on how to authenticate to ZPA via Zidentity/OneAPI are located here [here](https://registry.terraform.io/providers/zscaler/zpa/latest/docs#authentication---oneapi-new-framework)
- `client_id`
- `client_secret`
- `zpa_customer_id`
- `vanity_domain`
- `zscaler_cloud` - This authentication parameter is optional and only required if authenticating to a non-production cloud i.e `beta`

```hcl
provider "zpa" {
  client_id = "client_id" # pragma: allowlist secret
  client_secret = "client_secret" # pragma: allowlist secret
  zpa_customer_id = "client_secret" # pragma: allowlist secret
  vanity_domain = "vanity_domain" # pragma: allowlist secret
  zscaler_cloud = "zscaler_cloud" # pragma: allowlist secret
}
```

-> **Attention Government customers.** OneAPI and Zidentity now support the government (FedRAMP) clouds. These are FedRAMP-isolated environments served by a dedicated Zidentity identity provider and API gateway. To authenticate, set the `zscaler_cloud` attribute (or `ZSCALER_CLOUD` environment variable) to one of the supported government values `gov` or `govus`:

| Argument        | Description                                                     | Environment Variable    |
|-----------------|-----------------------------------------------------------------|-------------------------|
| `vanity_domain` | _(String)_ Refers to the domain name used by your organization  | `ZSCALER_VANITY_DOMAIN` |
| `zscaler_cloud` | _(String)_ Supported Zidentity Gov Cloud `gov` or `govus`       | `ZSCALER_CLOUD`         |

**NOTE:** The FedRAMP cloud is only supported when using a compatible provider version. Ensure you are on a ZPA provider version that supports the unified `gov` / `govus` cloud values.

For example, authenticating to the GOV environment:

```sh
export ZSCALER_VANITY_DOMAIN="acme"
export ZSCALER_CLOUD="gov"
```

3. (Optional) An existing App Connector Group and Provisioning Key. Otherwise, you can follow the prompts in the examples terraform.tfvars to create a new Connector Group and Provisioning Key

See: [Zscaler App Connector Azure Deployment Guide](https://help.zscaler.com/zpa/connector-deployment-guide-microsoft-azure) for additional prerequisite provisioning steps.


## App Connector Onboarding Methods

This module supports **both** App Connector onboarding methods, selectable per deployment via the `onboarding_method` variable in your `terraform.tfvars`:

| `onboarding_method` | Description |
|---------------------|-------------|
| `oauth` _(default)_ | Enrolls App Connectors using **OAuth2 user codes**. Each connector reads its user code from `/etc/issue` at boot, publishes it to an Azure Key Vault secret via the VM's user-assigned Managed Identity, and Terraform reads it back to create the App Connector Group. This is the modern, more secure enrollment flow. |
| `provisioning_key`  | Enrolls App Connectors using the traditional **provisioning key**. The key is generated via the `zpa_provisioning_key` resource (or supplied via `byo_provisioning_key` / `byo_provisioning_key_name`) and baked into the VM `user_data`; the connector self-enrolls at boot. No Key Vault interaction is required. |

Both methods are supported and can be used interchangeably. The default is `oauth`.

-> **Recommended:** If your Zscaler tenant has been migrated to support the OAuth2 onboarding method, that should be your **preferred** method as Zscaler is encouraging customers to move away from the provisioning key approach. If your tenant has not yet been migrated, use `onboarding_method = "provisioning_key"`.

Example `terraform.tfvars` snippets:

```hcl
# Default: OAuth2 user code onboarding (recommended for migrated tenants)
onboarding_method = "oauth"
```

```hcl
# Legacy provisioning key onboarding
onboarding_method = "provisioning_key"

# Optionally bring your own existing provisioning key instead of creating one
# byo_provisioning_key      = true
# byo_provisioning_key_name = "my-existing-key"
```

## How to deploy
Provisioning templates are available for customer use/reference to successfully deploy fully operational App Connector appliances once the prerequisites have been completed. Please follow the instructions located in [examples](examples/README.md).

## Format

This repository follows the [Hashicorp Standard Modules Structure](https://www.terraform.io/registry/modules/publish):

* `modules` - All module resources utilized by and customized specifically for ZPA App Connector deployments. The intent is these modules are resusable and functional for any deployment type referencing for both production or lab/testing purposes.
* `examples` - Zscaler provides fully functional deployment templates utilizing a combination of some or all of the modules published. These can utilized in there entirety or as reference templates for more advanced customers or custom deployments. For novice Terraform users, we also provide a bash script (zsec) that can be run from any Linux/Mac OS or CSP Cloud Shell that walks through all provisioning requirements as well as downloading/running an isolated teraform process. This allows ZPA App Connector deployments from any supported client without having to even have Terraform installed or know how the language/syntax for running it.

## Versioning

These modules follow recommended release tagging in [Semantic Versioning](http://semver.org/). You can find each new release,
along with the changelog, on the GitHub [Releases](https://github.com/zscaler/terraform-azurerm-zpa-app-connector-modules/releases) page.

# License and Copyright

Copyright (c) 2022 Zscaler, Inc.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
