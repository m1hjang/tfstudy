package network_test

import (
	"fmt"
	"os"
	"testing"
	"time"

	"github.com/gruntwork-io/terratest/modules/aws"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

const (
	awsRegion   = "ap-northeast-2"
	fixturesDir = "./fixtures"
	vpcCIDR     = "10.0.0.0/16"
)

func TestNetworkModule(t *testing.T) {
	t.Parallel()

	uniqueID := random.UniqueId()
	project := fmt.Sprintf("test-%s", uniqueID)
	env := "test"

	terraformOpts := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: fixturesDir,
		Vars: map[string]interface{}{
			"project":  project,
			"env":      env,
			"vpc_cidr": vpcCIDR,
			"public_subnets": map[string]string{
				"10.0.1.0/24": "ap-northeast-2a",
			},
			// Two private subnets in different AZs to verify generic handling.
			"private_subnets": map[string]string{
				"10.0.11.0/24": "ap-northeast-2a",
				"10.0.21.0/24": "ap-northeast-2a",
			},
		},
		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": awsRegion,
		},
	})

	writeTfvars(t, fixturesDir+"/terraform.tfvars", project, env)
	defer os.Remove(fixturesDir + "/terraform.tfvars")

	destroyOpts := &terraform.Options{
		TerraformDir:       fixturesDir,
		Vars:               terraformOpts.Vars,
		EnvVars:            terraformOpts.EnvVars,
		MaxRetries:         3,
		TimeBetweenRetries: 30 * time.Second,
		Parallelism:        1,
	}
	defer func() {
		if _, err := terraform.DestroyE(t, destroyOpts); err != nil {
			t.Errorf("terraform destroy failed — manual cleanup needed (project=%s): %v", project, err)
		}
	}()

	terraform.InitAndApply(t, terraformOpts)

	t.Run("VPC has correct CIDR", func(t *testing.T) {
		vpcID := terraform.Output(t, terraformOpts, "vpc_id")
		require.NotEmpty(t, vpcID)

		actualCIDR := terraform.Output(t, terraformOpts, "vpc_cidr")
		assert.Equal(t, vpcCIDR, actualCIDR)
	})

	t.Run("Public subnet count is 1", func(t *testing.T) {
		publicSubnetIDs := terraform.OutputList(t, terraformOpts, "public_subnet_ids")
		assert.Len(t, publicSubnetIDs, 1)
	})

	t.Run("Private subnet count matches input", func(t *testing.T) {
		privateSubnetIDs := terraform.OutputMap(t, terraformOpts, "private_subnet_ids")
		assert.Len(t, privateSubnetIDs, 2)
	})

	t.Run("Private subnet IDs keyed by CIDR", func(t *testing.T) {
		privateSubnetIDs := terraform.OutputMap(t, terraformOpts, "private_subnet_ids")
		_, ok1 := privateSubnetIDs["10.0.11.0/24"]
		_, ok2 := privateSubnetIDs["10.0.21.0/24"]
		assert.True(t, ok1, "expected key 10.0.11.0/24 in private_subnet_ids")
		assert.True(t, ok2, "expected key 10.0.21.0/24 in private_subnet_ids")
	})

	t.Run("NAT route table exists per public AZ", func(t *testing.T) {
		natRTIDs := terraform.OutputMap(t, terraformOpts, "nat_route_table_ids")
		assert.Len(t, natRTIDs, 1)
		_, ok := natRTIDs["ap-northeast-2a"]
		assert.True(t, ok, "expected AZ ap-northeast-2a in nat_route_table_ids")
	})

	t.Run("VPC has correct tags", func(t *testing.T) {
		vpcID := terraform.Output(t, terraformOpts, "vpc_id")
		tags := aws.GetTagsForVpc(t, vpcID, awsRegion)

		assert.Equal(t, project, tags["Project"])
		assert.Equal(t, env, tags["Env"])
		assert.Equal(t, fmt.Sprintf("%s-%s-vpc", project, env), tags["Name"])
	})

	t.Run("Public subnet has internet route (IGW)", func(t *testing.T) {
		publicSubnetIDs := terraform.OutputList(t, terraformOpts, "public_subnet_ids")
		require.NotEmpty(t, publicSubnetIDs)
		assert.True(t, aws.IsPublicSubnet(t, publicSubnetIDs[0], awsRegion))
	})
}

func writeTfvars(t *testing.T, path, project, env string) {
	t.Helper()
	content := fmt.Sprintf(`project    = %q
env        = %q
vpc_cidr   = %q
aws_region = %q
public_subnets  = { "10.0.1.0/24"  = "ap-northeast-2a" }
private_subnets = {
  "10.0.11.0/24" = "ap-northeast-2a"
  "10.0.21.0/24" = "ap-northeast-2a"
}
`, project, env, vpcCIDR, awsRegion)
	err := os.WriteFile(path, []byte(content), 0600)
	require.NoError(t, err, "terraform.tfvars write failed")
}
