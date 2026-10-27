#!/bin/sh
# regen.sh — rebuild obfuscated packages/*/root from the private src/*/root
# needs: UC=<ucode compiler>  ESB=<esbuild>   (bytecode is 24.10<->25.12 compatible)
set -e
ROOT=$(cd "$(dirname "$0")/.." && pwd)
for d in "$ROOT"/src/*/; do
	n=$(basename "$d"); [ -d "$d/root" ] || continue
	sh "$ROOT/scripts/obfuscate.sh" "$d/root" "$ROOT/packages/$n/root"
done
echo "regenerated packages/*/root from src/"
