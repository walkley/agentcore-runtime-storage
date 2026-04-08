#!/bin/bash
set -euo pipefail

STACK_NAME="agentcore-s3files"
AGENT_NAME="s3files_agent"
REGION="us-west-2"

# ── 检查必填参数 ──
if [[ -z "${VPC_ID:-}" || -z "${SUBNET_A:-}" || -z "${SUBNET_B:-}" ]]; then
  echo "用法: VPC_ID=vpc-xxx SUBNET_A=subnet-aaa SUBNET_B=subnet-bbb bash deploy.sh"
  exit 1
fi

# ── 1. 安装依赖到本地 .venv ──
uv sync
AGENTCORE="uv run agentcore"

# ── 2. 部署 CloudFormation（S3 Files + ECR）──
echo ">>> 部署基础设施..."
aws cloudformation deploy --template-file infra.yaml \
  --stack-name "$STACK_NAME" \
  --parameter-overrides \
    VpcId="$VPC_ID" \
    PrivateSubnetA="$SUBNET_A" \
    PrivateSubnetB="$SUBNET_B" \
  --capabilities CAPABILITY_NAMED_IAM \
  --region "$REGION"

# ── 3. 获取 CFN 输出 ──
get_output() {
  aws cloudformation describe-stacks --stack-name "$STACK_NAME" \
    --query "Stacks[0].Outputs[?OutputKey=='$1'].OutputValue" --output text --region "$REGION"
}

S3FILES_FS_ID=$(get_output FileSystemId)
SG_ID=$(get_output SecurityGroupId)
SUBNETS=$(get_output Subnets)
ECR_REPO=$(get_output EcrRepositoryUri)
S3FILES_POLICY_ARN=$(get_output S3FilesClientPolicyArn)

echo "S3Files=$S3FILES_FS_ID  SG=$SG_ID  ECR=$ECR_REPO"

# ── 4. 配置 Agent ──
echo ">>> 配置 agent..."
$AGENTCORE configure -c \
  -e agent/entrypoint.sh \
  -n "$AGENT_NAME" \
  -dt container \
  -dm \
  --ecr "$ECR_REPO" \
  --vpc --subnets "$SUBNETS" --security-groups "$SG_ID" \
  -ni

# ── 5. 部署（remote build）──
# CodeBuild 在项目根目录执行 docker build，需要 Dockerfile 在根目录
cp agent/Dockerfile Dockerfile
trap 'rm -f Dockerfile' EXIT

echo ">>> 部署 agent..."
$AGENTCORE launch --env S3FILES_FS_ID="$S3FILES_FS_ID" --env AWS_REGION="$REGION"

# ── 6. 附加 S3 Files 挂载权限到 execution role ──
echo ">>> 附加 S3 Files 权限..."
EXEC_ROLE_NAME=$(grep 'execution_role:' .bedrock_agentcore.yaml | head -1 | awk -F'/' '{print $NF}')
aws iam attach-role-policy --role-name "$EXEC_ROLE_NAME" --policy-arn "$S3FILES_POLICY_ARN"

echo ">>> 完成。测试: uv run agentcore invoke '{\"prompt\": \"hello\"}'"
