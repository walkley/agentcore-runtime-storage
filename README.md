# AgentCore Runtime + EFS Auto-Mount

AgentCore Runtime 容器启动时自动挂载 EFS 文件系统。

## 项目结构

```
├── infra.yaml               # CloudFormation: EFS + SG + ECR
├── agent/
│   ├── Dockerfile           # Amazon Linux 2023 + EFS utils + Python 3.11
│   ├── entrypoint.sh        # 容器入口：挂载 EFS → 启动 server.py
│   └── server.py            # Agent 业务逻辑
├── deploy.sh                # 一键部署
├── destroy.sh               # 一键销毁
└── README.md
```

## 前提

- AWS CLI（已配置凭证）
- [uv](https://docs.astral.sh/uv/)（`brew install uv`）
- 有 NAT Gateway 的 VPC（私有子网需要出站访问）

## 部署

```bash
VPC_ID=vpc-xxx SUBNET_A=subnet-aaa SUBNET_B=subnet-bbb bash deploy.sh
```

## 测试

```bash
agentcore invoke '{"prompt": "hello"}'
```

## 销毁

```bash
bash destroy.sh
```

销毁顺序：Agent → 清空 ECR 镜像 → 删除 CloudFormation 栈（EFS / SG / ECR）。
