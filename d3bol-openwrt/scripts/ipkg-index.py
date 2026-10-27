#!/usr/bin/env python3
"""ipkg-index.py <dir> — write <dir>/Packages for every .ipk in <dir> (OpenWrt opkg feed index)."""
import hashlib, io, os, sys, tarfile

d = sys.argv[1]
entries = []
for fn in sorted(os.listdir(d)):
    if not fn.endswith(".ipk"):
        continue
    path = os.path.join(d, fn)
    raw = open(path, "rb").read()
    with tarfile.open(fileobj=io.BytesIO(raw), mode="r:gz") as outer:
        ctl_tgz = outer.extractfile("./control.tar.gz").read()
    with tarfile.open(fileobj=io.BytesIO(ctl_tgz), mode="r:gz") as ctl:
        control = ctl.extractfile("./control").read().decode().strip()
    entries.append("%s\nFilename: %s\nSize: %d\nSHA256sum: %s\n" % (
        control, fn, len(raw), hashlib.sha256(raw).hexdigest()))

with open(os.path.join(d, "Packages"), "w") as f:
    f.write("\n".join(entries))
print("%s: %d packages" % (d, len(entries)))
