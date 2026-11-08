"""The project's one image set: palette-bound SVGs plus PNG renders that have SVG sources.

Responsibilities: check SVGs under assets/ and skills/*/assets/ have a <title> and use
only colors from assets/brand.json, every PNG there has an SVG beside it, and the
Claude manifest icon is assets/icon.png, square and at least 512 pixels wide.

Invariants: reads only.
"""

from pathlib import Path
import json
import struct
from xml.etree import ElementTree

from helpers import ROOT, read_json

SVG_NS = "{http://www.w3.org/2000/svg}"


def png_size(path: Path) -> tuple[int, int]:
    data = path.read_bytes()[:24]
    assert data[:8] == b"\x89PNG\r\n\x1a\n", f"{path} is not a PNG"
    return struct.unpack(">II", data[16:24])


def svgs() -> list[Path]:
    return sorted(ROOT.glob("assets/*.svg")) + sorted(ROOT.glob("skills/*/assets/*.svg"))


def test_svgs_use_only_the_brand_palette() -> None:
    palette = {c.lower() for c in json.loads((ROOT / "assets/brand.json").read_text())["palette"]}
    for svg in svgs():
        root = ElementTree.parse(svg).getroot()
        assert root.findtext(f"{SVG_NS}title"), f"{svg}: add a <title>"
        colors = {v.lower() for el in root.iter() for k, v in el.attrib.items()
                  if k in ("fill", "stroke", "stop-color") and v not in ("none", "currentColor")}
        assert colors <= palette, f"{svg}: {sorted(colors - palette)} not in assets/brand.json"


def test_every_png_has_an_svg_source() -> None:
    for png in sorted(ROOT.glob("assets/*.png")) + sorted(ROOT.glob("skills/*/assets/*.png")):
        assert png.with_suffix(".svg").is_file(), f"{png}: no SVG source beside it"


def test_claude_icon_is_a_square_render_of_the_logo() -> None:
    icon = ROOT / read_json(".claude-plugin/plugin.json")["icon"]
    assert icon == ROOT / "assets/icon.png"
    width, height = png_size(icon)
    assert width == height >= 512, f"{icon}: {width}x{height}, need square 512+"
