#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
CLI="${CIRCUREAD_BIN:-$SCRIPT_DIR/circuread}"

echo "fetch_edges.sh is deprecated; forwarding to: circuread fetch --all" >&2
exec "$CLI" fetch --all

