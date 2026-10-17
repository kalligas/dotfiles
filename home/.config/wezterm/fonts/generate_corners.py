# /// script
# requires-python = ">=3.10"
# dependencies = ["fonttools==4.67.0"]
# ///
"""Generate circular pane corners and tab caps for Herdr's selected surfaces.

Run with: uv run generate_corners.py [--check]
The outlines are original. Metrics match JetBrains Mono's terminal cells.
"""

import argparse
from io import BytesIO
from pathlib import Path

from fontTools.fontBuilder import FontBuilder
from fontTools.pens.transformPen import TransformPen
from fontTools.pens.ttGlyphPen import TTGlyphPen

# WezTerm drops the alpha of a text color, so each glyph carries the
# translucent surface gray as a color layer. Keep it equal to palette index
# 235 in wezterm.lua, which fills the rest of each selected surface.
SURFACE_RGBA = (78, 84, 94, 64)


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

    # One-row tabs need both top and bottom curves in each end cell.
    # Use plane-16 private-use characters to avoid Nerd Font icon ranges.
    for codepoint, mirror_x in [(0x10F000, False), (0x10F001, True)]:
        name = f"u{codepoint:X}"
        target = TTGlyphPen(None)
        pen = TransformPen(
            target, (-1 if mirror_x else 1, 0, 0, 1, width if mirror_x else 0, 0)
        )
        pen.moveTo((width, bottom))
        pen.lineTo((width, top))
        pen.qCurveTo(
            (radius * 0.585786, top),
            (radius * 0.292893, curve_bottom + radius * 0.707107),
        )
        pen.qCurveTo((0, curve_bottom + radius * 0.414214), (0, curve_bottom))
        pen.lineTo((0, bottom + radius))
        pen.qCurveTo(
            (0, bottom + radius * 0.585786),
            (radius * 0.292893, bottom + radius * 0.292893),
        )
        pen.qCurveTo((radius * 0.585786, bottom), (width, bottom))
        pen.closePath()
        glyphs[name] = target.glyph()
        cmap[codepoint] = name

    # Each mapped glyph paints an identical outline layer in the surface gray.
    layers = {}
    for name in cmap.values():
        glyphs[f"{name}.fill"] = glyphs[name]
        layers[name] = [(f"{name}.fill", 0)]

    builder = FontBuilder(1000, isTTF=True)
    builder.setupGlyphOrder(list(glyphs))
    builder.setupCharacterMap(cmap)
    builder.setupGlyf(glyphs)
    builder.setupHorizontalMetrics({name: (width, 0) for name in glyphs})
    builder.setupCOLR(layers, version=0)
    builder.setupCPAL([[tuple(channel / 255 for channel in SURFACE_RGBA)]])
    builder.setupHorizontalHeader(ascent=top, descent=bottom)
    builder.setupNameTable(
        {
            "familyName": "Herdr Rounded UI",
            "styleName": "Regular",
            "uniqueFontIdentifier": "HerdrRoundedUI-1.3",
            "fullName": "Herdr Rounded UI Regular",
            "psName": "HerdrRoundedUI-Regular",
            "version": "Version 1.3",
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
