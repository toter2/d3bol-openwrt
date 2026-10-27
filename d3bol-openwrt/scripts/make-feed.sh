#!/bin/sh
# make-feed.sh <pkg-out-dir> <site-dir> <base-url>
#   builds signed feeds:
#     <site>/apk/<arch>/packages.adb   (OpenWrt 25, apk-tools v3, ECDSA key)
#     <site>/ipk/<arch>/Packages{,.gz,.sig}  (OpenWrt 24.10, opkg, usign key)
#   env: APK_KEY (private PEM file), USIGN_KEY (secret file from usign.py gen)
set -e
OUT=$(cd "$1" && pwd); SITE=$2; BASE=$3
HERE=$(cd "$(dirname "$0")" && pwd)
APK=${APK:-apk}
TARGETS=${TARGETS:-"aarch64_cortex-a53 x86_64"}
mkdir -p "$SITE/keys"

openssl ec -in "$APK_KEY" -pubout -out "$SITE/keys/d3bol.pem" 2>/dev/null
KID=$(python3 - "$USIGN_KEY" "$SITE/keys" <<'PY'
import base64, sys
from cryptography.hazmat.primitives.asymmetric.ed25519 import Ed25519PrivateKey
from cryptography.hazmat.primitives import serialization as s
blob = base64.b64decode([l for l in open(sys.argv[1]).read().split("\n") if l.strip()][-1])
kn, sk = blob[2:10], Ed25519PrivateKey.from_private_bytes(blob[10:42])
pub = sk.public_key().public_bytes(s.Encoding.Raw, s.PublicFormat.Raw)
open(sys.argv[2] + "/" + kn.hex(), "w").write("untrusted comment: D3BOL feed public key %s\n%s\n" % (kn.hex(), base64.b64encode(b"Ed" + kn + pub).decode()))
print(kn.hex())
PY
)
echo "$KID" > "$SITE/keys/usign-id"

for A in $TARGETS; do
	# apk feed
	D="$SITE/apk/$A"; mkdir -p "$D"
	# apk resolves files as <name>-<version>.apk inside the feed: drop our _<arch> suffix
	for f in "$OUT"/*_noarch.apk "$OUT"/*_"$A".apk; do
		[ -f "$f" ] || continue
		b=$(basename "$f"); b=${b%_noarch.apk}; b=${b%_"$A".apk}; cp "$f" "$D/$b.apk"
	done
	(cd "$D" && "$APK" mkndx --allow-untrusted --sign-key "$APK_KEY" --output packages.adb *.apk)   # same as OpenWrt package/Makefile
	# ipk feed
	D="$SITE/ipk/$A"; mkdir -p "$D"
	cp "$OUT"/*_all.ipk "$D/" 2>/dev/null || true
	cp "$OUT"/*_"$A".ipk "$D/" 2>/dev/null || true
	python3 "$HERE/ipkg-index.py" "$D"
	gzip -9nc "$D/Packages" > "$D/Packages.gz"
	python3 "$HERE/usign.py" sign "$USIGN_KEY" "$D/Packages"
done

sed "s#@BASE@#$BASE#g; s#@KID@#$KID#g" "$HERE/../site-static/install.sh" > "$SITE/install.sh"
sed "s#@BASE@#$BASE#g" "$HERE/../site-static/index.html" > "$SITE/index.html"
cp "$HERE/../site-static/logo.jpg" "$SITE/" 2>/dev/null || true
echo "feed ready in $SITE ($BASE)"
