"""Textures of the Halloween edition (Client/Images), drawn here with PIL and numpy.

- moon.png / moon_blood.png: the harvest moon with a witch flying across it on her broom, and its blood-red
  version for the Witching Hour (Sky.SetMoonTexture, Client/Sky.lua)
- bat_1.png / bat_2.png: a bat with its wings up and down (the flapping bats round the dome, Client/Bats.lua)
- witch.png / witch_left.png: the witch on her broom alone, facing right and left (crossing the sky now and then)
- leaves_1.png / leaves_2.png: fallen autumn leaves, decals on the pitch (Client/Arena.lua)
- ground.png: dark graveyard earth, tiling, for the ground round the arena

Usage: python tools/make_textures.py [output folder, default Client/Images]
"""
import math
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

OUT_DIR = sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(__file__), "..", "Client", "Images")
RNG = np.random.default_rng(1031)


def save(img, name):
    os.makedirs(OUT_DIR, exist_ok=True)
    img.save(os.path.join(OUT_DIR, name), optimize=True)
    print(name, img.size)


def tiling_noise(size, scale, seed):
    """Smooth noise that tiles: white noise low-passed in the frequency domain."""
    rng = np.random.default_rng(seed)
    spectrum = np.fft.fft2(rng.standard_normal((size, size)))
    fy = np.fft.fftfreq(size)[:, None]
    fx = np.fft.fftfreq(size)[None, :]
    spectrum *= np.exp(-(fx ** 2 + fy ** 2) * (scale ** 2))
    n = np.real(np.fft.ifft2(spectrum))
    return (n - n.min()) / (n.max() - n.min())


# --- Silhouettes, drawn in a 512 x 256 box (x right, y down), scaled by `s` round an origin ----------------------

def witch_shapes(draw, ox, oy, s, fill):
    def P(points):
        return [(ox + x * s, oy + y * s) for x, y in points]
    # The broom: a long crooked stick, its twigs fanning out behind
    draw.line(P([(40, 172), (250, 158), (470, 136)]), fill=fill, width=max(1, int(9 * s)))
    draw.polygon(P([(70, 166), (-10, 128), (0, 150), (-22, 160), (0, 175), (-16, 196), (8, 192), (-4, 214), (72, 180)]), fill=fill)
    # The cloak billowing back over the broom, its hem in tatters
    draw.polygon(P([(318, 92), (282, 96), (230, 108), (175, 118), (120, 112), (150, 132), (110, 142), (160, 150), (138, 166),
                    (205, 160), (250, 164), (300, 162), (338, 150), (344, 118)]), fill=fill)
    # Her back upright over the broom
    draw.polygon(P([(316, 84), (348, 94), (346, 150), (298, 162), (292, 118)]), fill=fill)
    # Leg and pointed boot hanging under the broom
    draw.polygon(P([(300, 150), (322, 186), (360, 196), (378, 192), (352, 182), (330, 160)]), fill=fill)
    # Arm reaching to the stick
    draw.polygon(P([(330, 100), (372, 130), (390, 142), (382, 150), (360, 140), (322, 116)]), fill=fill)
    # Head, a hooked nose and a pointy chin
    cx, cy, r = 338, 74, 19
    draw.ellipse(P([(cx - r, cy - r), (cx + r, cy + r)]), fill=fill)
    draw.polygon(P([(352, 66), (384, 80), (354, 82)]), fill=fill)
    draw.polygon(P([(344, 88), (360, 104), (336, 94)]), fill=fill)
    # Hair streaming back
    draw.polygon(P([(324, 70), (290, 78), (262, 98), (296, 90), (270, 112), (306, 98), (320, 94)]), fill=fill)
    # The hat: a wide brim and a crooked cone, its tip bent back
    draw.polygon(P([(292, 62), (386, 50), (388, 56), (296, 70)]), fill=fill)
    draw.polygon(P([(312, 62), (362, 54), (346, 28), (330, 6), (304, -4), (290, 6), (318, 12), (326, 30)]), fill=fill)


def bat_shapes(draw, ox, oy, s, fill, wings_up):
    def P(points):
        return [(ox + x * s, oy + (y + 40) * s) for x, y in points]
    lift = -85 if wings_up else 75
    for side in (-1, 1):
        def W(x, y):
            return (256 + side * x, y)
        # Wing: from the shoulder out to the tip, then back along a scalloped trailing edge
        tip_y = 60 + lift
        points = [W(10, 96), W(60, 70 + lift * 0.4), W(120, 58 + lift * 0.7), W(190, tip_y), W(236, tip_y + 18 - lift * 0.1),
                  W(210, 112 + lift * 0.45), W(178, 100 + lift * 0.5), W(150, 128 + lift * 0.3), W(118, 112 + lift * 0.3),
                  W(88, 136 + lift * 0.15), W(58, 118 + lift * 0.1), W(28, 132)]
        draw.polygon(P(points), fill=fill)
        # Ear
        draw.polygon(P([W(6, 82), W(18, 54), W(24, 84)]), fill=fill)
    draw.ellipse(P([(236, 74), (276, 150)]), fill=fill)     # body
    draw.ellipse(P([(238, 68), (274, 100)]), fill=fill)     # head


def silhouette(width, height, draw_fn, supersample=4, blur=0.0):
    big = Image.new("L", (width * supersample, height * supersample), 0)
    draw_fn(ImageDraw.Draw(big), supersample)
    mask = big.resize((width, height), Image.LANCZOS)
    if blur:
        mask = mask.filter(ImageFilter.GaussianBlur(blur))
    img = Image.new("RGBA", (width, height), (8, 4, 10, 0))
    img.putalpha(mask)
    return img


def moon(color_inner, color_outer, maria_tint, size=1024):
    """A full moon disc on transparency, craters and a witch crossing it. maria_tint: how much the dark
    patches darken each channel."""
    y, x = np.mgrid[0:size, 0:size].astype(float)
    c = size / 2
    r = np.hypot(x - c, y - c) / (size * 0.47)
    disc = np.clip((1 - r) * size * 0.02, 0, 1)
    rgb = np.zeros((size, size, 3))
    k = np.clip(r, 0, 1)[..., None] ** 1.6
    rgb[:] = np.array(color_inner) * (1 - k) + np.array(color_outer) * k
    # Maria and craters: darker blotches from tiling noise, a few round craters with bright rims
    blotch = tiling_noise(size, 60, 7) * 0.6 + tiling_noise(size, 18, 8) * 0.4
    maria = 0.32 * np.clip((blotch - 0.45) * 3, 0, 1)
    rgb *= 1 - maria[..., None] * np.array(maria_tint)
    rng = np.random.default_rng(3)
    for _ in range(26):
        cx, cy = rng.uniform(size * 0.15, size * 0.85, 2)
        cr = rng.uniform(size * 0.012, size * 0.05)
        d = np.hypot(x - cx, y - cy) / cr
        rgb *= (1 - 0.18 * np.clip(1 - d, 0, 1) ** 0.5)[..., None]
        rgb *= (1 + 0.12 * np.exp(-((d - 1.0) / 0.12) ** 2))[..., None]
    rgb = np.clip(rgb, 0, 1)
    img = Image.fromarray((rgb * 255).astype(np.uint8), "RGB").convert("RGBA")
    img.putalpha(Image.fromarray((disc * 255).astype(np.uint8), "L"))
    # The witch on her broom across the lower half, two bats above her
    sil = silhouette(size, size, lambda d, s: (witch_shapes(d, size * 0.2 * s, size * 0.48 * s, 1.15 * s, 255),
                                              bat_shapes(d, size * 0.52 * s, size * 0.2 * s, 0.32 * s, 255, True),
                                              bat_shapes(d, size * 0.68 * s, size * 0.3 * s, 0.24 * s, 255, False)))
    dark = Image.new("RGBA", (size, size), (16, 6, 10, 255))
    mask = Image.fromarray(np.minimum(np.array(sil.getchannel("A")), (disc * 255).astype(np.uint8)), "L")
    img.paste(dark, (0, 0), mask)
    return img


def leaves(size, count, seed):
    """Autumn leaves scattered on transparency: maple-like stars and plain ovals, with their veins."""
    ss = 2
    img = Image.new("RGBA", (size * ss, size * ss), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    rng = np.random.default_rng(seed)
    palette = [(196, 72, 18), (222, 116, 24), (160, 40, 22), (120, 62, 28), (214, 160, 40), (96, 44, 30)]
    for _ in range(count):
        cx, cy = rng.uniform(0.08, 0.92, 2) * size * ss
        r = rng.uniform(0.025, 0.06) * size * ss
        a0 = rng.uniform(0, 2 * math.pi)
        col = palette[rng.integers(len(palette))]
        shade = rng.uniform(0.75, 1.1)
        fill = tuple(int(min(255, ch * shade)) for ch in col) + (255,)
        if rng.random() < 0.6:
            pts = []
            for k in range(10):          # five lobes
                a = a0 + k * math.pi / 5
                rr = r * (1.0 if k % 2 == 0 else rng.uniform(0.42, 0.55))
                pts.append((cx + math.cos(a) * rr, cy + math.sin(a) * rr))
            draw.polygon(pts, fill=fill)
        else:                            # an oval leaf along a0
            pts = []
            for t in np.linspace(0, 2 * math.pi, 24, endpoint=False):
                u, v = math.cos(t) * r, math.sin(t) * r * 0.42
                pts.append((cx + u * math.cos(a0) - v * math.sin(a0), cy + u * math.sin(a0) + v * math.cos(a0)))
            draw.polygon(pts, fill=fill)
        vein = tuple(int(ch * 0.55) for ch in col) + (255,)
        draw.line([(cx - math.cos(a0) * r * 0.9, cy - math.sin(a0) * r * 0.9), (cx + math.cos(a0) * r * 0.9, cy + math.sin(a0) * r * 0.9)],
                  fill=vein, width=ss * 2)
    return img.resize((size, size), Image.LANCZOS)


def ground(size=512):
    """Dark earth with patches of dead grass and moss, tiling."""
    a = tiling_noise(size, 40, 11)
    b = tiling_noise(size, 10, 12)
    c = tiling_noise(size, 3, 13)
    earth = np.array([0.16, 0.12, 0.10])
    grass = np.array([0.13, 0.15, 0.08])
    moss = np.array([0.08, 0.12, 0.08])
    mix = np.clip((a - 0.4) * 2.5, 0, 1)[..., None]
    rgb = earth * (1 - mix) + grass * mix
    rgb = rgb * (1 - 0.5 * np.clip((b - 0.6) * 3, 0, 1))[..., None] + moss * 0.5 * np.clip((b - 0.6) * 3, 0, 1)[..., None]
    rgb *= (0.75 + 0.5 * c)[..., None]
    return Image.fromarray((np.clip(rgb, 0, 1) * 255).astype(np.uint8), "RGB")


if __name__ == "__main__":
    save(moon((1.0, 0.78, 0.38), (0.93, 0.45, 0.12), (0.7, 0.9, 1.0)), "moon.png")
    save(moon((0.95, 0.25, 0.16), (0.55, 0.04, 0.04), (0.8, 1.0, 1.0)), "moon_blood.png")
    save(silhouette(512, 256, lambda d, s: bat_shapes(d, 0, 0, s, 255, True)), "bat_1.png")
    save(silhouette(512, 256, lambda d, s: bat_shapes(d, 0, 0, s, 255, False)), "bat_2.png")
    witch = silhouette(512, 256, lambda d, s: witch_shapes(d, 24 * s, 34 * s, 0.9 * s, 255))
    save(witch, "witch.png")
    save(witch.transpose(Image.FLIP_LEFT_RIGHT), "witch_left.png")
    save(leaves(512, 46, 21), "leaves_1.png")
    save(leaves(512, 34, 22), "leaves_2.png")
    save(ground(), "ground.png")
