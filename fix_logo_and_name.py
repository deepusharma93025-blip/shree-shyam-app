import os
import shutil
from PIL import Image

logo_paths = [
    '/storage/emulated/0/Pictures/app_logo.png',
    '/sdcard/Pictures/app_logo.png',
    'app_logo.png'
]

logo_src = None
for p in logo_paths:
    if os.path.exists(p):
        logo_src = p
        break

if not logo_src:
    print("Logo file nahi mili Pictures folder mein!")
    exit(1)

print(f"Found logo: {logo_src}")

# 1. Update Android App Label (restaurant -> Jai Shree Shyam)
manifest_path = "android/app/src/main/AndroidManifest.xml"
if os.path.exists(manifest_path):
    with open(manifest_path, 'r', encoding='utf-8') as f:
        mf = f.read()
    mf = mf.replace('android:label="restaurant"', 'android:label="Jai Shree Shyam"')
    mf = mf.replace('android:label="shree_shyam_app"', 'android:label="Jai Shree Shyam"')
    with open(manifest_path, 'w', encoding='utf-8') as f:
        f.write(mf)
    print("Updated App Name to Jai Shree Shyam")

# 2. Generate and Replace All Mipmap & Drawable Icons
res_dir = "android/app/src/main/res"
sizes = {
    'mipmap-mdpi': (48, 48),
    'mipmap-hdpi': (72, 72),
    'mipmap-xhdpi': (96, 96),
    'mipmap-xxhdpi': (144, 144),
    'mipmap-xxxhdpi': (192, 192),
}

img = Image.open(logo_src).convert("RGBA")

for folder, size in sizes.items():
    fpath = os.path.join(res_dir, folder)
    os.makedirs(fpath, exist_ok=True)
    resized = img.resize(size, Image.Resampling.LANCZOS)
    resized.save(os.path.join(fpath, 'ic_launcher.png'), 'PNG')
    # Background and foreground for adaptive
    resized.save(os.path.join(fpath, 'ic_launcher_foreground.png'), 'PNG')

# 3. Fix Adaptive XML (For Android 8 to 15+)
anydpi = os.path.join(res_dir, 'mipmap-anydpi-v26')
os.makedirs(anydpi, exist_ok=True)
xml_content = """<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/white"/>
    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>
</adaptive-icon>
"""
with open(os.path.join(anydpi, 'ic_launcher.xml'), 'w', encoding='utf-8') as f:
    f.write(xml_content)

# Values color
vals = os.path.join(res_dir, 'values')
os.makedirs(vals, exist_ok=True)
colors_xml = """<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="white">#FFFFFF</color>
</resources>
"""
with open(os.path.join(vals, 'colors.xml'), 'w', encoding='utf-8') as f:
    f.write(colors_xml)

print("SOLID_LOGO_SETUP_COMPLETE")
