# ZPA App Connector Azure Modules Tests

This directory contains comprehensive tests for the ZPA App Connector Azure Terraform modules using gruntwork-io/terratest.

## Prerequisites

1. **Go 1.21+** installed
2. **Terraform** installed
3. **Azure credentials** configured as environment variables:
   - `ARM_CLIENT_ID`
   - `ARM_CLIENT_SECRET`
   - `ARM_SUBSCRIPTION_ID`
   - `ARM_TENANT_ID`
4. **ZPA API credentials** configured as environment variables:
   - `ZSCALER_CLIENT_ID`
   - `ZSCALER_CLIENT_SECRET`
   - `ZSCALER_VANITY_DOMAIN`
   - `ZPA_CUSTOMER_ID`
   - `ZSCALER_CLOUD`

## Test Structure

```
test/
├── internal/
│   └── zpatt/
│       └── zpatt.go           # ZPA-specific test utilities
├── terraform-zpa-app-connector-group/
│   ├── main_test.go
│   ├── main.tf
│   ├── variables.tf
│   └── test.tfvars
├── terraform-zpa-provisioning-key/
│   ├── main_test.go
│   ├── main.tf
│   ├── variables.tf
│   └── test.tfvars
├── terraform-zsac-network-azure/
│   ├── main_test.go
│   ├── main.tf
│   ├── variables.tf
│   └── test.tfvars
├── terraform-zsac-nsg-azure/
│   ├── main_test.go
│   ├── main.tf
│   ├── variables.tf
│   └── test.tfvars
└── README.md
```

## Running Tests

### Run all tests:
```bash
go test ./test/... -v
```

### Run specific module tests:
```bash
# Test Network module
cd test/terraform-zsac-network-azure
go test -v -run TestValidate -timeout 5m

# Test NSG module
cd test/terraform-zsac-nsg-azure
go test -v -run TestValidate -timeout 5m

# Test App Connector Group module
cd test/terraform-zpa-app-connector-group
go test -v -run TestValidate -timeout 5m

# Test Provisioning Key module
cd test/terraform-zpa-provisioning-key
go test -v -run TestValidate -timeout 5m
```

### Run specific test functions:
```bash
# Run only validation tests
go test ./test/terraform-zpa-app-connector-group -v -run TestValidate

# Run only plan tests
go test ./test/terraform-zpa-app-connector-group -v -run TestPlan

# Run only apply tests (creates real resources!)
go test ./test/terraform-zpa-app-connector-group -v -run TestApply

# Run idempotence tests
go test ./test/terraform-zpa-app-connector-group -v -run TestIdempotence
```

## Test Functions

Each module test includes the following test functions:

- **TestValidate**: Validates Terraform configuration syntax
- **TestPlan**: Runs `terraform plan` to check for errors
- **TestApply**: Deploys infrastructure and verifies outputs
- **TestIdempotence**: Verifies that subsequent applies don't make changes

## Environment Variables

Set the following environment variables before running tests:

### Azure Credentials

```bash
export ARM_CLIENT_ID="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"         # pragma: allowlist secret
export ARM_CLIENT_SECRET="your-azure-client-value"                  # pragma: allowlist secret
export ARM_SUBSCRIPTION_ID="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"   # pragma: allowlist secret
export ARM_TENANT_ID="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"         # pragma: allowlist secret
```

### Zscaler Credentials

```bash
# Replace with your actual Zscaler OneAPI credentials
export ZSCALER_CLIENT_ID="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"     # pragma: allowlist secret
export ZSCALER_CLIENT_SECRET="your-zscaler-client-value"            # pragma: allowlist secret
export ZSCALER_VANITY_DOMAIN="your-vanity-domain"                   # pragma: allowlist secret
export ZPA_CUSTOMER_ID="your-customer-id"                           # pragma: allowlist secret
export ZSCALER_CLOUD="PRODUCTION"  # e.g., "PRODUCTION", "BETA", "GOV"
```

## Test Configuration

Tests use realistic default values configured in `test.tfvars` files. You can customize these values by modifying the appropriate `test.tfvars` file or by adding variables to the `Vars` map in each `main_test.go` file.

## Cleanup

Tests automatically clean up resources after each test run using `defer terraform.Destroy()`.

## CI/CD Integration

These tests are integrated with GitHub Actions. See `.github/workflows/ci.yml` for the workflow configuration.

Required GitHub Secrets:
- `AZURE_CREDENTIALS` - Azure Service Principal credentials JSON
- `ARM_CLIENT_ID`, `ARM_CLIENT_SECRET`, `ARM_SUBSCRIPTION_ID`, `ARM_TENANT_ID`
- `ZSCALER_CLIENT_ID`, `ZSCALER_CLIENT_SECRET`, `ZSCALER_VANITY_DOMAIN`, `ZPA_CUSTOMER_ID`, `ZSCALER_CLOUD`
