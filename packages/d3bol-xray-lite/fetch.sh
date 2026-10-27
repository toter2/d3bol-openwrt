#!/bin/sh
# fetch.sh <arch> <dest-root> — download pinned upstream binaries, verify sha256, store xz-packed
set -e
ARCH=$1; DEST=$2/usr/share/d3bol-lite
case "$ARCH" in
	aarch64_cortex-a53|aarch64_*)
		XZIP=Xray-linux-arm64-v8a.zip; XSHA=82939febc98c2738dd78e931a69967f9c16b771bd20f313bfc0629bacd13bab6
		VBIN=v2raya_linux_arm64_2.3.4;  VSHA=a9d26d3752af3561093a0ba318668b2f061623bb09ec55778bdf121df9e5144b ;;
	x86_64)
		XZIP=Xray-linux-64.zip;         XSHA=47a860787e823474a358d6bca536547df6dd08b69c6de482ea92a9e7e8f8969c
		VBIN=v2raya_linux_x64_2.3.4;    VSHA=36fb3b77c86a66e3c1bda7d3b6168fce72909f9de4918bc079b87274d3c4f695 ;;
	*) echo "unsupported arch $ARCH" >&2; exit 1 ;;
esac
T=$(mktemp -d)
curl -fsSL -o "$T/x.zip" "https://github.com/XTLS/Xray-core/releases/download/v1.8.24/$XZIP"
curl -fsSL -o "$T/v2raya" "https://github.com/v2rayA/v2rayA/releases/download/v2.3.4/$VBIN"
echo "$XSHA  $T/x.zip" | sha256sum -c -
echo "$VSHA  $T/v2raya" | sha256sum -c -
(cd "$T" && python3 -c "import zipfile; zipfile.ZipFile('x.zip').extract('xray')")
mkdir -p "$DEST"
for b in xray v2raya; do
	xz -9e -T1 -c "$T/$b" > "$DEST/$b.xz"
	wc -c < "$T/$b" | tr -d ' \n' > "$DEST/$b.size"
done
rm -f "$DEST/.keep"; rm -rf "$T"
