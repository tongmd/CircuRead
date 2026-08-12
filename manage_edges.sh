#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
CLI="${CIRCUREAD_BIN:-$SCRIPT_DIR/circuread}"

echo "manage_edges.sh is deprecated; forwarding to: circuread sync" >&2
exec "$CLI" sync

