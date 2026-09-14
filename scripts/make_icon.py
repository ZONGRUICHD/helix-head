"""Reproducible original geometric Helix app icon (requires Pillow)."""
from pathlib import Path
import json
import math
from PIL import Image, ImageDraw

root = Path(__file__).resolve().parents[1]
dest = root / 'HelixHead' / 'Assets.xcassets' / 'AppIcon.appiconset'
dest.mkdir(parents=True, exist_ok=True)
size = 1024
im = Image.new('RGB', (size, size))
pixels = im.load()
for y in range(size):
    for x in range(size):
        glow = max(0, 1 - math.hypot(x - 220, y - 120) / 1150)
        pixels[x, y] = (int(12 + 47 * glow), int(24 + 54 * glow), int(19 + 44 * glow))
draw = ImageDraw.Draw(im)
for i in range(48):
    angle = i * math.tau / 48
    radius = 280
    twist = 0.20
    p1 = (512 + math.cos(angle) * radius, 512 + math.sin(angle) * radius)
    p2 = (512 + math.cos(angle + twist) * 360, 512 + math.sin(angle + twist) * 360)
    shade = int(180 + 65 * (0.5 + 0.5 * math.cos(angle + 1)))
    draw.line([p1, p2], fill=(shade, min(255, shade + 10), shade), width=12)
# Minimal head silhouette, original vector geometry.
draw.ellipse((388, 278, 625, 600), fill=(226, 235, 227))
draw.polygon([(595, 389), (671, 467), (613, 477), (599, 568), (543, 612), (545, 690), (441, 690), (442, 540)], fill=(226, 235, 227))
draw.ellipse((424, 432, 466, 493), fill=(105, 129, 114))
draw.rounded_rectangle((558, 410, 585, 420), radius=5, fill=(27, 46, 34))
im.save(dest / 'AppIcon.png')
(dest / 'Contents.json').write_text(json.dumps({'images': [{'filename': 'AppIcon.png', 'idiom': 'universal', 'platform': 'ios', 'size': '1024x1024'}], 'info': {'author': 'xcode', 'version': 1}}, indent=2) + '\n')
(dest.parent / 'Contents.json').write_text('{"info":{"author":"xcode","version":1}}\n')
