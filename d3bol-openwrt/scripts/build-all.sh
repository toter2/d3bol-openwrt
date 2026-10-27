#!/bin/sh
# build-all.sh <base-url> — build every package for every arch, then the signed feed in ./site
set -e
ROOT=$(cd "$(dirname "$0")/.." && pwd)
BASE=${1:?usage: build-all.sh <base-url>}
OUT=$ROOT/out; SITE=$ROOT/site
rm -rf "$OUT" "$SITE"; mkdir -p "$OUT" "$SITE"
for p in "$ROOT"/packages/*/; do
	ARCHS=$(. "$p/pkg.conf"; echo "$ARCHS")
	for a in $ARCHS; do sh "$ROOT/scripts/build-pkg.sh" "$p" "$a" "$OUT"; done
done
sh "$ROOT/scripts/make-feed.sh" "$OUT" "$SITE" "$BASE"
ls -l "$OUT"
