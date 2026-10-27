#!/usr/bin/env python3
"""Minimal usign (OpenWrt opkg feed signing) compatible tool.

  usign.py gen  <secret-out> <public-out>       new Ed25519 key pair
  usign.py sign <secret-file> <file>            writes <file>.sig
  usign.py id   <public-file>                   prints the key id (opkg key file name)

Secret file format (ours): "untrusted comment: ...\\n" + base64(b"Ed" + keynum[8] + seed[32])
Public / signature files are byte-compatible with OpenWrt's usign.
"""
import base64, os, sys
from cryptography.hazmat.primitives.asymmetric.ed25519 import Ed25519PrivateKey
from cryptography.hazmat.primitives import serialization

RAW = serialization.Encoding.Raw


def b64line(path):
    with open(path) as f:
        lines = [l.strip() for l in f if l.strip()]
    return base64.b64decode(lines[-1])


def load_secret(path):
    blob = b64line(path)
    assert blob[:2] == b"Ed" and len(blob) == 42, "bad secret key"
    return blob[2:10], Ed25519PrivateKey.from_private_bytes(blob[10:42])


def main():
    cmd = sys.argv[1]
    if cmd == "gen":
        keynum, sk = os.urandom(8), Ed25519PrivateKey.generate()
        seed = sk.private_bytes(RAW, serialization.PrivateFormat.Raw, serialization.NoEncryption())
        pub = sk.public_key().public_bytes(RAW, serialization.PublicFormat.Raw)
        kid = keynum.hex()
        with open(sys.argv[2], "w") as f:
            f.write("untrusted comment: D3BOL feed secret key %s\n%s\n" % (kid, base64.b64encode(b"Ed" + keynum + seed).decode()))
        with open(sys.argv[3], "w") as f:
            f.write("untrusted comment: D3BOL feed public key %s\n%s\n" % (kid, base64.b64encode(b"Ed" + keynum + pub).decode()))
        print(kid)
    elif cmd == "sign":
        keynum, sk = load_secret(sys.argv[2])
        data = open(sys.argv[3], "rb").read()
        sig = sk.sign(data)
        with open(sys.argv[3] + ".sig", "w") as f:
            f.write("untrusted comment: signed by key %s\n%s\n" % (keynum.hex(), base64.b64encode(b"Ed" + keynum + sig).decode()))
    elif cmd == "id":
        print(b64line(sys.argv[2])[2:10].hex())
    else:
        sys.exit(__doc__)


if __name__ == "__main__":
    main()
