#!/bin/bash
set -e

if [ -n "$S3FILES_FS_ID" ]; then
  MOUNT_POINT="${S3FILES_MOUNT_PATH:-/mnt/s3files}"
  mkdir -p "$MOUNT_POINT"
  mount -t s3files "$S3FILES_FS_ID:/" "$MOUNT_POINT" 2>&1 && \
    echo "S3 Files mounted at $MOUNT_POINT" || \
    echo "S3 Files mount failed"
fi

exec python3.11 /app/server.py
