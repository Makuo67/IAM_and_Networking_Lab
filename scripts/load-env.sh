#!/usr/bin/env bash
# Usage: source scripts/load-env.sh
# Loads AWS credentials from .env into the current shell so Terraform can pick them up.
set -a
source "$(dirname "${BASH_SOURCE[0]}")/../.env"
set +a
