#!/usr/bin/env python3
"""Make the Malayalam and Arabic fonts the app ships in app/assets/fonts.

  python3 tools/brand/script_fonts.py <manjari-regular.ttf> <manjari-bold.ttf> <naskh-variable.ttf>

Malayalam is Manjari (SMC) and Arabic is Noto Naskh Arabic, both under the SIL
Open Font License with no reserved font name. The files come from
github.com/google/fonts (ofl/manjari and ofl/notonaskharabic).

Both faces draw smaller than Manrope at the same size, so each is enlarged by
lowering its units per em: Manjari by 112% (the same size-adjust the website
uses) and Noto Naskh Arabic by 115%. Flutter has no size-adjust for fallback
fonts, so the scale has to live in the font file. Noto Naskh Arabic is a
variable font; it is cut to static 500 and 700 weights, the two the app asks
for, because Flutter does not move the weight axis on its own.

Needs fontTools (pip install fonttools).
"""
import os
import sys

from fontTools.ttLib import TTFont
from fontTools.varLib import instancer

OUT = os.path.join(os.path.dirname(__file__), '..', '..', 'app', 'assets', 'fonts')


def enlarge(font, scale):
    head = font['head']
    head.unitsPerEm = round(head.unitsPerEm / scale)
    return font


def main(manjari_regular, manjari_bold, naskh):
    jobs = [
        (lambda: TTFont(manjari_regular), 1.12, 'Manjari-500.ttf'),
        (lambda: TTFont(manjari_bold), 1.12, 'Manjari-700.ttf'),
        (lambda: instancer.instantiateVariableFont(TTFont(naskh), {'wght': 500}, updateFontNames=True), 1.15, 'NotoNaskhArabic-500.ttf'),
        (lambda: instancer.instantiateVariableFont(TTFont(naskh), {'wght': 700}, updateFontNames=True), 1.15, 'NotoNaskhArabic-700.ttf'),
    ]
    for load, scale, name in jobs:
        path = os.path.join(OUT, name)
        enlarge(load(), scale).save(path)
        print(name, os.path.getsize(path))


if __name__ == '__main__':
    if len(sys.argv) != 4:
        sys.exit(__doc__)
    main(*sys.argv[1:])
