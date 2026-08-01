#!/usr/bin/env bash
# Regenerate the C++ name constants consumed by Zeal from this registry.
#   ./generate.sh [output-dir]     (defaults to ../NewZeal/Zeal)
set -euo pipefail
OUT="${1:-$(cd "$(dirname "$0")/.." && pwd)/NewZeal/Zeal}"
WEAVER="${WEAVER:-weaver}"
"$WEAVER" registry check -r model --future
"$WEAVER" registry generate -r model --templates templates cpp "$OUT"
echo "wrote $OUT/everquest_semconv.h"
