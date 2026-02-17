#!/usr/bin/env python3
"""Recolor iTerm2 icon PNGs from green accent to teal/blue accent.

Shifts hue of green-ish pixels (~80-160 degrees) to teal/blue (~180-200 degrees).
Used to visually differentiate the yiTerm2 fork from upstream iTerm2.

Usage:
    python3 tools/recolor_icon.py
"""

import os
import colorsys
from PIL import Image

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
APPICON_DIR = os.path.join(REPO_ROOT, "images", "AppIcon")

# PNGs to recolor (relative to images/AppIcon/)
ICON_PNGS = [
    # Root-level cursor and dollar/symbol PNGs
    "cursor.png",
    "cursor@2x.png",
    "dollar.png",
    "dollar@2x.png",
    # Release .icon assets
    "iTerm2 App Icon for Release.icon/Assets/cursor@2x 4.png",
    "iTerm2 App Icon for Release.icon/Assets/dollar@2x 2.png",
    # Beta .icon assets
    "iTerm2 App Icon for Beta.icon/Assets/cursor@2x 4.png",
    "iTerm2 App Icon for Beta.icon/Assets/b.png",
    # Nightly .icon assets
    "iTerm2 App Icon for Nightly.icon/Assets/cursor@2x 4.png",
    "iTerm2 App Icon for Nightly.icon/Assets/dollar@2x 2.png",
    "iTerm2 App Icon for Nightly.icon/Assets/a.png",
]

# Composite preview images to also recolor
COMPOSITE_PNGS = [
    "release.png",
    "beta.png",
    "nightly.png",
]


def shift_green_to_teal(image_path):
    """Shift green hues to teal/blue in a PNG image, preserving alpha."""
    img = Image.open(image_path).convert("RGBA")
    pixels = img.load()
    width, height = img.size

    for y in range(height):
        for x in range(width):
            r, g, b, a = pixels[x, y]
            if a == 0:
                continue

            # Convert to HSV (0-1 range)
            h, s, v = colorsys.rgb_to_hsv(r / 255.0, g / 255.0, b / 255.0)
            hue_deg = h * 360

            # Shift green range (80-160 degrees) to teal (185-200 degrees)
            if 60 <= hue_deg <= 170 and s > 0.15:
                # Map the green range proportionally to teal range
                green_frac = (hue_deg - 60) / (170 - 60)
                new_hue_deg = 185 + green_frac * 15  # 185-200 degree range
                h = new_hue_deg / 360.0

                nr, ng, nb = colorsys.hsv_to_rgb(h, s, v)
                pixels[x, y] = (int(nr * 255), int(ng * 255), int(nb * 255), a)

    img.save(image_path)
    print(f"  Recolored: {os.path.relpath(image_path, REPO_ROOT)}")


def main():
    print("Recoloring icon PNGs: green -> teal/blue")
    print()

    all_pngs = ICON_PNGS + COMPOSITE_PNGS
    for rel_path in all_pngs:
        full_path = os.path.join(APPICON_DIR, rel_path)
        if os.path.exists(full_path):
            shift_green_to_teal(full_path)
        else:
            print(f"  SKIPPED (not found): {rel_path}")

    print()
    print("Done. Verify visually by building the app.")


if __name__ == "__main__":
    main()
