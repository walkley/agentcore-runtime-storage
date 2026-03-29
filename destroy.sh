#!/bin/bash
set -euo pipefail

STACK_NAME="agentcore-efs"
AGENT_NAME="efs_agent"
REGION="us-west-2"

# ── 1. 销毁 Agent ──
AGENTCORE="uv run agentcore"

echo ">>> 销毁 agent..."
$AGENTCORE destroy --name "$AGENT_NAME" --yes 2>/dev/null || echo "agent 不存在或已销毁，跳过"

# ── 2. 清空 ECR 镜像（ECR 仓库非空时 CFN 无法删除）──
echo ">>> 清空 ECR 仓库..."
ECR_REPO_NAME="agentcore-efs-agent"
IMAGE_IDS=$(aws ecr list-images --repository-name "$ECR_REPO_NAME" --region "$REGION" \
  --query 'imageIds[*]' --output json 2>/dev/null || echo "[]")

if [[ "$IMAGE_IDS" != "[]" && -n "$IMAGE_IDS" ]]; then
  aws ecr batch-delete-image --repository-name "$ECR_REPO_NAME" \
    --image-ids "$IMAGE_IDS" --region "$REGION" >/dev/null
  echo "ECR 镜像已清空"
else
  echo "ECR 仓库为空或不存在，跳过"
fi

# ── 3. 删除 CloudFormation 栈 ──
echo ">>> 删除 CloudFormation 栈 $STACK_NAME..."
aws cloudformation delete-stack --stack-name "$STACK_NAME" --region "$REGION"
echo ">>> 等待栈删除完成..."
aws cloudformation wait stack-delete-complete --stack-name "$STACK_NAME" --region "$REGION"

echo ">>> 销毁完成。"
