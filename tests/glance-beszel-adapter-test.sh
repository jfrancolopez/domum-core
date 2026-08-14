#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IMAGE="${GO_TEST_IMAGE:-golang:1.24-alpine}"

docker run --rm \
  -v "$ROOT/compose/monitoring/glance-beszel-adapter:/src" \
  -w /src \
  "$IMAGE" \
  sh -c 'test -z "$(gofmt -l *.go)" && go test ./...'
