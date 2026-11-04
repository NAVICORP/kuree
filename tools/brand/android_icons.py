"""The Android app icon, from the brand pictures in app/assets/brand.

    python3 tools/brand/android_icons.py

Writes, under app/android/app/src/main/res:
- mipmap-*dpi/ic_launcher.png: the full icon (icon.png), for older Androids.
- drawable-*dpi/ic_launcher_foreground.png: the card (icon-foreground.png),
  drawable-*dpi/ic_launcher_background.png: the deep green with its soft glow,
  drawable-*dpi/ic_launcher_monochrome.png: the card in one colour with the K
  cut out, for themed icons (Android 13 and later),
  and mipmap-anydpi-v26/ic_launcher.xml, which puts the three together, so the
  launcher can shape the icon (circle, squircle) without cropping the card.
"""
import math
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
BRAND = ROOT / 'app' / 'assets' / 'brand'
RES = ROOT / 'app' / 'android' / 'app' / 'src' / 'main' / 'res'
DENSITIES = {'mdpi': 1, 'hdpi': 1.5, 'xhdpi': 2, 'xxhdpi': 3, 'xxxhdpi': 4}

# The icon's background: deep green, a little lighter towards the top middle.
STOPS = [(0.0, (17, 76, 29)), (0.35, (8, 58, 18)), (0.7, (3, 40, 9)), (1.0, (2, 26, 5))]


def background(size):
    img = Image.new('RGB', (size, size))
    px = img.load()
    cx, cy = size * 0.5, size * 0.3
    far = math.hypot(size * 0.5, size * 0.7)
    for y in range(size):
        for x in range(size):
            d = min(1.0, math.hypot(x - cx, y - cy) / far)
            for (a, ca), (b, cb) in zip(STOPS, STOPS[1:]):
                if a <= d <= b:
                    t = (d - a) / (b - a)
                    px[x, y] = tuple(round(ca[i] + (cb[i] - ca[i]) * t) for i in range(3))
                    break
    return img


def monochrome(fg):
    """The card's outline in white, with the dark K (and nothing else) cut out."""
    fg = fg.convert('RGBA')
    out = Image.new('RGBA', fg.size, (255, 255, 255, 0))
    src, dst = fg.load(), out.load()
    for y in range(fg.size[1]):
        for x in range(fg.size[0]):
            r, g, b, a = src[x, y]
            lum = 0.299 * r + 0.587 * g + 0.114 * b
            keep = 0 if lum < 90 else 1
            dst[x, y] = (255, 255, 255, a * keep)
    return out


def main():
    icon = Image.open(BRAND / 'icon.png').convert('RGBA')
    fg = Image.open(BRAND / 'icon-foreground.png').convert('RGBA')
    mono = monochrome(fg)
    bg = background(432)
    for name, k in DENSITIES.items():
        legacy = round(48 * k)
        adaptive = round(108 * k)
        m = RES / f'mipmap-{name}'
        m.mkdir(parents=True, exist_ok=True)
        icon.resize((legacy, legacy), Image.LANCZOS).save(m / 'ic_launcher.png', optimize=True)
        d = RES / f'drawable-{name}'
        d.mkdir(parents=True, exist_ok=True)
        fg.resize((adaptive, adaptive), Image.LANCZOS).save(d / 'ic_launcher_foreground.png', optimize=True)
        bg.resize((adaptive, adaptive), Image.LANCZOS).save(d / 'ic_launcher_background.png', optimize=True)
        mono.resize((adaptive, adaptive), Image.LANCZOS).save(d / 'ic_launcher_monochrome.png', optimize=True)
    a = RES / 'mipmap-anydpi-v26'
    a.mkdir(parents=True, exist_ok=True)
    (a / 'ic_launcher.xml').write_text(
        '<?xml version="1.0" encoding="utf-8"?>\n'
        '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
        '    <background android:drawable="@drawable/ic_launcher_background"/>\n'
        '    <foreground android:drawable="@drawable/ic_launcher_foreground"/>\n'
        '    <monochrome android:drawable="@drawable/ic_launcher_monochrome"/>\n'
        '</adaptive-icon>\n')
    print('icons written to', RES)


if __name__ == '__main__':
    main()
