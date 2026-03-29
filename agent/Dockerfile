FROM --platform=linux/arm64 public.ecr.aws/amazonlinux/amazonlinux:2023

RUN dnf install -y --setopt=install_weak_deps=False amazon-efs-utils python3.11 python3.11-pip && \
    pip3.11 install --no-cache-dir bedrock-agentcore && \
    dnf clean all && rm -rf /var/cache/dnf

WORKDIR /app
COPY server.py entrypoint.sh ./
RUN chmod +x entrypoint.sh

EXPOSE 8080
ENTRYPOINT ["/app/entrypoint.sh"]
