<p align="center"><img src="site-static/logo.jpg" width="110"></p>

# D3BOL OpenWrt

حزم دعبول ستور للراوترات (OpenWrt 24.10 و 25):

| الحزمة | شنو تسوي |
|---|---|
| `d3bol-panel` | لوحة بيوزر وباسورد على 2017 (بديل v2rayA)، بروكسي شفاف، سيرفرات واشتراكات، HTTP Ping، صفحة LuCI، تدعم xray و **sing-box** (يختاره إذا منصّب) |
| `luci-app-d3bol-split` | عزل التطبيقات: تطبيقات تطلع مباشر على الخط بدون VPN |
| `d3bol-xray-lite` | xray 1.8.24 مضغوط يشتغل من الرام: أقل استهلاك، ويقبل vless بدون TLS |

## التنصيب

```sh
wget -qO- https://toter2.github.io/d3bol-openwrt/install.sh | sh
```

التحديث: `apk upgrade` (OpenWrt 25) أو `opkg update && opkg upgrade d3bol-panel luci-app-d3bol-split d3bol-xray-lite` (24.10).

الأجهزة: `aarch64_cortex-a53` (GL-MT6000، Linksys MX2000…) و `x86_64`. اللوحة والعزل تشتغل على كل المعماريات.

## إصدار نسخة جديدة

1. عدّل الكود تحت `packages/<الحزمة>/root/`.
2. ارفع رقم `VERSION` (أو `RELEASE`) بـ `packages/<الحزمة>/pkg.conf`.
3. `git push` — GitHub Actions يبني الحزم ويوقّعها وينشر المستودع على GitHub Pages تلقائياً.


## الحماية (التشفير)

الملفات المنشورة بالريبو والباكجات **مشفّرة**، فاللي يحمّلها أو يتصفح الريبو ما يكدر يقرا الكود:

- محرك اللوحة والعزل (`.uc`) وإضافة rpcd → **bytecode مترجم** (ucode يشغّله مباشرة؛ متوافق بين OpenWrt 24.10 و 25.12).
- سكربتات CGI و CLI → bytecode بترويسة `#!/usr/bin/ucode`.
- جافاسكربت اللوحة وصفحات LuCI → مصغّرة ومشفّرة الأسماء (esbuild).
- سكربتات الشِل → بدون تعليقات.

الكود المقروء موجود بس بمجلد `src/` (مو مرفوع للريبو، محفوظ خاص). أي تعديل: عدّل `src/`، بعدها:

```sh
UC=<ucode> ESB=<esbuild> sh scripts/regen.sh   # يولّد packages/*/root المشفّرة من src/
git add -A && git commit && git push            # Actions يعيد البناء والنشر
```

> ملاحظة: التشفير يصعّب القراءة والنسخ بشكل كبير، لكنه مو تشفير مطلق — نفس مستوى حماية أي كود مصغّر/مترجم.

## الهيكل

```
packages/<name>/pkg.conf     اسم، نسخة، معماريات، اعتماديات
src/<name>/root/              المصدر المقروء (خاص، مو بالريبو)
packages/<name>/root/        الملفات المشفّرة كما تنحط بالراوتر
scripts/obfuscate.sh         يشفّر شجرة مصدر -> شجرة منشورة
scripts/regen.sh             يعيد توليد كل الحزم من src/
packages/<name>/postinst     بعد التنصيب
packages/<name>/prerm        قبل الحذف
packages/d3bol-xray-lite/fetch.sh   ينزّل xray 1.8.24 الرسمي ويتأكد من sha256
scripts/build-pkg.sh         يبني .ipk و .apk
scripts/make-feed.sh         يولّد المستودع الموقّع (apk + opkg)
site-static/                 install.sh وصفحة المستودع
```

## التوقيع

- OpenWrt 25: الفهرس `packages.adb` موقّع بمفتاح ECDSA (السر `APK_SIGN_KEY`)، والمفتاح العام `keys/d3bol.pem`.
- OpenWrt 24.10: `Packages.sig` بتوقيع usign (السر `USIGN_SECRET_KEY`).

المفاتيح السرية موجودة بس بـ GitHub Secrets. لا ترفعها للريبو.

---
© D3BOL STORE · [@do3bl_store](https://t.me/do3bl_store) · [@TOTER2](https://t.me/TOTER2)
