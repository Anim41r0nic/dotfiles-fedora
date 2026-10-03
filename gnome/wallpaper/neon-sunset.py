#!/usr/bin/env python3
"""Genera el wallpaper "Neon Sunset" (synthwave, tonos ámbar/rosa/violeta).

Uso: python3 neon-sunset.py [salida.png]   (solo necesita python3-pillow)
Se renderiza a 2x y se reduce para suavizar bordes.
"""
import math
import random
import sys

from PIL import Image, ImageChops, ImageDraw, ImageFilter

W, H = 3840, 2160          # salida final (4K, se ve nítido también en 1080p)
S = 2                      # supersampling
w, h = W * S, H * S
HORIZON = int(h * 0.62)
random.seed(44)


def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def gradient(stops, t):
    for (p0, c0), (p1, c1) in zip(stops, stops[1:]):
        if t <= p1:
            return lerp(c0, c1, (t - p0) / (p1 - p0))
    return stops[-1][1]


# --- Cielo -------------------------------------------------------------------
SKY = [
    (0.00, (14, 6, 38)),      # azul noche
    (0.30, (52, 16, 92)),     # violeta
    (0.58, (156, 32, 128)),   # magenta
    (0.82, (240, 86, 92)),    # coral
    (1.00, (255, 168, 72)),   # ámbar en el horizonte
]
img = Image.new("RGB", (w, h))
d = ImageDraw.Draw(img)
for y in range(HORIZON):
    d.line([(0, y), (w, y)], fill=gradient(SKY, y / HORIZON))

# Estrellas en la parte alta
for _ in range(700):
    x, y = random.randrange(w), random.randrange(int(HORIZON * 0.55))
    r = random.choice([1, 1, 2, 2, 3])
    a = int(255 * (1 - y / (HORIZON * 0.55)) * random.uniform(0.3, 1))
    d.ellipse([x - r, y - r, x + r, y + r], fill=lerp((60, 30, 110), (255, 240, 255), a / 255))

# --- Sol con franjas -----------------------------------------------------------
cx, cy, R = w // 2, int(HORIZON * 0.80), int(h * 0.20)
glow = Image.new("RGB", (w, h))
ImageDraw.Draw(glow).ellipse([cx - R * 1.5, cy - R * 1.5, cx + R * 1.5, cy + R * 1.5], fill=(255, 70, 140))
img = ImageChops.screen(img, glow.filter(ImageFilter.GaussianBlur(R * 0.6)))

sun = Image.new("RGB", (w, h))
sd = ImageDraw.Draw(sun)
for y in range(cy - R, cy + R):
    sd.line([(0, y), (w, y)], fill=gradient([(0, (255, 236, 120)), (0.5, (255, 140, 70)), (1, (255, 45, 140))], (y - cy + R) / (2 * R)))
mask = Image.new("L", (w, h))
md = ImageDraw.Draw(mask)
md.ellipse([cx - R, cy - R, cx + R, cy + R], fill=255)
# franjas horizontales cada vez más gruesas hacia abajo
y, gap = cy - R * 0.05, 6 * S
while y < cy + R:
    md.rectangle([0, y, w, y + gap], fill=0)
    y += gap + 28 * S
    gap += 5 * S
img.paste(sun, (0, 0), mask)
d = ImageDraw.Draw(img)

# --- Montañas lejanas -----------------------------------------------------------
def ridge(base, amp, color, seed, edge=None):
    rnd = random.Random(seed)
    pts, x = [(0, HORIZON)], 0
    phase = [rnd.uniform(0, 6) for _ in range(3)]
    while x <= w:
        yv = base - amp * (0.55 * math.sin(x / w * 7 + phase[0]) + 0.3 * math.sin(x / w * 17 + phase[1])
                           + 0.15 * math.sin(x / w * 41 + phase[2]))
        yv -= amp * 0.9 * max(0, 1 - abs(x - w / 2) / (w * 0.18)) * 0  # valle central despejado
        pts.append((x, yv))
        x += 8 * S
    pts.append((w, HORIZON))
    d.polygon(pts, fill=color)
    if edge:
        d.line(pts[1:-1], fill=edge, width=3 * S)

ridge(HORIZON - 40 * S, 110 * S, (92, 28, 120), 1, edge=(255, 110, 190))
ridge(HORIZON - 10 * S, 60 * S, (48, 14, 80), 2, edge=(120, 220, 255))

# --- Suelo con rejilla neón en perspectiva ---------------------------------------
for y in range(HORIZON, h):
    d.line([(0, y), (w, y)], fill=gradient([(0, (60, 12, 84)), (1, (10, 4, 30))], (y - HORIZON) / (h - HORIZON)))

grid = Image.new("RGB", (w, h))
gd = ImageDraw.Draw(grid)
vx = w / 2
for i in range(-40, 41):                       # líneas de fuga
    gd.line([(vx + i * 14 * S, HORIZON), (vx + i * 260 * S, h)], fill=(255, 60, 200), width=3 * S)
z = 1.0
while z < 60:                                  # líneas horizontales
    y = HORIZON + (h - HORIZON) / z
    t = 1 - (y - HORIZON) / (h - HORIZON)
    gd.line([(0, y), (w, y)], fill=lerp((255, 60, 200), (90, 220, 255), t), width=max(2, int(4 * S * (1 - t) + 1)))
    z *= 1.22
fade = Image.new("L", (w, h))
fd = ImageDraw.Draw(fade)
for y in range(HORIZON, h):
    fd.line([(0, y), (w, y)], fill=int(255 * min(1, (y - HORIZON) / ((h - HORIZON) * 0.35))))
grid_glow = ImageChops.screen(grid, grid.filter(ImageFilter.GaussianBlur(10 * S)))
img.paste(ImageChops.screen(img, grid_glow), (0, 0), fade)

# Reflejo del sol en el horizonte
haze = Image.new("RGB", (w, h))
ImageDraw.Draw(haze).rectangle([0, HORIZON - 6 * S, w, HORIZON + 6 * S], fill=(255, 120, 150))
img = ImageChops.screen(img, haze.filter(ImageFilter.GaussianBlur(30 * S)))
d = ImageDraw.Draw(img)

# --- Palmeras (siluetas) ---------------------------------------------------------
def palm(bx, by, height, lean, scale, color=(16, 4, 26)):
    pts_l, pts_r = [], []
    steps = 40
    for i in range(steps + 1):
        t = i / steps
        x = bx + lean * height * t ** 1.8
        y = by - height * t
        half = (26 - 14 * t) * scale * S
        pts_l.append((x - half, y))
        pts_r.append((x + half, y))
    d.polygon(pts_l + pts_r[::-1], fill=color)
    tx, ty = pts_l[-1][0] + 14 * scale * S, pts_l[-1][1]
    for k in range(9):                         # hojas: curvas con forma de lanza
        ang = math.radians(-170 + k * 22 + random.uniform(-6, 6))
        length = random.uniform(330, 430) * scale * S
        droop = random.uniform(0.6, 1.0)
        upper, lower = [], []
        for j in range(31):
            t = j / 30
            px = tx + math.cos(ang) * length * t
            py = ty + math.sin(ang) * length * t + droop * length * 0.55 * t * t
            nx, ny = -math.sin(ang), math.cos(ang)
            wid = 34 * scale * S * math.sin(math.pi * min(t * 1.1, 1)) * (1 - 0.4 * t)
            upper.append((px + nx * wid, py + ny * wid))
            lower.append((px - nx * wid * 0.3, py - ny * wid * 0.3))
        d.polygon(upper + lower[::-1], fill=color)
    d.ellipse([tx - 30 * scale * S, ty - 20 * scale * S, tx + 30 * scale * S, ty + 30 * scale * S], fill=color)

palm(int(w * 0.07), h + 40, int(h * 0.82), 0.18, 1.35)
palm(int(w * 0.16), h + 40, int(h * 0.60), 0.30, 1.0)
palm(int(w * 0.93), h + 40, int(h * 0.78), -0.20, 1.3)
palm(int(w * 0.85), h + 40, int(h * 0.52), -0.12, 0.9)

# --- Salida ----------------------------------------------------------------------
out = sys.argv[1] if len(sys.argv) > 1 else "neon-sunset.png"
img.resize((W, H), Image.LANCZOS).save(out, optimize=True)
print(out)
