#!/usr/bin/env python3
"""Versión animada (bucle sin cortes) del wallpaper "Neon Sunset".

Uso: python3 neon-sunset-anim.py salida.webm   (python3-pillow + ffmpeg)
Animación: la rejilla avanza hacia el espectador, las franjas del sol bajan
y las estrellas parpadean. Las capas fijas se pintan una vez; por fotograma
solo se redibuja lo que se mueve.
"""
import math
import os
import random
import subprocess
import sys
import tempfile

from PIL import Image, ImageChops, ImageDraw, ImageFilter

W, H = 1920, 1080
S = 2                          # supersampling de las capas
w, h = W * S, H * S
HORIZON = int(h * 0.62)
FPS, SECONDS = 30, 6
FRAMES = FPS * SECONDS
GRID_RATIO = 1.22              # separación entre líneas horizontales (perspectiva)
GRID_LOOPS = 3                 # la rejilla avanza 3 líneas por bucle
STRIPE_LOOPS = 2
random.seed(44)


def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def gradient(stops, t):
    t = min(max(t, 0), 1)
    for (p0, c0), (p1, c1) in zip(stops, stops[1:]):
        if t <= p1:
            return lerp(c0, c1, (t - p0) / (p1 - p0))
    return stops[-1][1]


def down(im):
    return im.resize((W, H), Image.LANCZOS)


# --- Capa 1: cielo + resplandor (fija) -------------------------------------------
SKY = [(0.00, (14, 6, 38)), (0.30, (52, 16, 92)), (0.58, (156, 32, 128)),
       (0.82, (240, 86, 92)), (1.00, (255, 168, 72))]
sky = Image.new("RGB", (w, h))
d = ImageDraw.Draw(sky)
for y in range(HORIZON):
    d.line([(0, y), (w, y)], fill=gradient(SKY, y / HORIZON))
for y in range(HORIZON, h):
    d.line([(0, y), (w, y)], fill=gradient([(0, (60, 12, 84)), (1, (10, 4, 30))], (y - HORIZON) / (h - HORIZON)))
cx, cy, R = w // 2, int(HORIZON * 0.80), int(h * 0.20)
glow = Image.new("RGB", (w, h))
ImageDraw.Draw(glow).ellipse([cx - R * 1.5, cy - R * 1.5, cx + R * 1.5, cy + R * 1.5], fill=(255, 70, 140))
sky = ImageChops.screen(sky, glow.filter(ImageFilter.GaussianBlur(R * 0.6)))
sky = down(sky)

# Sol (relleno) y su disco; las franjas se recortan por fotograma
sun_fill = Image.new("RGB", (W, H))
sd = ImageDraw.Draw(sun_fill)
scx, scy, sR = cx // S, cy // S, R // S
for y in range(scy - sR, scy + sR):
    sd.line([(0, y), (W, y)], fill=gradient([(0, (255, 236, 120)), (0.5, (255, 140, 70)), (1, (255, 45, 140))], (y - scy + sR) / (2 * sR)))
disc = Image.new("L", (w, h))
ImageDraw.Draw(disc).ellipse([cx - R, cy - R, cx + R, cy + R], fill=255)
disc = disc.resize((W, H), Image.LANCZOS)

# Estrellas (posición fija, brillo animado)
stars = [(random.randrange(W), random.randrange(int(HORIZON / S * 0.55)), random.choice([0.6, 0.8, 1, 1.4]),
          random.uniform(0, 2 * math.pi), random.choice([1, 1, 2])) for _ in range(380)]

# --- Capa 3: montañas + suelo (fija, con alfa) ----------------------------------
mount = Image.new("RGBA", (w, h))
md = ImageDraw.Draw(mount)


def ridge(base, amp, color, seed, edge):
    rnd = random.Random(seed)
    ph = [rnd.uniform(0, 6) for _ in range(3)]
    pts = [(0, HORIZON)]
    for x in range(0, w + 8 * S, 8 * S):
        pts.append((x, base - amp * (0.55 * math.sin(x / w * 7 + ph[0]) + 0.3 * math.sin(x / w * 17 + ph[1])
                                     + 0.15 * math.sin(x / w * 41 + ph[2]))))
    pts.append((w, HORIZON))
    md.polygon(pts, fill=color + (255,))
    md.line(pts[1:-1], fill=edge + (255,), width=3 * S)


ridge(HORIZON - 40 * S, 110 * S, (92, 28, 120), 1, (255, 110, 190))
ridge(HORIZON - 10 * S, 60 * S, (48, 14, 80), 2, (120, 220, 255))
mount = mount.resize((W, H), Image.LANCZOS)

floor = sky.crop((0, HORIZON // S, W, H))     # suelo sin rejilla
haze = Image.new("RGB", (W, H))
ImageDraw.Draw(haze).rectangle([0, HORIZON // S - 6, W, HORIZON // S + 6], fill=(255, 120, 150))
haze = haze.filter(ImageFilter.GaussianBlur(30))

fade = Image.new("L", (W, H))
fd = ImageDraw.Draw(fade)
hz = HORIZON // S
for y in range(hz, H):
    fd.line([(0, y), (W, y)], fill=int(255 * min(1, (y - hz) / ((H - hz) * 0.35))))

# --- Capa 4: palmeras (fija, con alfa) ---------------------------------------------
palms = Image.new("RGBA", (w, h))
pd = ImageDraw.Draw(palms)
COL = (16, 4, 26, 255)


def palm(bx, by, height, lean, scale):
    L, Rr = [], []
    for i in range(41):
        t = i / 40
        x, y = bx + lean * height * t ** 1.8, by - height * t
        half = (26 - 14 * t) * scale * S
        L.append((x - half, y))
        Rr.append((x + half, y))
    pd.polygon(L + Rr[::-1], fill=COL)
    tx, ty = L[-1][0] + 14 * scale * S, L[-1][1]
    for k in range(9):
        ang = math.radians(-170 + k * 22 + random.uniform(-6, 6))
        length = random.uniform(330, 430) * scale * S
        droop = random.uniform(0.6, 1.0)
        up, lo = [], []
        for j in range(31):
            t = j / 30
            px = tx + math.cos(ang) * length * t
            py = ty + math.sin(ang) * length * t + droop * length * 0.55 * t * t
            nx, ny = -math.sin(ang), math.cos(ang)
            wid = 34 * scale * S * math.sin(math.pi * min(t * 1.1, 1)) * (1 - 0.4 * t)
            up.append((px + nx * wid, py + ny * wid))
            lo.append((px - nx * wid * 0.3, py - ny * wid * 0.3))
        pd.polygon(up + lo[::-1], fill=COL)
    pd.ellipse([tx - 30 * scale * S, ty - 20 * scale * S, tx + 30 * scale * S, ty + 30 * scale * S], fill=COL)


palm(int(w * 0.07), h + 40, int(h * 0.82), 0.18, 1.35)
palm(int(w * 0.16), h + 40, int(h * 0.60), 0.30, 1.0)
palm(int(w * 0.93), h + 40, int(h * 0.78), -0.20, 1.3)
palm(int(w * 0.85), h + 40, int(h * 0.52), -0.12, 0.9)
palms = palms.resize((W, H), Image.LANCZOS)


# --- Fotogramas ------------------------------------------------------------------
def frame(t):                       # t en [0, 1)
    img = sky.copy()
    d = ImageDraw.Draw(img)
    for x, y, r, ph, speed in stars:
        a = 0.55 + 0.45 * math.sin(ph + 2 * math.pi * speed * t)
        a *= 1 - y / (hz * 0.55)
        d.ellipse([x - r, y - r, x + r, y + r], fill=lerp((60, 30, 110), (255, 240, 255), max(a, 0)))

    # Sol con franjas que bajan (el hueco crece hacia abajo, como en el estático)
    mask = disc.copy()
    mdraw = ImageDraw.Draw(mask)
    period = 34
    y0 = scy - sR * 0.05
    k = -1 + (STRIPE_LOOPS * t) % 1
    while True:
        y = y0 + k * period
        if y > scy + sR:
            break
        if y + 3 + max(0, y - y0) * 0.12 > y0:
            gap = 3 + max(0, (y - y0)) * 0.12
            mdraw.rectangle([0, max(y, y0), W, y + gap], fill=0)
        k += 1
    img.paste(sun_fill, (0, 0), mask)
    img.paste(mount, (0, 0), mount)
    img.paste(floor, (0, hz))

    # Rejilla en perspectiva avanzando
    grid = Image.new("RGB", (w, h))
    gd = ImageDraw.Draw(grid)
    vx = w / 2
    for i in range(-40, 41):
        gd.line([(vx + i * 14 * S, HORIZON), (vx + i * 260 * S, h)], fill=(255, 60, 200), width=3 * S)
    shift = GRID_RATIO ** (GRID_LOOPS * t)
    z = 1.0 / GRID_RATIO ** 2
    while z / shift < 60:
        zz = z / shift
        if zz >= 1:
            y = HORIZON + (h - HORIZON) / zz
            tt = 1 - (y - HORIZON) / (h - HORIZON)
            gd.line([(0, y), (w, y)], fill=lerp((255, 60, 200), (90, 220, 255), tt),
                    width=max(2, int(4 * S * (1 - tt) + 1)))
        z *= GRID_RATIO
    grid = grid.resize((W, H), Image.LANCZOS)
    grid = ImageChops.screen(grid, grid.filter(ImageFilter.GaussianBlur(10)))
    img.paste(ImageChops.screen(img, grid), (0, 0), fade)

    img = ImageChops.screen(img, haze)
    img.paste(palms, (0, 0), palms)
    return img


out = sys.argv[1] if len(sys.argv) > 1 else "neon-sunset.webm"
with tempfile.TemporaryDirectory() as tmp:
    for n in range(FRAMES):
        frame(n / FRAMES).save(os.path.join(tmp, f"{n:04d}.png"), compress_level=1)
        if n % 30 == 0:
            print(f"fotograma {n}/{FRAMES}", flush=True)
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-framerate", str(FPS), "-i", os.path.join(tmp, "%04d.png"),
                    "-c:v", "libvpx-vp9", "-b:v", "0", "-crf", "30", "-row-mt", "1", "-pix_fmt", "yuv420p",
                    "-an", out], check=True)
print(out)
