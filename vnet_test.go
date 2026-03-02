package test

import (
	"testing"
	"time"

	"github.com/gruntwork-io/terratest/modules/azure"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

// TestVnetModuleDeployment provisions the VNET module with minimal config,
// asserts outputs are non-empty and the VNET exists in Azure, then destroys.
func TestVnetModuleDeployment(t *testing.T) {
	t.Parallel()

	terraformOptions := &terraform.Options{
		TerraformDir: "../modules/vnet",
		Vars: map[string]interface{}{
			"name":                "test-vnet-ci",
			"resource_group_name": "test-vnet-rg",
			"location":            "eastus",
			"address_space":       []string{"10.99.0.0/16"},
			"create_nsgs":         true,
			"subnets": map[string]interface{}{
				"default": map[string]interface{}{
					"address_prefixes": []string{"10.99.1.0/24"},
				},
			},
			"tags": map[string]string{
				"environment": "ci",
				"managed_by":  "terratest",
			},
		},
		// Retry on transient Azure API errors
		MaxRetries:         3,
		TimeBetweenRetries: 10 * time.Second,
	}

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

	// Assert outputs
	vnetID := terraform.Output(t, terraformOptions, "vnet_id")
	assert.NotEmpty(t, vnetID, "vnet_id output should not be empty")

	subnetIDs := terraform.OutputMap(t, terraformOptions, "subnet_ids")
	assert.Contains(t, subnetIDs, "default", "subnet_ids should contain 'default'")
	assert.NotEmpty(t, subnetIDs["default"])

	// Assert Azure resource actually exists
	exists := azure.VirtualNetworkExists(t, "test-vnet-ci", "test-vnet-rg", "")
	assert.True(t, exists, "Virtual network should exist in Azure")
}

// TestVnetModuleNoNSGs verifies the module works with NSG creation disabled.
func TestVnetModuleNoNSGs(t *testing.T) {
	t.Parallel()

	terraformOptions := &terraform.Options{
		TerraformDir: "../modules/vnet",
		Vars: map[string]interface{}{
			"name":                "test-vnet-nonsg",
			"resource_group_name": "test-vnet-nonsg-rg",
			"location":            "eastus",
			"address_space":       []string{"10.98.0.0/16"},
			"create_nsgs":         false,
			"subnets": map[string]interface{}{
				"default": map[string]interface{}{
					"address_prefixes": []string{"10.98.1.0/24"},
				},
			},
		},
	}

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

	nsgIDs := terraform.OutputMap(t, terraformOptions, "nsg_ids")
	assert.Empty(t, nsgIDs, "nsg_ids should be empty when create_nsgs is false")
}
