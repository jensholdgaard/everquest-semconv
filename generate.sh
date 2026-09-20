#!/usr/bin/env bash
# Regenerate the name constants consumers compile against, from this registry.
#   ./generate.sh [output-dir]          C++ header for Zeal (default ../NewZeal/Zeal)
#   ./generate.sh rust <output-dir>     Rust module for eqmacemu (src/everquest_semconv.rs)
set -euo pipefail
WEAVER="${WEAVER:-weaver}"
"$WEAVER" registry check -r model --future
if [ "${1:-}" = "rust" ]; then
  OUT="${2:?output dir for the Rust module}"
  "$WEAVER" registry generate -r model --templates templates rust "$OUT"
  echo "wrote $OUT/everquest_semconv.rs"
else
  OUT="${1:-$(cd "$(dirname "$0")/.." && pwd)/NewZeal/Zeal}"
  "$WEAVER" registry generate -r model --templates templates cpp "$OUT"
  echo "wrote $OUT/everquest_semconv.h"
fi
