#!/bin/bash
set -e

if [ -n "$EFS_FS_ID" ]; then
  MOUNT_POINT="${EFS_MOUNT_PATH:-/mnt/efs}"
  mkdir -p "$MOUNT_POINT"
  mount -t efs -o tls "$EFS_FS_ID" "$MOUNT_POINT" 2>&1 && \
    echo "EFS mounted at $MOUNT_POINT (TLS)" || \
    echo "EFS mount failed"
  /usr/bin/amazon-efs-mount-watchdog &
fi

exec python3.11 /app/server.py
