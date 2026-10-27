#!/bin/sh
# build-pkg.sh <package-dir> <arch> <out-dir>
#   builds <name>_<ver>_<arch>.ipk (OpenWrt 24.10 / opkg) and <name>-<ver>.apk (OpenWrt 25 / apk-tools v3)
#   arch "all" = architecture independent (apk: noarch)
set -e
PKG=$(cd "$1" && pwd); ARCH=$2; OUT=$3
APK=${APK:-apk}
. "$PKG/pkg.conf"
mkdir -p "$OUT"
W=$(mktemp -d)
trap 'rm -rf "$W"' EXIT

cp -a "$PKG/root" "$W/data"
[ -x "$PKG/fetch.sh" ] && "$PKG/fetch.sh" "$ARCH" "$W/data"
find "$W/data" -name .keep -delete
find "$W/data" -type d -exec chmod 755 {} +
find "$W/data" -type f -exec chmod 644 {} +
for f in $EXEC; do chmod 755 "$W/data$f"; done
if [ -n "$CONFFILES" ]; then
	mkdir -p "$W/data/lib/apk/packages"
	for c in $CONFFILES; do echo "$c"; done > "$W/data/lib/apk/packages/$NAME.conffiles"
fi

V="$VERSION-r$RELEASE"
APKARCH=$ARCH; [ "$ARCH" = all ] && APKARCH=noarch
T="--owner=0 --group=0 --numeric-owner --sort=name --mtime=@1793000000 --format=gnu"

# ---- .ipk ----
mkdir -p "$W/ctrl"
{
	echo "Package: $NAME"
	echo "Version: $V"
	echo "Depends: libc, $(echo $DEPENDS | sed 's/ /, /g')"
	echo "Source: d3bol"
	echo "SourceName: $NAME"
	echo "License: $LICENSE"
	echo "Section: $SECTION"
	echo "Maintainer: Toter (@TOTER2)"
	echo "Architecture: $ARCH"
	echo "Installed-Size: $(du -sb "$W/data" | cut -f1)"
	echo "Description: $DESCRIPTION"
} > "$W/ctrl/control"
[ -n "$CONFFILES" ] && for c in $CONFFILES; do echo "$c"; done > "$W/ctrl/conffiles"
cp "$PKG/postinst" "$PKG/prerm" "$W/ctrl/"
chmod 755 "$W/ctrl/postinst" "$W/ctrl/prerm"
echo "2.0" > "$W/debian-binary"
(cd "$W/ctrl" && tar $T -czf "$W/control.tar.gz" ./)
(cd "$W/data" && tar $T -czf "$W/data.tar.gz" ./)
(cd "$W" && tar $T -czf "$OUT/${NAME}_${V}_${ARCH}.ipk" ./debian-binary ./control.tar.gz ./data.tar.gz)

# ---- .apk ----
"$APK" mkpkg \
	--info "name:$NAME" --info "version:$V" --info "arch:$APKARCH" \
	--info "description:$DESCRIPTION" --info "license:$LICENSE" --info "origin:d3bol" \
	--info "maintainer:Toter (@TOTER2)" --info "url:https://t.me/do3bl_store" \
	--info "depends:$DEPENDS" \
	--script "post-install:$PKG/postinst" --script "post-upgrade:$PKG/postinst" \
	--script "pre-deinstall:$PKG/prerm" \
	--files "$W/data" --output "$OUT/${NAME}-${V}_${APKARCH}.apk"

echo "built $NAME $V ($ARCH)"
