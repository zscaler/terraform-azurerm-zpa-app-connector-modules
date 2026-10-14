package base

import (
	"log"
	"os"
	"testing"

	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/zscaler/terraform-azurerm-zpa-app-connector-modules/internal/testhelpers"
	"github.com/zscaler/terraform-modules-zscaler-tests-skeleton/pkg/testskeleton"
)

func CreateTerraformOptions(t *testing.T) *terraform.Options {
	varsInfo, err := testskeleton.GenerateTerraformVarsInfo("azure")
	if err != nil {
		log.Fatalf("Error generating terraform vars info: %v", err)
	}

	return terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: ".",
		VarFiles:     []string{"terraform.tfvars"},
		Vars: map[string]interface{}{
			"name_prefix":  varsInfo.NamePrefix,
			"arm_location": armLocation(),
		},
		Logger:               logger.Default,
		Lock:                 true,
		Upgrade:              true,
		SetVarsAfterVarFiles: true,
	})
}

func armLocation() string {
	if location := os.Getenv("ARM_LOCATION"); location != "" {
		return location
	}
	return "westus2"
}

func TestValidate(t *testing.T) {
	testskeleton.ValidateCode(t, nil)
}

func TestPlan(t *testing.T) {
	plan := testhelpers.Plan(t, CreateTerraformOptions(t))
	testhelpers.AssertBastionTrustedLaunch(t, plan)
	testhelpers.AssertImagePublished(t, armLocation(), testhelpers.UbuntuJammyGen2)
}

func TestApply(t *testing.T) {
	testskeleton.DeployInfraCheckOutputs(t, CreateTerraformOptions(t),
		[]testskeleton.AssertExpression{})
}

func TestIdempotence(t *testing.T) {
	testskeleton.DeployInfraCheckOutputsVerifyChanges(t, CreateTerraformOptions(t),
		[]testskeleton.AssertExpression{})
}
