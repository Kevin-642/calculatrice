from __future__ import annotations

import math
import os
import random
import subprocess
import sys
import wave
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageEnhance, ImageFilter, ImageFont


ROOT = Path(__file__).resolve().parents[1]
WIDTH, HEIGHT = 720, 1280
FPS = 24
DURATION = 20
FRAMES = FPS * DURATION

SCREENSHOT = ROOT / "build" / "calculatrice_compact_a.png"
LOGO = ROOT / "assets" / "brand" / "logo.png"
SPACE = ROOT / "space.jpeg"
OUTPUT_DIR = ROOT / "store_assets"
SILENT_VIDEO = OUTPUT_DIR / "calculatrice_cosmique_promo_silent.mp4"
AUDIO = OUTPUT_DIR / "calculatrice_cosmique_promo_audio.wav"
OUTPUT = OUTPUT_DIR / "calculatrice_cosmique_promo_20s.mp4"
COVER = OUTPUT_DIR / "calculatrice_cosmique_promo_cover.png"

FONT_REGULAR = Path(os.environ.get("WINDIR", "C:/Windows")) / "Fonts" / "segoeui.ttf"
FONT_SEMIBOLD = Path(os.environ.get("WINDIR", "C:/Windows")) / "Fonts" / "seguisb.ttf"
FONT_BOLD = Path(os.environ.get("WINDIR", "C:/Windows")) / "Fonts" / "segoeuib.ttf"

GOLD = (255, 222, 163)
WHITE = (246, 249, 255)
CYAN = (111, 185, 255)
INK = (4, 10, 30)


def font(size: int, bold: bool = False, semibold: bool = False) -> ImageFont.FreeTypeFont:
    path = FONT_BOLD if bold else FONT_SEMIBOLD if semibold else FONT_REGULAR
    return ImageFont.truetype(str(path), size)


def clamp(value: float, low: float = 0.0, high: float = 1.0) -> float:
    return max(low, min(high, value))


def ease(value: float) -> float:
    value = clamp(value)
    return value * value * (3 - 2 * value)


def fade_window(t: float, start: float, end: float, fade: float = 0.45) -> float:
    return clamp((t - start) / fade) * clamp((end - t) / fade)


def cover(image: Image.Image, size: tuple[int, int]) -> Image.Image:
    scale = max(size[0] / image.width, size[1] / image.height)
    resized = image.resize((round(image.width * scale), round(image.height * scale)), Image.Resampling.LANCZOS)
    x = (resized.width - size[0]) // 2
    y = (resized.height - size[1]) // 2
    return resized.crop((x, y, x + size[0], y + size[1]))


def alpha_scaled(image: Image.Image, alpha: float) -> Image.Image:
    result = image.copy()
    result.putalpha(result.getchannel("A").point(lambda p: round(p * clamp(alpha))))
    return result


def draw_centered(draw: ImageDraw.ImageDraw, text: str, y: float, text_font: ImageFont.FreeTypeFont,
                  fill: tuple[int, ...], stroke_width: int = 0, stroke_fill: tuple[int, ...] | None = None) -> None:
    box = draw.textbbox((0, 0), text, font=text_font, stroke_width=stroke_width)
    draw.text(((WIDTH - (box[2] - box[0])) / 2, y), text, font=text_font, fill=fill,
              stroke_width=stroke_width, stroke_fill=stroke_fill)


def glass_chip(text: str, width: int, text_size: int = 31) -> Image.Image:
    chip = Image.new("RGBA", (width, 72), (0, 0, 0, 0))
    shadow = Image.new("RGBA", chip.size, (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle((5, 6, width - 5, 66), radius=28, fill=(0, 0, 0, 150))
    shadow = shadow.filter(ImageFilter.GaussianBlur(10))
    chip.alpha_composite(shadow)
    d = ImageDraw.Draw(chip)
    d.rounded_rectangle((4, 3, width - 4, 63), radius=28, fill=(8, 18, 48, 225), outline=(118, 182, 255, 180), width=2)
    bbox = d.textbbox((0, 0), text, font=font(text_size, semibold=True))
    d.text(((width - (bbox[2] - bbox[0])) / 2, 12), text, font=font(text_size, semibold=True), fill=WHITE)
    return chip


def prepare_assets() -> tuple[Image.Image, Image.Image, Image.Image]:
    background = cover(Image.open(SPACE).convert("RGB"), (WIDTH, HEIGHT))
    background = ImageEnhance.Color(background).enhance(1.18)
    background = ImageEnhance.Brightness(background).enhance(0.42).convert("RGBA")

    logo = Image.open(LOGO).convert("RGBA")
    screenshot = Image.open(SCREENSHOT).convert("RGBA")
    phone_width = 610
    screenshot = screenshot.resize((phone_width, round(screenshot.height * phone_width / screenshot.width)), Image.Resampling.LANCZOS)
    return background, logo, screenshot


BACKGROUND, LOGO_IMAGE, PHONE = prepare_assets()
RANDOM = random.Random(642)
STARS = [
    (RANDOM.randrange(WIDTH), RANDOM.randrange(HEIGHT), RANDOM.uniform(0.45, 1.8), RANDOM.random() * math.tau)
    for _ in range(115)
]


def cosmic_background(t: float) -> Image.Image:
    drift = int(14 * math.sin(t * 0.16))
    canvas = Image.new("RGBA", (WIDTH, HEIGHT), INK + (255,))
    canvas.alpha_composite(BACKGROUND, (drift, 0))
    if drift > 0:
        canvas.alpha_composite(BACKGROUND.crop((WIDTH - drift, 0, WIDTH, HEIGHT)), (0, 0))
    elif drift < 0:
        canvas.alpha_composite(BACKGROUND.crop((0, 0, -drift, HEIGHT)), (WIDTH + drift, 0))

    glow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    pulse = 0.72 + 0.18 * math.sin(t * 0.8)
    gd.ellipse((90, 360, 650, 920), fill=(39, 92, 230, round(44 * pulse)))
    glow = glow.filter(ImageFilter.GaussianBlur(110))
    canvas.alpha_composite(glow)

    d = ImageDraw.Draw(canvas)
    for x, y, radius, phase in STARS:
        yy = (y + int(t * (6 + radius * 4))) % HEIGHT
        brightness = round(110 + 130 * (0.5 + 0.5 * math.sin(t * 2.3 + phase)))
        r = max(1, round(radius))
        d.ellipse((x - r, yy - r, x + r, yy + r), fill=(220, 236, 255, brightness))
    return canvas


def phone_layer(t: float, scene_start: float, scene_end: float, zoom: float = 1.0, y_offset: int = 70) -> tuple[Image.Image, int, int, float]:
    alpha = fade_window(t, scene_start, scene_end)
    entrance = ease((t - scene_start) / 0.75)
    scale = zoom * (0.94 + 0.06 * entrance)
    phone = PHONE.resize((round(PHONE.width * scale), round(PHONE.height * scale)), Image.Resampling.LANCZOS)
    x = (WIDTH - phone.width) // 2
    y = y_offset + round((1 - entrance) * 95)

    shadow = Image.new("RGBA", (phone.width + 60, phone.height + 60), (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.rounded_rectangle((30, 20, phone.width + 30, phone.height + 40), radius=42, fill=(0, 0, 0, round(180 * alpha)))
    shadow = shadow.filter(ImageFilter.GaussianBlur(22))
    layer = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
    layer.alpha_composite(shadow, (x - 30, y - 20))
    layer.alpha_composite(alpha_scaled(phone, alpha), (x, y))
    return layer, x, y, scale


def overlay_display(layer: Image.Image, x: int, y: int, scale: float, expression: str, result: str, alpha: float = 1.0) -> None:
    # Coordinates map the real display panel in calculatrice_compact_a.png.
    sx = PHONE.width / 945
    left = x + round(31 * sx * scale)
    top = y + round(292 * sx * scale)
    right = x + round(914 * sx * scale)
    bottom = y + round(529 * sx * scale)
    d = ImageDraw.Draw(layer)
    d.rounded_rectangle((left, top, right, bottom), radius=30, fill=(12, 21, 50, round(246 * alpha)), outline=(91, 147, 230, round(150 * alpha)), width=2)
    expr_font = font(max(18, round(31 * scale)), semibold=True)
    result_font = font(max(34, round(66 * scale)), bold=True)
    if expression:
        d.text((right - 24, top + 23), expression, font=expr_font, fill=CYAN + (round(255 * alpha),), anchor="ra")
    d.text((right - 24, bottom - 25), result, font=result_font, fill=GOLD + (round(255 * alpha),), anchor="rs")


def opening_scene(canvas: Image.Image, t: float) -> None:
    alpha = fade_window(t, 0, 3.3, 0.65)
    logo_size = round(330 * (0.82 + 0.18 * ease(t / 1.2)))
    logo = LOGO_IMAGE.resize((logo_size, logo_size), Image.Resampling.LANCZOS)
    glow = Image.new("RGBA", (logo_size + 100, logo_size + 100), (0, 0, 0, 0))
    ImageDraw.Draw(glow).ellipse((50, 50, logo_size + 50, logo_size + 50), fill=(91, 132, 255, round(105 * alpha)))
    glow = glow.filter(ImageFilter.GaussianBlur(42))
    canvas.alpha_composite(glow, ((WIDTH - glow.width) // 2, 180))
    canvas.alpha_composite(alpha_scaled(logo, alpha), ((WIDTH - logo_size) // 2, 230))
    d = ImageDraw.Draw(canvas)
    draw_centered(d, "CALCULATRICE", 615, font(46, bold=True), WHITE + (round(255 * alpha),), 2, (12, 21, 55, 210))
    draw_centered(d, "COSMIQUE", 670, font(60, bold=True), GOLD + (round(255 * alpha),), 2, (12, 21, 55, 220))
    draw_centered(d, "Le calcul entre dans une autre dimension", 760, font(25, semibold=True), WHITE + (round(235 * alpha),))


def calculation_scene(canvas: Image.Image, t: float) -> None:
    layer, x, y, scale = phone_layer(t, 2.7, 8.1, y_offset=60)
    local = t - 2.7
    if local < 1.15:
        expression, result = "", "0"
    elif local < 1.75:
        expression, result = "125", "125"
    elif local < 2.25:
        expression, result = "125 ×", "125"
    elif local < 2.85:
        expression, result = "125 × 8", "125"
    else:
        expression, result = "125 × 8", "1 000"
    overlay_display(layer, x, y, scale, expression, result, fade_window(t, 2.9, 8.1))
    canvas.alpha_composite(layer)
    chip = glass_chip("Rapide et intuitive", 390)
    canvas.alpha_composite(alpha_scaled(chip, fade_window(t, 3.1, 7.9)), ((WIDTH - chip.width) // 2, 75))


def science_scene(canvas: Image.Image, t: float) -> None:
    layer, x, y, scale = phone_layer(t, 7.7, 13.1, y_offset=45)
    local = t - 7.7
    expression = "sin(π ÷ 2)" if local > 1.1 else "sin("
    result = "1" if local > 2.0 else "0"
    overlay_display(layer, x, y, scale, expression, result, fade_window(t, 7.9, 13.0))
    canvas.alpha_composite(layer)
    chip = glass_chip("Puissante en sciences", 430)
    canvas.alpha_composite(alpha_scaled(chip, fade_window(t, 8.0, 12.9)), ((WIDTH - chip.width) // 2, 70))

    if t > 10.25:
        badge_alpha = fade_window(t, 10.25, 13.0, 0.35)
        badge = glass_chip("Σ  Fonctions scientifiques", 470, 27)
        canvas.alpha_composite(alpha_scaled(badge, badge_alpha), ((WIDTH - badge.width) // 2, 980))


def features_scene(canvas: Image.Image, t: float) -> None:
    alpha = fade_window(t, 12.7, 16.8)
    layer, _, _, _ = phone_layer(t, 12.7, 16.8, zoom=1.08, y_offset=-190)
    canvas.alpha_composite(layer)
    veil = Image.new("RGBA", (WIDTH, HEIGHT), (2, 8, 27, round(70 * alpha)))
    canvas.alpha_composite(veil)
    title = glass_chip("Tout un univers d'outils", 500)
    canvas.alpha_composite(alpha_scaled(title, alpha), ((WIDTH - title.width) // 2, 70))

    items = [("Grapheur", 365), ("Conversions", 475), ("Historique", 585)]
    for index, (label, yy) in enumerate(items):
        item_alpha = alpha * ease((t - (13.25 + index * 0.32)) / 0.45)
        chip = glass_chip(label, 390, 30)
        canvas.alpha_composite(alpha_scaled(chip, item_alpha), ((WIDTH - chip.width) // 2, yy))


def outro_scene(canvas: Image.Image, t: float) -> None:
    alpha = fade_window(t, 16.2, 20.5, 0.6)
    progress = ease((t - 16.2) / 0.9)
    size = round(250 * (0.84 + 0.16 * progress))
    logo = LOGO_IMAGE.resize((size, size), Image.Resampling.LANCZOS)
    canvas.alpha_composite(alpha_scaled(logo, alpha), ((WIDTH - size) // 2, 190))
    d = ImageDraw.Draw(canvas)
    draw_centered(d, "Simple. Scientifique.", 500, font(38, bold=True), WHITE + (round(255 * alpha),))
    draw_centered(d, "Hors ligne.", 550, font(45, bold=True), GOLD + (round(255 * alpha),))
    draw_centered(d, "CALCULATRICE COSMIQUE", 675, font(42, bold=True), WHITE + (round(255 * alpha),), 2, (8, 16, 45, 220))
    draw_centered(d, "Disponible sur Google Play", 755, font(28, semibold=True), (190, 215, 255, round(255 * alpha)))

    button_alpha = alpha * ease((t - 17.5) / 0.6)
    if button_alpha > 0:
        d.rounded_rectangle((145, 850, 575, 940), radius=40, fill=(242, 215, 164, round(245 * button_alpha)), outline=(255, 244, 217, round(255 * button_alpha)), width=2)
        bbox = d.textbbox((0, 0), "TÉLÉCHARGEZ-LA", font=font(31, bold=True))
        d.text(((WIDTH - (bbox[2] - bbox[0])) / 2, 873), "TÉLÉCHARGEZ-LA", font=font(31, bold=True), fill=(7, 15, 40, round(255 * button_alpha)))


def render_frame(index: int) -> Image.Image:
    t = index / FPS
    canvas = cosmic_background(t)
    if t < 3.35:
        opening_scene(canvas, t)
    if 2.7 <= t < 8.1:
        calculation_scene(canvas, t)
    if 7.7 <= t < 13.1:
        science_scene(canvas, t)
    if 12.7 <= t < 16.8:
        features_scene(canvas, t)
    if t >= 16.2:
        outro_scene(canvas, t)

    # Gentle cinematic vignette.
    vignette = Image.new("L", (WIDTH, HEIGHT), 0)
    vd = ImageDraw.Draw(vignette)
    vd.ellipse((-190, -170, WIDTH + 190, HEIGHT + 170), fill=230)
    vignette = vignette.filter(ImageFilter.GaussianBlur(95))
    shade = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
    shade.putalpha(vignette.point(lambda p: 255 - p))
    canvas.alpha_composite(shade)
    return canvas.convert("RGB")


def create_audio() -> None:
    rate = 44_100
    count = rate * DURATION
    t = np.arange(count, dtype=np.float64) / rate
    fade_in = np.minimum(1.0, t / 1.4)
    fade_out = np.minimum(1.0, (DURATION - t) / 1.4)
    envelope = np.maximum(0, fade_in * fade_out)

    pad = (
        0.10 * np.sin(2 * np.pi * 110.0 * t)
        + 0.06 * np.sin(2 * np.pi * 164.81 * t + 0.3)
        + 0.045 * np.sin(2 * np.pi * 220.0 * t + 1.0)
    )
    shimmer = 0.018 * np.sin(2 * np.pi * (520 + 28 * np.sin(t * 0.5)) * t)
    audio = (pad + shimmer) * envelope

    for hit, freq in [(0.45, 880), (3.3, 660), (5.55, 990), (8.25, 784), (10.0, 1175), (13.2, 740), (16.6, 880), (18.0, 1320)]:
        dt = t - hit
        active = (dt >= 0) & (dt < 1.25)
        audio += active * 0.09 * np.sin(2 * np.pi * freq * dt) * np.exp(-3.8 * np.maximum(dt, 0))

    audio = np.clip(audio, -0.92, 0.92)
    stereo = np.column_stack((audio, audio * 0.96))
    samples = (stereo * 32767).astype(np.int16)
    with wave.open(str(AUDIO), "wb") as wav:
        wav.setnchannels(2)
        wav.setsampwidth(2)
        wav.setframerate(rate)
        wav.writeframes(samples.tobytes())


def main() -> None:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    sys.path.insert(0, str(ROOT / "build" / "video_tools"))
    import imageio_ffmpeg

    ffmpeg = imageio_ffmpeg.get_ffmpeg_exe()
    command = [
        ffmpeg, "-y", "-f", "rawvideo", "-vcodec", "rawvideo", "-pix_fmt", "rgb24",
        "-s", f"{WIDTH}x{HEIGHT}", "-r", str(FPS), "-i", "-", "-an", "-c:v", "libx264",
        "-preset", "medium", "-crf", "18", "-pix_fmt", "yuv420p", "-movflags", "+faststart",
        str(SILENT_VIDEO),
    ]
    process = subprocess.Popen(command, stdin=subprocess.PIPE)
    assert process.stdin is not None
    cover_frame = None
    for index in range(FRAMES):
        frame = render_frame(index)
        if index == round(FPS * 18.5):
            cover_frame = frame.copy()
        process.stdin.write(np.asarray(frame, dtype=np.uint8).tobytes())
        if index % FPS == 0:
            print(f"Rendu {index // FPS:02d}/{DURATION}s", flush=True)
    process.stdin.close()
    if process.wait() != 0:
        raise RuntimeError("L'encodage vidéo a échoué")

    create_audio()
    mux = [
        ffmpeg, "-y", "-i", str(SILENT_VIDEO), "-i", str(AUDIO), "-c:v", "copy",
        "-c:a", "aac", "-b:a", "192k", "-shortest", "-movflags", "+faststart", str(OUTPUT),
    ]
    subprocess.run(mux, check=True)
    if cover_frame is not None:
        cover_frame.save(COVER, quality=95)
    SILENT_VIDEO.unlink(missing_ok=True)
    AUDIO.unlink(missing_ok=True)
    print(f"Vidéo créée : {OUTPUT}")
    print(f"Couverture créée : {COVER}")


if __name__ == "__main__":
    main()
