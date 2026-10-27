#!/usr/bin/env python3
"""obfuscate.py <root-dir> — scramble D3BOL code inside a package tree (in place, build copy only).

Every ucode / JavaScript file becomes an XOR + base64 blob plus a tiny loader that
decodes it in memory at run time:
  * ucode (.uc modules, rpcd plugins, CGI/CLI scripts with #!/usr/bin/ucode):
      loadstring(decoded)()            — supported by ucode in OpenWrt 24.10 and 25
  * LuCI views (www/luci-static/resources/view/**.js):
      'require' header kept for LuCI's loader, body decoded with eval()
  * the pan