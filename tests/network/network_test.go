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
			// 비용 절감: AZ 1개만 사용
			"public_subnets": map[string]string{
				"10.0.1.0/24": "ap-northeast-2a",
			},
			"private_subnets": map[string]string{
				"10.0.11.0/24": "ap-northeast-2a",
			},
		},
		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": awsRegion,
		},
	})

	// 강제 종료 등으로 defer가 실행되지 않을 때를 대비해 변수값을 파일로 보존.
	// 복구 시: cd tests/network/fixtures && terraform destroy
	writeTfvars(t, fixturesDir+"/terraform.tfvars", project, env)
	defer os.Remove(fixturesDir + "/terraform.tfvars")

	// destroy 전용 옵션: NAT GW 삭제(3~5분)를 고려해 타임아웃 연장 + 순차 삭제
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
			t.Errorf("terraform destroy 실패 — AWS 콘솔에서 수동 정리 필요 (project=%s): %v", project, err)
		}
	}()

	terraform.InitAndApply(t, terraformOpts)

	t.Run("VPC가 올바른 CIDR로 생성됐는지", func(t *testing.T) {
		vpcID := terraform.Output(t, terraformOpts, "vpc_id")
		require.NotEmpty(t, vpcID)

		actualCIDR := terraform.Output(t, terraformOpts, "vpc_cidr")
		assert.Equal(t, vpcCIDR, actualCIDR)
	})

	t.Run("Public 서브넷이 1개 생성됐는지", func(t *testing.T) {
		publicSubnetIDs := terraform.OutputList(t, terraformOpts, "public_subnet_ids")
		assert.Len(t, publicSubnetIDs, 1)
	})

	t.Run("Private 서브넷이 1개 생성됐는지", func(t *testing.T) {
		privateSubnetIDs := terraform.OutputList(t, terraformOpts, "private_subnet_ids")
		assert.Len(t, privateSubnetIDs, 1)
	})

	t.Run("VPC에 태그가 올바르게 붙었는지", func(t *testing.T) {
		vpcID := terraform.Output(t, terraformOpts, "vpc_id")
		tags := aws.GetTagsForVpc(t, vpcID, awsRegion)

		assert.Equal(t, project, tags["Project"])
		assert.Equal(t, env, tags["Env"])
		assert.Equal(t, fmt.Sprintf("%s-%s-vpc", project, env), tags["Name"])
	})

	t.Run("Public 서브넷이 실제로 인터넷 경로를 가지는지 (IGW 연결 간접 검증)", func(t *testing.T) {
		publicSubnetIDs := terraform.OutputList(t, terraformOpts, "public_subnet_ids")
		require.NotEmpty(t, publicSubnetIDs)
		assert.True(t, aws.IsPublicSubnet(t, publicSubnetIDs[0], awsRegion))
	})
}

func writeTfvars(t *testing.T, path, project, env string) {
	t.Helper()
	content := fmt.Sprintf(`project = %q
env     = %q
vpc_cidr = %q
aws_region = %q
public_subnets  = { "10.0.1.0/24" = "ap-northeast-2a" }
private_subnets = { "10.0.11.0/24" = "ap-northeast-2a" }
`, project, env, vpcCIDR, awsRegion)
	err := os.WriteFile(path, []byte(content), 0600)
	require.NoError(t, err, "terraform.tfvars 생성 실패")
}
