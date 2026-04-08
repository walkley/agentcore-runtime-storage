#!/bin/bash
set -euo pipefail

STACK_NAME="agentcore-s3files"
AGENT_NAME="s3files_agent"
REGION="us-west-2"

# ── 1. 销毁 Agent ──
AGENTCORE="uv run agentcore"

echo ">>> 销毁 agent..."
$AGENTCORE destroy --agent "$AGENT_NAME" --force 2>/dev/null || echo "agent 不存在或已销毁，跳过"

# ── 2. 清空 ECR 镜像（ECR 仓库非空时 CFN 无法删除）──
echo ">>> 清空 ECR 仓库..."
ECR_REPO_NAME="agentcore-s3files-agent"
IMAGE_IDS=$(aws ecr list-images --repository-name "$ECR_REPO_NAME" --region "$REGION" \
  --query 'imageIds[*]' --output json 2>/dev/null || echo "[]")

if [[ "$IMAGE_IDS" != "[]" && -n "$IMAGE_IDS" ]]; then
  aws ecr batch-delete-image --repository-name "$ECR_REPO_NAME" \
    --image-ids "$IMAGE_IDS" --region "$REGION" >/dev/null
  echo "ECR 镜像已清空"
else
  echo "ECR 仓库为空或不存在，跳过"
fi

# ── 3. 清空 S3 桶（非空时 CFN 无法删除）──
echo ">>> 清空 S3 桶..."
BUCKET_NAME=$(aws cloudformation describe-stacks --stack-name "$STACK_NAME" \
  --query "Stacks[0].Outputs[?OutputKey=='BucketName'].OutputValue" --output text --region "$REGION" 2>/dev/null || echo "")

if [[ -n "$BUCKET_NAME" && "$BUCKET_NAME" != "None" ]]; then
  aws s3 rm "s3://$BUCKET_NAME" --recursive --region "$REGION" 2>/dev/null || echo "桶为空或不存在，跳过"
  echo "S3 桶已清空"
fi

# ── 4. 删除 CloudFormation 栈 ──
echo ">>> 删除 CloudFormation 栈 $STACK_NAME..."
aws cloudformation delete-stack --stack-name "$STACK_NAME" --region "$REGION"
echo ">>> 等待栈删除完成..."
aws cloudformation wait stack-delete-complete --stack-name "$STACK_NAME" --region "$REGION"

echo ">>> 销毁完成。"
