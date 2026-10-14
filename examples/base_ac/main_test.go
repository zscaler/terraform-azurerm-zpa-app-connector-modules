package base_ac

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

// The default deployment uses the Zscaler Marketplace image, which is
// Generation 1 only, so Trusted Launch stays off.
func TestPlan(t *testing.T) {
	plan := testhelpers.Plan(t, CreateTerraformOptions(t))
	testhelpers.AssertBastionTrustedLaunch(t, plan)
	vm := testhelpers.PlannedAttributes(t, plan, testhelpers.AppConnectorVM)
	image := testhelpers.AssertSourceImage(t, vm, testhelpers.ZscalerAppConnector)
	testhelpers.AssertPlanBlocks(t, vm, 1)
	testhelpers.AssertTrustedLaunch(t, vm, false)
	testhelpers.AssertImagePublished(t, armLocation(), image)
}

// use_zscaler_image = false must swap the image itself, not only the bootstrap
// script, and enables Trusted Launch on the Generation 2 RHEL image.
func TestPlanRhelTrustedLaunch(t *testing.T) {
	opts := CreateTerraformOptions(t)
	opts.Vars["use_zscaler_image"] = false
	plan := testhelpers.Plan(t, opts)

	vm := testhelpers.PlannedAttributes(t, plan, testhelpers.AppConnectorVM)
	testhelpers.AssertSourceImage(t, vm, testhelpers.RHEL9Gen2)
	testhelpers.AssertPlanBlocks(t, vm, 0)
	testhelpers.AssertTrustedLaunch(t, vm, true)
	testhelpers.AssertImagePublished(t, armLocation(), testhelpers.RHEL9Gen2)
}

// An explicit trusted_launch_enabled = false overrides the RHEL default.
func TestPlanRhelTrustedLaunchDisabled(t *testing.T) {
	opts := CreateTerraformOptions(t)
	opts.Vars["use_zscaler_image"] = false
	opts.Vars["trusted_launch_enabled"] = false
	plan := testhelpers.Plan(t, opts)

	vm := testhelpers.PlannedAttributes(t, plan, testhelpers.AppConnectorVM)
	testhelpers.AssertSourceImage(t, vm, testhelpers.RHEL9Gen2)
	testhelpers.AssertTrustedLaunch(t, vm, false)
}

// Apply and idempotence deploy the RHEL Generation 2 image with Trusted Launch
// so the RHEL bootstrap and OAuth2 enrollment run for real; examples/ac covers
// the Zscaler Marketplace image. The idempotence plan also proves Azure kept
// Secure Boot and vTPM enabled, since any drift would show as a change.
func createRhelTerraformOptions(t *testing.T) *terraform.Options {
	opts := CreateTerraformOptions(t)
	opts.Vars["use_zscaler_image"] = false
	return opts
}

func TestApply(t *testing.T) {
	testskeleton.DeployInfraCheckOutputs(t, createRhelTerraformOptions(t),
		[]testskeleton.AssertExpression{})
}

func TestIdempotence(t *testing.T) {
	testskeleton.DeployInfraCheckOutputsVerifyChanges(t, createRhelTerraformOptions(t),
		[]testskeleton.AssertExpression{})
}
