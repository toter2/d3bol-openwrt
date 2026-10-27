#!/bin/sh
# obfuscate.sh <src-root> <dst-root>
#   turns a readable package payload tree into a shipped one:
#     ucode engines / rpcd plugins  -> compiled bytecode (require + rpcd load it)
#     ucode CLI / CGI scripts        -> bytecode with a #!/usr/bin/ucode line
#     web + LuCI JavaScript          -> esbuild minify + local-name mangling
#     shell scripts                  -> comments and blank lines stripped
#   everything else (json, lists, geo, images, .xz) is copied unchanged.
# env: UC (ucode compiler, bytecode is cross-compatible 24.10<->25.12), ESB (esbuild)
set -e
SRC=$(cd "$1" && pwd); DST=$2
UC=${UC:-ucode}; ESB=${ESB:-esbuild}
HERE=$(cd "$(dirname "$0")" && pwd)
rm -rf "$DST"; mkdir -p "$DST"

is_ucode_exec() {   # ucode scripts that are run directly (shebang)
	case "$1" in
		usr/sbin/d3bol-panel|usr/sbin/d3bol-split|*/www/cgi-bin/api) return 0 ;;
	esac
	return 1
}
is_ucode_mod() {    # ucode loaded by require()/rpcd — pure bytecode, no shebang
	case "$1" in
		usr/share/ucode/*.uc|usr/share/rpcd/ucode/*) return 0 ;;
	esac
	return 1
}
is_shell() {
	case "$1" in
		etc/init.d/*|usr/sbin/d3bol-lite|usr/share/d3bol-split/loop.sh) return 0 ;;
	esac
	return 1
}

uc_compile() {   # compile with a bare basename so no build path is embedded in the bytecode
	_s=$1; _d=$2; _flag=$3; _tmp=$(mktemp -d); _b=$(basename "$_s")
	cp "$_s" "$_tmp/$_b"; _da=$(cd "$(dirname "$_d")" && pwd)/$(basename "$_d")
	( cd "$_tmp" && $UC "$_flag" -o "$_da" "$_b" ); rm -rf "$_tmp"
}

( cd "$SRC" && find . -type f | sed 's|^\./||' ) | while read -r rel; do
	src="$SRC/$rel"; dst="$DST/$rel"
	mkdir -p "$(dirname "$dst")"
	if is_ucode_mod "$rel"; then
		uc_compile "$src" "$dst" "-cno-interp"; chmod 644 "$dst"
	elif is_ucode_exec "$rel"; then
		uc_compile "$src" "$dst" "-cinterp=/usr/bin/ucode"; chmod 755 "$dst"
	elif echo "$rel" | grep -q "/www/index.html$"; then
		python3 "$HERE/obf-html.py" "$src" "$dst" "$ESB"
	elif echo "$rel" | grep -q '\.js$'; then
		"$ESB" "$src" --minify --legal-comments=none > "$dst"
	elif is_shell "$rel"; then
		# keep the shebang/first line, drop comment-only and blank lines, trim indentation
		awk 'NR==1{print; next} /^[[:space:]]*#/{next} /^[[:space:]]*$/{next}
		     {sub(/^[[:space:]]+/,""); print}' "$src" > "$dst"
		chmod "$(stat -c %a "$src")" "$dst"
	else
		cp -a "$src" "$dst"
	fi
done
echo "obfuscated $SRC -> $DST"
