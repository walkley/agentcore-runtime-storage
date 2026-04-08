# AgentCore Runtime + S3 Files Auto-Mount

AgentCore Runtime 容器启动时自动挂载 [S3 Files](https://aws.amazon.com/s3/features/files/) 文件系统。数据存储在 S3，通过 S3 Files 以 NFS 文件系统方式访问，兼具 S3 的持久性和成本优势与文件系统的低延迟访问体验。

## 项目结构

```
├── infra.yaml               # CloudFormation: S3 Bucket + S3 Files + SG + IAM Policy + ECR
├── agent/
│   ├── Dockerfile           # Amazon Linux 2023 + amazon-efs-utils + Python 3.11
│   ├── entrypoint.sh        # 容器入口：挂载 S3 Files → 启动 server.py
│   └── server.py            # Agent 业务逻辑
├── deploy.sh                # 一键部署
├── destroy.sh               # 一键销毁
└── README.md
```

## 前提

- AWS CLI（已配置凭证）
- [uv](https://docs.astral.sh/uv/)（`brew install uv`）
- 有 NAT Gateway 的 VPC，需提供两个不同 AZ 的私有子网

> AgentCore Runtime 的 microVM 通过 VPC ENI 通信，私有子网必须有 NAT Gateway 才能访问 ECR 和 AgentCore 控制面。公有子网不可用。

## 部署

```bash
VPC_ID=vpc-xxx SUBNET_A=subnet-aaa SUBNET_B=subnet-bbb bash deploy.sh
```

部署流程：
1. CloudFormation 创建 S3 Bucket、S3 Files 文件系统、Mount Target、安全组、IAM Policy、ECR 仓库
2. `agentcore configure` 配置 Agent（VPC 模式）
3. `agentcore launch` 通过 CodeBuild 构建 ARM64 镜像并部署到 AgentCore Runtime
4. 将 S3 Files 客户端权限附加到 execution role

## 测试

```bash
uv run agentcore invoke '{"prompt": "hello"}'
```

## 销毁

```bash
bash destroy.sh
```

销毁顺序：Agent → 清空 ECR 镜像 → 清空 S3 桶 → 删除 CloudFormation 栈。
