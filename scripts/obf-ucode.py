#!/usr/bin/env python3
"""obf-ucode.py <src.uc> <dst.uc>
Safe ucode source minifier: drops full-line comments, blank lines and leading
indentation only (never touches code or string contents), so the result parses
identically on any ucode version. A shebang first line is preserved.
The installed package compiles this to device-native bytecode in postinst."""
import re, sys

src = open(sys.argv[1], encoding="utf-8").read().split("\n")
out, in_block = [], False
for i, line in enumerate(src):
    if i == 0 and line.startswith("#!"):
        out.append(line); continue
    s = line.strip()
    if in_block:
        if "*/" in s:
            in_block = False
            tail = s.split("*/", 1)[1].strip()
            if tail:
                out.append(tail)
        continue
    if s == "" :
        continue
    if s.startswith("//"):
        continue
    if s.startswith("/*"):
        if "*/" in s:
            tail = s.split("*/", 1)[1].strip()
            if tail:
                out.append(tail)
        else:
            in_block = True
        continue
    out.append(s)   # trimmed of leading indentation

open(sys.argv[2], "w", encoding="utf-8").write("\n".join(out) + "\n")
