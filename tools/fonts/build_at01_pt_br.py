"""Build an at01 variant with real Latin accented glyphs.

The original at01 outlines are preserved. Only the placeholder glyphs used by
Latin-1 accented letters are replaced with outlines drawn on at01's 64-unit
pixel grid.
"""

from __future__ import annotations

from pathlib import Path

from fontTools.pens.ttGlyphPen import TTGlyphPen
from fontTools.ttLib import TTFont


ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "fonts" / "at01.ttf"
OUTPUT = ROOT / "fonts" / "at01_pt_br" / "at01_pt_br.ttf"
PIXEL = 64


def add_rectangle(pen: TTGlyphPen, x: int, y: int) -> None:
    """Add one at01 pixel to an outline."""
    pen.moveTo((x, y))
    pen.lineTo((x, y + PIXEL))
    pen.lineTo((x + PIXEL, y + PIXEL))
    pen.lineTo((x + PIXEL, y))
    pen.closePath()


def draw_base(font: TTFont, pen: TTGlyphPen, glyph_name: str) -> None:
    font["glyf"][glyph_name].draw(pen, font["glyf"])


def glyph_center(font: TTFont, glyph_name: str) -> int:
    glyph = font["glyf"][glyph_name]
    glyph.recalcBounds(font["glyf"])
    geometric_center = glyph.xMin + glyph.xMax
    return ((geometric_center + PIXEL) // (2 * PIXEL)) * PIXEL


def add_mark(
    pen: TTGlyphPen,
    mark: str,
    center: int,
    base_top: int,
) -> None:
    """Draw a pixel accent with a one-pixel gap above the base letter."""
    bottom = base_top + PIXEL

    if mark == "acute":
        add_rectangle(pen, center - PIXEL, bottom)
        add_rectangle(pen, center, bottom + PIXEL)
    elif mark == "grave":
        add_rectangle(pen, center, bottom)
        add_rectangle(pen, center - PIXEL, bottom + PIXEL)
    elif mark == "circumflex":
        add_rectangle(pen, center - PIXEL, bottom)
        add_rectangle(pen, center, bottom + PIXEL)
        add_rectangle(pen, center + PIXEL, bottom)
    elif mark == "tilde":
        add_rectangle(pen, center - PIXEL, bottom + PIXEL)
        add_rectangle(pen, center, bottom + PIXEL)
        add_rectangle(pen, center + PIXEL, bottom)
        add_rectangle(pen, center + 2 * PIXEL, bottom)
    elif mark == "dieresis":
        add_rectangle(pen, center - 2 * PIXEL, bottom)
        add_rectangle(pen, center + PIXEL, bottom)
    else:
        raise ValueError(f"Unsupported mark: {mark}")


def make_accented(font: TTFont, target: str, base: str, mark: str) -> None:
    pen = TTGlyphPen(font.getGlyphSet())
    draw_base(font, pen, base)
    base_glyph = font["glyf"][base]
    base_glyph.recalcBounds(font["glyf"])
    base_top = base_glyph.yMax
    add_mark(pen, mark, glyph_center(font, base), base_top)
    font["glyf"][target] = pen.glyph()
    font["hmtx"][target] = font["hmtx"][base]


def make_cedilla(font: TTFont, target: str, base: str) -> None:
    pen = TTGlyphPen(font.getGlyphSet())
    draw_base(font, pen, base)
    center = glyph_center(font, base)
    add_rectangle(pen, center - PIXEL, -PIXEL)
    add_rectangle(pen, center - 2 * PIXEL, -2 * PIXEL)
    add_rectangle(pen, center - PIXEL, -2 * PIXEL)
    font["glyf"][target] = pen.glyph()
    font["hmtx"][target] = font["hmtx"][base]


def make_dotless_i(font: TTFont) -> None:
    pen = TTGlyphPen(None)
    add_rectangle(pen, 0, 0)
    add_rectangle(pen, 0, PIXEL)
    add_rectangle(pen, 0, 2 * PIXEL)
    add_rectangle(pen, 0, 3 * PIXEL)
    add_rectangle(pen, 0, 4 * PIXEL)
    font["glyf"]["dotlessi"] = pen.glyph()
    font["hmtx"]["dotlessi"] = font["hmtx"]["i"]


def set_font_name(font: TTFont, name_id: int, value: str) -> None:
    name_table = font["name"]
    for record in name_table.names:
        if record.nameID == name_id:
            record.string = value.encode(record.getEncoding())
    name_table.setName(value, name_id, 3, 1, 0x0409)
    name_table.setName(value, name_id, 1, 0, 0)


def main() -> None:
    font = TTFont(SOURCE)

    make_dotless_i(font)

    families = {
        "A": ("A", "a"),
        "E": ("E", "e"),
        "I": ("I", "dotlessi"),
        "O": ("O", "o"),
        "U": ("U", "u"),
    }
    accents = {
        "grave": "grave",
        "acute": "acute",
        "circumflex": "circumflex",
        "tilde": "tilde",
        "dieresis": "dieresis",
    }

    for letter, (upper_base, lower_base) in families.items():
        for suffix, mark in accents.items():
            upper_name = f"{letter}{suffix}"
            lower_name = f"{letter.lower()}{suffix}"
            if upper_name in font["glyf"]:
                make_accented(font, upper_name, upper_base, mark)
            if lower_name in font["glyf"]:
                make_accented(font, lower_name, lower_base, mark)

    make_accented(font, "Ntilde", "N", "tilde")
    make_accented(font, "ntilde", "n", "tilde")
    make_cedilla(font, "Ccedilla", "C")
    make_cedilla(font, "ccedilla", "c")

    set_font_name(font, 0, "GrafxKid; Portuguese glyph extension by the Peakguin project")
    set_font_name(font, 1, "at01 PT-BR")
    set_font_name(font, 4, "at01 PT-BR")
    set_font_name(font, 5, "Version 001.100")
    set_font_name(font, 6, "at01-PT-BR")
    set_font_name(
        font,
        13,
        "Based on GrafxKid's at01, released to the public domain under CC0 1.0.",
    )
    set_font_name(font, 14, "https://grafxkid.itch.io/at01")

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    font.save(OUTPUT, reorderTables=True)
    print(f"Created {OUTPUT.relative_to(ROOT)} ({OUTPUT.stat().st_size} bytes)")


if __name__ == "__main__":
    main()
