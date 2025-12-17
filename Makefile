.PHONY: all help test-validate test-plan test-apply test-all clean deps fmt lint

# Default target
all:
	@echo "Run [make help] for usage details."

help:
	@echo "Zscaler App Connector Azure Terraform Module Test Suite"
	@echo ""
	@echo "Usage:"
	@echo "  make deps              - Download Go dependencies"
	@echo "  make fmt               - Format Go test files"
	@echo "  make lint              - Run Go linter on test files"
	@echo "  make test-validate     - Run terraform validate tests on all modules"
	@echo "  make test-plan         - Run terraform plan tests (requires Azure credentials)"
	@echo "  make test-apply        - Run terraform apply tests (requires Azure credentials)"
	@echo "  make test-all          - Run all tests"
	@echo "  make clean             - Clean up test artifacts"
	@echo ""
	@echo "Module-specific targets:"
	@echo "  make test-network      - Test terraform-zsac-network-azure module"
	@echo "  make test-nsg          - Test terraform-zsac-nsg-azure module"
	@echo "  make test-acgroup      - Test terraform-zpa-app-connector-group module"
	@echo "  make test-provkey      - Test terraform-zpa-provisioning-key module"
	@echo ""
	@echo "Environment Variables:"
	@echo "  ARM_CLIENT_ID            - Azure Service Principal Client ID"
	@echo "  ARM_CLIENT_SECRET        - Azure Service Principal Client Secret"
	@echo "  ARM_SUBSCRIPTION_ID      - Azure Subscription ID"
	@echo "  ARM_TENANT_ID            - Azure Tenant ID"
	@echo "  ZSCALER_CLIENT_ID        - Zscaler Client ID (OneAPI)"
	@echo "  ZSCALER_CLIENT_SECRET    - Zscaler Client Secret (OneAPI)"
	@echo "  ZSCALER_VANITY_DOMAIN    - Zscaler Vanity Domain"
	@echo "  ZPA_CUSTOMER_ID          - Zscaler ZPA Customer ID"
	@echo "  ZSCALER_CLOUD            - Zscaler Cloud (e.g., PRODUCTION)"
	@echo ""

# Download dependencies
deps:
	@echo "Downloading Go dependencies..."
	go mod download
	go mod tidy

# Format test files
fmt:
	@echo "Formatting Go files..."
	go fmt ./...

# Run linter
lint:
	@echo "Running Go linter..."
	@if command -v golangci-lint >/dev/null 2>&1; then \
		golangci-lint run ./...; \
	else \
		echo "golangci-lint not installed, skipping..."; \
	fi

# Validate all modules (no cloud credentials required)
test-validate: deps
	@echo "Running validation tests on all modules..."
	@echo "::group::Testing terraform-zsac-network-azure"
	cd test/terraform-zsac-network-azure && go test -v -run TestValidate -timeout 10m
	@echo "::endgroup::"
	@echo "::group::Testing terraform-zsac-nsg-azure"
	cd test/terraform-zsac-nsg-azure && go test -v -run TestValidate -timeout 10m
	@echo "::endgroup::"
	@echo "::group::Testing terraform-zpa-app-connector-group"
	cd test/terraform-zpa-app-connector-group && go test -v -run TestValidate -timeout 10m
	@echo "::endgroup::"
	@echo "::group::Testing terraform-zpa-provisioning-key"
	cd test/terraform-zpa-provisioning-key && go test -v -run TestValidate -timeout 10m
	@echo "::endgroup::"

# Individual module tests
test-network: deps
	@echo "Testing terraform-zsac-network-azure module..."
	cd test/terraform-zsac-network-azure && go test -v -timeout 30m

test-nsg: deps
	@echo "Testing terraform-zsac-nsg-azure module..."
	cd test/terraform-zsac-nsg-azure && go test -v -timeout 30m

test-acgroup: deps
	@echo "Testing terraform-zpa-app-connector-group module..."
	cd test/terraform-zpa-app-connector-group && go test -v -timeout 30m

test-provkey: deps
	@echo "Testing terraform-zpa-provisioning-key module..."
	cd test/terraform-zpa-provisioning-key && go test -v -timeout 30m

# Plan tests (require credentials)
test-plan: deps
	@echo "Running plan tests..."
	cd test/terraform-zsac-network-azure && go test -v -run TestPlan -timeout 30m
	cd test/terraform-zsac-nsg-azure && go test -v -run TestPlan -timeout 30m
	cd test/terraform-zpa-app-connector-group && go test -v -run TestPlan -timeout 30m

# Apply tests (require credentials, creates real resources)
test-apply: deps
	@echo "WARNING: This will create real Azure resources and incur costs!"
	@echo "Running apply tests..."
	cd test/terraform-zsac-network-azure && go test -v -run TestApply -timeout 60m
	cd test/terraform-zsac-nsg-azure && go test -v -run TestApply -timeout 60m
	cd test/terraform-zpa-app-connector-group && go test -v -run TestApply -timeout 60m

# Run all tests
test-all: test-validate test-plan

# Clean up test artifacts
clean:
	@echo "Cleaning up test artifacts..."
	find . -name "*.tfstate*" -type f -delete
	find . -name ".terraform" -type d -exec rm -rf {} + 2>/dev/null || true
	find . -name ".terraform.lock.hcl" -type f -delete
	find . -name "terraform.tfplan" -type f -delete
	find . -name "tmp.plan" -type f -delete
	go clean -testcache
