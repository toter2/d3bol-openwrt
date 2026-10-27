#!/bin/sh
# D3BOL feed — one-line install for OpenWrt 24.10 (opkg) and 25.x (apk)
#   wget -qO- @BASE@/install.sh | sh
#   wget -qO- @BASE@/install.sh | sh -s -- d3bol-panel        (only some packages)
BASE="@BASE@"
KID="@KID@"
PKGS="${*:-d3bol-panel luci-app-d3bol-split d3bol-xray-lite}"

say() { printf '\033[1;36m» %s\033[0m\n' "$*"; }
die() { printf '\033[1;31m✗ %s\033[0m\n' "$*"; exit 1; }

[ "$(id -u)" = 0 ] || die "run as root"

# ---- scan: which OpenWrt / package manager / CPU ----
. /etc/openwrt_release 2>/dev/null
REL=${DISTRIB_RELEASE:-unknown}
MAJOR=$(echo "$REL" | cut -d. -f1)
say "OpenWrt $REL · ${DISTRIB_TARGET:-?} · $(uname -m)"
if command -v apk >/dev/null 2>&1 && [ -f /etc/apk/arch ]; then PM=apk
elif command -v opkg >/dev/null 2>&1; then PM=opkg
else die "no apk or opkg found"; fi
case "$MAJOR" in
	2[5-9]|[3-9][0-9]) [ "$PM" = apk ] || say "warning: OpenWrt $REL but no apk — using opkg" ;;
	2[0-4]|1[0-9])     [ "$PM" = opkg ] || say "warning: OpenWrt $REL but apk found — using apk" ;;
	SNAPSHOT|unknown)  ;;
esac
say "package manager: $PM"

if [ "$PM" = apk ]; then
	ARCH=$(cat /etc/apk/arch 2>/dev/null)
	say "arch: $ARCH"
	case "$ARCH" in
		aarch64_cortex-a53|x86_64) FEED="$BASE/apk/$ARCH" ;;
		*) FEED="$BASE/apk/x86_64"; PKGS=$(echo "$PKGS" | sed 's/d3bol-xray-lite//')
		   say "no lite core build for $ARCH — installing panel + split only" ;;
	esac
	mkdir -p /etc/apk/keys /etc/apk/repositories.d
	wget -qO /etc/apk/keys/d3bol.pem "$BASE/keys/d3bol.pem" || die "cannot download key"
	echo "$FEED/packages.adb" > /etc/apk/repositories.d/d3bol.list
	say "updating package lists"
	apk update || die "apk update failed"
	say "installing: $PKGS"
	apk add $PKGS || die "install failed"
else
	ARCH=$(opkg print-architecture | awk '{print $2}' | grep -E '^(aarch64_cortex-a53|x86_64)$' | tail -n1)
	say "arch: ${ARCH:-other}"
	[ -n "$ARCH" ] || { ARCH=x86_64; PKGS=$(echo "$PKGS" | sed 's/d3bol-xray-lite//'); }
	mkdir -p /etc/opkg/keys
	wget -qO "/etc/opkg/keys/$KID" "$BASE/keys/$KID" || die "cannot download key"
	sed -i '/d3bol/d' /etc/opkg/customfeeds.conf 2>/dev/null
	echo "src/gz d3bol $BASE/ipk/$ARCH" >> /etc/opkg/customfeeds.conf
	say "updating package lists"
	opkg update || die "opkg update failed"
	say "installing: $PKGS"
	opkg install $PKGS || die "install failed"
fi

rm -rf /tmp/luci-indexcache* /tmp/luci-modulecache 2>/dev/null
IP=$(uci -q get network.lan.ipaddr | cut -d/ -f1)
P=$(cat /tmp/d3bol-panel.port 2>/dev/null || echo 2017)
say "done — D3BOL Panel: http://${IP:-192.168.1.1}:$P   ·   updates: apk upgrade / opkg upgrade"
