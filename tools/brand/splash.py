"""The launch screen pictures, from the brand card in app/assets/brand.

    python3 tools/brand/splash.py

Every launch screen shows the same thing: the chit card (icon-foreground.png)
in the middle of deep green, in a square 288 points wide, with the card
inside the middle circle of 192 points. That circle is all Android 12 and
later show of a splash icon, so the card is never cut there, and the same
picture on iOS and older Androids puts the card in exactly the same place.
The app's own loading screen (lib/ui/launch.dart) starts from that same
square, so it carries on from the phone's launch screen without a jump.

Writes:
- app/assets/brand/splash.png: the square at 4x, for the app.
- app/android/app/src/main/res/drawable-*dpi/splash.png: for Android.
- app/ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage*.png: for iOS.
"""
import math
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
BRAND = ROOT / 'app' / 'assets' / 'brand'
RES = ROOT / 'app' / 'android' / 'app' / 'src' / 'main' / 'res'
IOS = ROOT / 'app' / 'ios' / 'Runner' / 'Assets.xcassets' / 'LaunchImage.imageset'
DENSITIES = {'mdpi': 1, 'hdpi': 1.5, 'xhdpi': 2, 'xxhdpi': 3, 'xxxhdpi': 4}

BOX = 288  # the square, in points
SAFE = 192  # the circle Android 12 shows, in points
MARGIN = 0.96  # the card stays a little inside that circle


def square():
    """The card, centred, with its farthest pixel just inside the safe circle."""
    fg = Image.open(BRAND / 'icon-foreground.png').convert('RGBA')
    alpha = fg.split()[-1]
    x0, y0, x1, y1 = alpha.getbbox()
    cx, cy = (x0 + x1) / 2, (y0 + y1) / 2
    px = alpha.load()
    far = 0.0
    for y in range(y0, y1):
        for x in range(x0, x1):
            if px[x, y] > 8:
                far = max(far, math.hypot(x - cx, y - cy))
    # Points per source pixel, then the source square that makes the 288 box.
    k = (SAFE / 2 * MARGIN) / far
    side = BOX / k
    big = 4 * BOX
    scale = big / side
    card = fg.crop((x0, y0, x1, y1)).resize((round((x1 - x0) * scale), round((y1 - y0) * scale)), Image.LANCZOS)
    out = Image.new('RGBA', (big, big), (0, 0, 0, 0))
    out.alpha_composite(card, (round(big / 2 - (cx - x0) * scale), round(big / 2 - (cy - y0) * scale)))
    return out


def main():
    sq = square()
    sq.save(BRAND / 'splash.png', optimize=True)
    for name, d in DENSITIES.items():
        folder = RES / f'drawable-{name}'
        folder.mkdir(parents=True, exist_ok=True)
        n = round(BOX * d)
        sq.resize((n, n), Image.LANCZOS).save(folder / 'splash.png', optimize=True)
    for suffix, d in (('', 1), ('@2x', 2), ('@3x', 3)):
        n = BOX * d
        sq.resize((n, n), Image.LANCZOS).save(IOS / f'LaunchImage{suffix}.png', optimize=True)


if __name__ == '__main__':
    main()
