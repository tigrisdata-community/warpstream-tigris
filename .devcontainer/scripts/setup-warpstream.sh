#!/usr/bin/env bash

set -euo pipefail

arch="$(uname -m)"
target_arch=""
case "$arch" in
  x86_64)
    target_arch="amd64"
    ;;
  aarch64)
    target_arch="arm64"
    ;;
  *)
    echo "Error: unsupported architecture '$arch'" >&2
    exit 1
    ;;
esac

cd /tmp
wget "https://warpstream-public-us-east-1.s3.amazonaws.com/warpstream_agent_releases/warpstream_agent_linux_${target_arch}_latest.tar.gz" -O warpstream.tar.gz
tar xzf warpstream.tar.gz
sudo mv "./warpstream_agent_linux_${target_arch}" /usr/local/bin/warpstream
