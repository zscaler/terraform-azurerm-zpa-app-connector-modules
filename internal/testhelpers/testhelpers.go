// Package testhelpers holds plan-level assertions shared by the example
// Terratest suites. The test skeleton only asserts Terraform outputs, which do
// not expose image selection or Trusted Launch settings, so these helpers read
// the planned resource values instead.
package testhelpers

import (
	"path/filepath"
	"runtime"
	"testing"

	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/require"
)

// Resource addresses of the VMs created by the examples.
const (
	AppConnectorVM   = "module.ac_vm.azurerm_linux_virtual_machine.ac_vm[0]"
	AppConnectorVMSS = "module.ac_vmss.azurerm_orchestrated_virtual_machine_scale_set.ac_vmss[0]"
	BastionVM        = "module.bastion.azurerm_linux_virtual_machine.bastion_vm"
)

// Image identifies an Azure platform image.
type Image struct {
	Publisher string
	Offer     string
	SKU       string
	Version   string
}

// Images the examples are expected to deploy. ZscalerAppConnector carries no
// version because the pin is read back from the plan and checked against the
// Marketplace instead of being duplicated here.
var (
	ZscalerAppConnector = Image{Publisher: "zscaler", Offer: "zscaler-private-access", SKU: "zpa-con-azure"}
	RHEL9Gen2           = Image{Publisher: "RedHat", Offer: "RHEL", SKU: "9-lvm-gen2", Version: "latest"}
	UbuntuJammyGen2     = Image{Publisher: "Canonical", Offer: "0001-com-ubuntu-server-jammy", SKU: "22_04-lts-gen2", Version: "latest"}
)

// Plan runs init and plan for the options and returns the parsed plan.
func Plan(t *testing.T, opts *terraform.Options) *terraform.PlanStruct {
	t.Helper()
	opts.PlanFilePath = filepath.Join(t.TempDir(), "test.plan")
	return terraform.InitAndPlanAndShowWithStruct(t, opts)
}

// PlannedAttributes returns the planned attribute values of a resource.
func PlannedAttributes(t *testing.T, plan *terraform.PlanStruct, address string) map[string]interface{} {
	t.Helper()
	resource, ok := plan.ResourcePlannedValuesMap[address]
	require.Truef(t, ok, "resource %s is not in the plan", address)
	return resource.AttributeValues
}

// SourceImage returns the source_image_reference of a VM or scale set.
func SourceImage(t *testing.T, attrs map[string]interface{}) Image {
	t.Helper()
	refs, ok := attrs["source_image_reference"].([]interface{})
	require.True(t, ok && len(refs) == 1, "expected exactly one source_image_reference block")
	ref := refs[0].(map[string]interface{})
	return Image{
		Publisher: ref["publisher"].(string),
		Offer:     ref["offer"].(string),
		SKU:       ref["sku"].(string),
		Version:   ref["version"].(string),
	}
}

// AssertSourceImage checks publisher, offer and SKU, plus the version when
// want.Version is set, and returns the planned image.
func AssertSourceImage(t *testing.T, attrs map[string]interface{}, want Image) Image {
	t.Helper()
	got := SourceImage(t, attrs)
	require.Equal(t, want.Publisher, got.Publisher, "image publisher")
	require.Equal(t, want.Offer, got.Offer, "image offer")
	require.Equal(t, want.SKU, got.SKU, "image sku")
	if want.Version != "" {
		require.Equal(t, want.Version, got.Version, "image version")
	}
	return got
}

// AssertPlanBlocks checks how many Marketplace purchase plan blocks the
// resource has. Zscaler images need exactly one; plan-less images such as RHEL
// must have none or Azure rejects the deployment.
func AssertPlanBlocks(t *testing.T, attrs map[string]interface{}, want int) {
	t.Helper()
	blocks, _ := attrs["plan"].([]interface{})
	require.Len(t, blocks, want, "marketplace plan blocks")
}

// AssertTrustedLaunch checks secure_boot_enabled and vtpm_enabled.
func AssertTrustedLaunch(t *testing.T, attrs map[string]interface{}, want bool) {
	t.Helper()
	require.Equal(t, want, attrs["secure_boot_enabled"], "secure_boot_enabled")
	require.Equal(t, want, attrs["vtpm_enabled"], "vtpm_enabled")
}

// AssertBastionTrustedLaunch checks that the bastion host uses the Generation 2
// Ubuntu image with Trusted Launch enabled.
func AssertBastionTrustedLaunch(t *testing.T, plan *terraform.PlanStruct) {
	t.Helper()
	attrs := PlannedAttributes(t, plan, BastionVM)
	AssertSourceImage(t, attrs, UbuntuJammyGen2)
	AssertPlanBlocks(t, attrs, 0)
	AssertTrustedLaunch(t, attrs, true)
}

// AssertImagePublished fails when the image version is not published in the
// region. Azure deprecates old Zscaler image versions, which breaks a pinned
// default at apply time; this surfaces it at plan time instead.
func AssertImagePublished(t *testing.T, location string, image Image) {
	t.Helper()
	vars := map[string]interface{}{
		"location":  location,
		"publisher": image.Publisher,
		"offer":     image.Offer,
		"sku":       image.SKU,
	}
	if image.Version != "" && image.Version != "latest" {
		vars["image_version"] = image.Version
	}

	_, file, _, _ := runtime.Caller(0)
	opts := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: filepath.Join(filepath.Dir(file), "fixtures", "platform_image"),
		Vars:         vars,
		Logger:       logger.Default,
		Lock:         true,
		Upgrade:      true,
	})
	_, err := terraform.InitAndPlanE(t, opts)
	require.NoErrorf(t, err, "image %s:%s:%s:%s is not published in %s",
		image.Publisher, image.Offer, image.SKU, image.Version, location)
}
