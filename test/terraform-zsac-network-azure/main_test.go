package terraform_zsac_network_azure

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func CreateTerraformOptions(t *testing.T) *terraform.Options {
	// define options for Terraform
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: ".",
		VarFiles:     []string{"test.tfvars"},
		Logger:       logger.Default,
		Lock:         true,
		Upgrade:      true,
	})

	return terraformOptions
}

func TestValidate(t *testing.T) {
	terraformOptions := CreateTerraformOptions(t)
	// Initialize and then plan to ensure providers are downloaded
	terraform.Init(t, terraformOptions)
	terraform.Plan(t, terraformOptions)
}

func TestPlan(t *testing.T) {
	// define options for Terraform
	terraformOptions := CreateTerraformOptions(t)

	// Initialize and then plan test infrastructure
	terraform.Init(t, terraformOptions)
	terraform.Plan(t, terraformOptions)
}

func TestApply(t *testing.T) {
	// define options for Terraform
	terraformOptions := CreateTerraformOptions(t)

	// deploy test infrastructure
	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

	// verify outputs using validation outputs
	vnetIdValid := terraform.Output(t, terraformOptions, "vnet_id_valid")
	assert.Equal(t, "true", vnetIdValid, "VNet ID should be valid")

	acSubnetIdsValid := terraform.Output(t, terraformOptions, "ac_subnet_ids_valid")
	assert.Equal(t, "true", acSubnetIdsValid, "AC Subnet IDs should be valid")

	acSubnetCountCorrect := terraform.Output(t, terraformOptions, "ac_subnet_count_correct")
	assert.Equal(t, "true", acSubnetCountCorrect, "AC Subnet count should be correct")

	testVariablesSetCorrectly := terraform.Output(t, terraformOptions, "test_variables_set_correctly")
	assert.Equal(t, "true", testVariablesSetCorrectly, "Test variables should be set correctly")

	// Verify actual outputs are not empty
	vnetId := terraform.Output(t, terraformOptions, "virtual_network_id")
	assert.NotEmpty(t, vnetId, "VNet ID should not be empty")

	acSubnetIds := terraform.OutputList(t, terraformOptions, "ac_subnet_ids")
	assert.Len(t, acSubnetIds, 1, "Should create 1 AC subnet")
}

func TestIdempotence(t *testing.T) {
	// define options for Terraform
	terraformOptions := CreateTerraformOptions(t)

	// deploy test infrastructure
	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

	// verify idempotence - second apply should not make changes
	terraform.Apply(t, terraformOptions)
}
