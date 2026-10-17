# /// script
# requires-python = ">=3.10"
# dependencies = ["fonttools==4.67.0"]
# ///
"""Generate four filled corner glyphs for Herdr's borderless pane shading.

Run with: uv run generate_corners.py [--check]
The outlines are original. Metrics match JetBrains Mono's terminal cells.
"""

import argparse
from io import BytesIO
from pathlib import Path

from fontTools.fontBuilder import FontBuilder
from fontTools.pens.transformPen import TransformPen
from fontTools.pens.ttGlyphPen import TTGlyphPen


def build_font():
    width, top, bottom = 600, 1020, -300
    radius = width
    curve_bottom = top - radius
    # Mirror one circular corner into all four positions. Keep equal radii
    # even though the terminal cell is much taller than it is wide.
    corners = {
        0x1FBEE: (False, False),
        0x1FBED: (True, False),
        0x1FBEC: (False, True),
        0x1FBEF: (True, True),
    }
    glyphs = {".notdef": TTGlyphPen(None).glyph()}
    cmap = {}
    for codepoint, (mirror_x, mirror_y) in corners.items():
        name = f"u{codepoint:X}"
        target = TTGlyphPen(None)
        pen = TransformPen(
            target,
            (
                -1 if mirror_x else 1,
                0,
                0,
                -1 if mirror_y else 1,
                width if mirror_x else 0,
                top + bottom if mirror_y else 0,
            ),
        )
        pen.moveTo((width, bottom))
        pen.lineTo((0, bottom))
        pen.lineTo((0, curve_bottom))
        # Two quadratic segments approximate a quarter circle.
        pen.qCurveTo(
            (0, curve_bottom + radius * 0.414214),
            (radius * 0.292893, curve_bottom + radius * 0.707107),
        )
        pen.qCurveTo((radius * 0.585786, top), (radius, top))
        pen.closePath()
        glyphs[name] = target.glyph()
        cmap[codepoint] = name

    builder = FontBuilder(1000, isTTF=True)
    builder.setupGlyphOrder(list(glyphs))
    builder.setupCharacterMap(cmap)
    builder.setupGlyf(glyphs)
    builder.setupHorizontalMetrics({name: (width, 0) for name in glyphs})
    builder.setupHorizontalHeader(ascent=top, descent=bottom)
    builder.setupNameTable(
        {
            "familyName": "Herdr Pane Corners Round",
            "styleName": "Regular",
            "uniqueFontIdentifier": "HerdrPaneCornersRound-1.1",
            "fullName": "Herdr Pane Corners Round Regular",
            "psName": "HerdrPaneCornersRound-Regular",
            "version": "Version 1.1",
        }
    )
    builder.setupOS2(
        sTypoAscender=top,
        sTypoDescender=bottom,
        usWinAscent=top,
        usWinDescent=-bottom,
        sxHeight=550,
        sCapHeight=730,
    )
    builder.setupPost(isFixedPitch=1)
    builder.setupMaxp()
    builder.font["head"].created = builder.font["head"].modified = 2082844800
    builder.font.recalcTimestamp = False
    output = BytesIO()
    builder.font.save(output)
    return output.getvalue()


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    path = Path(__file__).with_name("HerdrPaneCorners.ttf")
    data = build_font()
    if args.check:
        if path.read_bytes() != data:
            raise SystemExit(f"{path.name} differs from the generated font")
        print(f"{path.name}: generated font matches")
    else:
        path.write_bytes(data)
        print(f"Wrote {path.name} ({len(data)} bytes)")
