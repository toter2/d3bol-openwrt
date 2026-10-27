#!/usr/bin/env python3
"""obf-html.py <src.html> <dst.html> <esbuild>
Minify the inline <script> (wrapped in an IIFE so every top-level name is mangled)
and collapse the inline <style>. Everything else is left intact."""
import re, subprocess, sys, tempfile, os

src, dst, esb = sys.argv[1], sys.argv[2], sys.argv[3]
html = open(src, encoding="utf-8").read()


def min_js(code):
    code = "(()=>{%s})();" % code            # top-level names become locals -> mangled
    with tempfile.NamedTemporaryFile("w", suffix=".js", delete=False) as f:
        f.write(code); tmp = f.name
    out = subprocess.run([esb, tmp, "--minify", "--legal-comments=none"],
                         capture_output=True, text=True, check=True).stdout
    os.unlink(tmp)
    return out


def min_css(code):
    code = re.sub(r"/\*.*?\*/", "", code, flags=re.S)
    code = re.sub(r"\s+", " ", code)
    code = re.sub(r"\s*([{}:;,>])\s*", r"\1", code)
    return code.strip()


html = re.sub(r"(<script>)(.*?)(</script>)",
              lambda m: m.group(1) + min_js(m.group(2)) + m.group(3),
              html, flags=re.S)
html = re.sub(r"(<style>)(.*?)(</style>)",
              lambda m: m.group(1) + min_css(m.group(2)) + m.group(3),
              html, flags=re.S)

open(dst, "w", encoding="utf-8").write(html)
