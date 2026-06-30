package database_test

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
	vpcCIDR     = "10.1.0.0/16"
)

// Cost strategy:
// - public subnet: 1 AZ (1 NAT GW billed)
// - app subnet:    1 AZ (no NAT cost for data subnets)
// - data subnets:  3 AZs a/b/c (no NAT, isolated by default)
// Result: DB x2 (AZ a,b), etcd x3 (AZ a,b,c)

var (
	publicSubnets = map[string]string{
		"10.1.1.0/24": "ap-northeast-2a",
	}
	appSubnetCIDRs  = []string{"10.1.11.0/24"}
	dataSubnetCIDRs = []string{"10.1.21.0/24", "10.1.22.0/24", "10.1.23.0/24"}
	privateSubnets  = map[string]string{
		"10.1.11.0/24": "ap-northeast-2a",
		"10.1.21.0/24": "ap-northeast-2a",
		"10.1.22.0/24": "ap-northeast-2b",
		"10.1.23.0/24": "ap-northeast-2c",
	}
)

func TestDatabaseModule(t *testing.T) {
	t.Parallel()

	uniqueID := random.UniqueId()
	project := fmt.Sprintf("test-%s", uniqueID)
	env := "test"

	terraformOpts := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: fixturesDir,
		Vars: map[string]interface{}{
			"project":           project,
			"env":               env,
			"vpc_cidr":          vpcCIDR,
			"public_subnets":    publicSubnets,
			"private_subnets":   privateSubnets,
			"app_subnet_cidrs":  appSubnetCIDRs,
			"data_subnet_cidrs": dataSubnetCIDRs,
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

	// ── DB instance assertions ─────────────────────────────────────────────────

	t.Run("DB instances: count equals data_subnet_cidrs - 1", func(t *testing.T) {
		dbInstanceIDs := terraform.OutputMap(t, terraformOpts, "db_instance_ids")
		// 3 data subnets → DB uses first 2 (last is etcd-only quorum)
		assert.Len(t, dbInstanceIDs, len(dataSubnetCIDRs)-1)
	})

	t.Run("DB instances: correct tags", func(t *testing.T) {
		dbInstanceIDs := terraform.OutputMap(t, terraformOpts, "db_instance_ids")
		for key, instanceID := range dbInstanceIDs {
			tags := aws.GetTagsForEc2Instance(t, awsRegion, instanceID)
			assert.Equal(t, project, tags["Project"], "key=%s", key)
			assert.Equal(t, env, tags["Env"], "key=%s", key)
			assert.Equal(t, "db", tags["Role"], "key=%s", key)
			assert.Equal(t, fmt.Sprintf("%s-%s-db-%s", project, env, key), tags["Name"], "key=%s", key)
		}
	})

	t.Run("DB instances: private IPs are non-empty", func(t *testing.T) {
		dbPrivateIPs := terraform.OutputMap(t, terraformOpts, "db_private_ips")
		require.Len(t, dbPrivateIPs, len(dataSubnetCIDRs)-1)
		for key, ip := range dbPrivateIPs {
			assert.NotEmpty(t, ip, "key=%s", key)
		}
	})

	// ── etcd instance assertions ───────────────────────────────────────────────

	t.Run("etcd instances: count equals data_subnet_cidrs (all AZs for quorum)", func(t *testing.T) {
		etcdInstanceIDs := terraform.OutputMap(t, terraformOpts, "etcd_instance_ids")
		assert.Len(t, etcdInstanceIDs, len(dataSubnetCIDRs))
	})

	t.Run("etcd instances: correct tags", func(t *testing.T) {
		etcdInstanceIDs := terraform.OutputMap(t, terraformOpts, "etcd_instance_ids")
		for key, instanceID := range etcdInstanceIDs {
			tags := aws.GetTagsForEc2Instance(t, awsRegion, instanceID)
			assert.Equal(t, project, tags["Project"], "key=%s", key)
			assert.Equal(t, env, tags["Env"], "key=%s", key)
			assert.Equal(t, "etcd", tags["Role"], "key=%s", key)
			assert.Equal(t, fmt.Sprintf("%s-%s-etcd-%s", project, env, key), tags["Name"], "key=%s", key)
		}
	})

	// ── Security Group assertions ──────────────────────────────────────────────

	t.Run("DB and etcd SGs are created and distinct", func(t *testing.T) {
		dbSGID := terraform.Output(t, terraformOpts, "db_security_group_id")
		etcdSGID := terraform.Output(t, terraformOpts, "etcd_security_group_id")
		require.NotEmpty(t, dbSGID)
		require.NotEmpty(t, etcdSGID)
		assert.NotEqual(t, dbSGID, etcdSGID)
	})

	// ── Private subnet assertions ──────────────────────────────────────────────

	t.Run("private_subnet_ids contains all subnets keyed by CIDR", func(t *testing.T) {
		subnetMap := terraform.OutputMap(t, terraformOpts, "private_subnet_ids")
		assert.Len(t, subnetMap, len(privateSubnets))
		for cidr := range privateSubnets {
			_, ok := subnetMap[cidr]
			assert.True(t, ok, "expected CIDR %s in private_subnet_ids", cidr)
		}
	})

	t.Run("data subnets are a subset of private subnets", func(t *testing.T) {
		subnetMap := terraform.OutputMap(t, terraformOpts, "private_subnet_ids")
		for _, cidr := range dataSubnetCIDRs {
			_, ok := subnetMap[cidr]
			assert.True(t, ok, "data CIDR %s not found in private_subnet_ids", cidr)
		}
	})
}

func writeTfvars(t *testing.T, path, project, env string) {
	t.Helper()
	content := fmt.Sprintf(`project  = %q
env      = %q
vpc_cidr = %q
public_subnets  = { "10.1.1.0/24"  = "ap-northeast-2a" }
private_subnets = {
  "10.1.11.0/24" = "ap-northeast-2a"
  "10.1.21.0/24" = "ap-northeast-2a"
  "10.1.22.0/24" = "ap-northeast-2b"
  "10.1.23.0/24" = "ap-northeast-2c"
}
app_subnet_cidrs  = ["10.1.11.0/24"]
data_subnet_cidrs = ["10.1.21.0/24", "10.1.22.0/24", "10.1.23.0/24"]
`, project, env, vpcCIDR)
	err := os.WriteFile(path, []byte(content), 0600)
	require.NoError(t, err, "terraform.tfvars write failed")
}
