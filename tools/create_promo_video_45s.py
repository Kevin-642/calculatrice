from __future__ import annotations

import math
import os
import subprocess
import sys
import wave
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

import create_promo_video as base


ROOT = Path(__file__).resolve().parents[1]
WIDTH, HEIGHT = base.WIDTH, base.HEIGHT
FPS = 24
DURATION = 45
FRAMES = FPS * DURATION
OUTPUT_DIR = ROOT / "store_assets"
SILENT_VIDEO = OUTPUT_DIR / "calculatrice_cosmique_promo_45s_silent.mp4"
AUDIO = OUTPUT_DIR / "calculatrice_cosmique_promo_45s_audio.wav"
OUTPUT = OUTPUT_DIR / "calculatrice_cosmique_promo_45s.mp4"
COVER = OUTPUT_DIR / "calculatrice_cosmique_promo_45s_cover.png"


def title_chip(canvas: Image.Image, text: str, t: float, start: float, end: float, width: int = 520) -> None:
    chip = base.glass_chip(text, width, 29)
    canvas.alpha_composite(base.alpha_scaled(chip, base.fade_window(t, start, end)), ((WIDTH - width) // 2, 64))


def phone_scene(t: float, start: float, end: float, y_offset: int = 45):
    layer, x, y, scale = base.phone_layer(t, start, end, y_offset=y_offset)
    return layer, x, y, scale, base.fade_window(t, start + 0.15, end)


def opening(canvas: Image.Image, t: float) -> None:
    alpha = base.fade_window(t, 0.0, 4.3, 0.7)
    progress = base.ease(t / 1.25)
    size = round(335 * (0.80 + 0.20 * progress))
    logo = base.LOGO_IMAGE.resize((size, size), Image.Resampling.LANCZOS)
    glow = Image.new("RGBA", (size + 130, size + 130), (0, 0, 0, 0))
    ImageDraw.Draw(glow).ellipse((65, 65, size + 65, size + 65), fill=(88, 126, 255, round(115 * alpha)))
    glow = glow.filter(ImageFilter.GaussianBlur(48))
    canvas.alpha_composite(glow, ((WIDTH - glow.width) // 2, 155))
    canvas.alpha_composite(base.alpha_scaled(logo, alpha), ((WIDTH - size) // 2, 220))
    d = ImageDraw.Draw(canvas)
    base.draw_centered(d, "CALCULATRICE", 610, base.font(46, bold=True), base.WHITE + (round(255 * alpha),), 2, (8, 14, 38, 220))
    base.draw_centered(d, "COSMIQUE", 665, base.font(62, bold=True), base.GOLD + (round(255 * alpha),), 2, (8, 14, 38, 220))
    base.draw_centered(d, "Vos calculs. Une autre dimension.", 760, base.font(27, semibold=True), base.WHITE + (round(245 * alpha),))


def calculation(canvas: Image.Image, t: float) -> None:
    start, end = 3.7, 10.3
    layer, x, y, scale, alpha = phone_scene(t, start, end)
    local = t - start
    if local < 1.25:
        expression, result = "", "0"
    elif local < 2.0:
        expression, result = "125", "125"
    elif local < 2.65:
        expression, result = "125 ×", "125"
    elif local < 3.35:
        expression, result = "125 × 8", "125"
    else:
        expression, result = "125 × 8", "1 000"
    base.overlay_display(layer, x, y, scale, expression, result, alpha)
    canvas.alpha_composite(layer)
    title_chip(canvas, "Rapide. Claire. Intuitive.", t, start + 0.2, end, 500)


def science(canvas: Image.Image, t: float) -> None:
    start, end = 9.7, 16.5
    layer, x, y, scale, alpha = phone_scene(t, start, end)
    local = t - start
    expression = "sin(" if local < 1.4 else "sin(π ÷ 2)"
    result = "0" if local < 2.7 else "1"
    base.overlay_display(layer, x, y, scale, expression, result, alpha)
    canvas.alpha_composite(layer)
    title_chip(canvas, "La puissance scientifique", t, start + 0.2, end, 510)
    badge = base.glass_chip("π   sin   cos   tan   xʸ   √", 520, 28)
    badge_alpha = alpha * base.ease((t - start - 2.0) / 0.55)
    canvas.alpha_composite(base.alpha_scaled(badge, badge_alpha), ((WIDTH - badge.width) // 2, 1000))


def graph(canvas: Image.Image, t: float) -> None:
    start, end = 15.9, 23.2
    layer, x, y, scale, alpha = phone_scene(t, start, end, 55)
    sx = base.PHONE.width / 945
    left = x + round(70 * sx * scale)
    top = y + round(275 * sx * scale)
    right = x + round(875 * sx * scale)
    bottom = y + round(860 * sx * scale)
    d = ImageDraw.Draw(layer)
    d.rounded_rectangle((left, top, right, bottom), radius=28, fill=(7, 14, 39, round(248 * alpha)), outline=(87, 151, 235, round(185 * alpha)), width=2)
    mid_x, mid_y = (left + right) // 2, (top + bottom) // 2
    grid = (78, 111, 168, round(70 * alpha))
    for i in range(-4, 5):
        xx = mid_x + i * (right - left) // 9
        yy = mid_y + i * (bottom - top) // 9
        d.line((xx, top + 20, xx, bottom - 20), fill=grid, width=1)
        d.line((left + 20, yy, right - 20, yy), fill=grid, width=1)
    d.line((left + 18, mid_y, right - 18, mid_y), fill=(190, 216, 255, round(180 * alpha)), width=2)
    d.line((mid_x, top + 18, mid_x, bottom - 18), fill=(190, 216, 255, round(180 * alpha)), width=2)
    progress = base.ease((t - start - 1.0) / 3.4)
    points = []
    count = max(2, round(150 * progress))
    for i in range(count):
        u = i / 149
        xx = left + 25 + u * (right - left - 50)
        value = math.sin((u * 2.0 - 1.0) * math.pi * 2.2)
        yy = mid_y - value * (bottom - top) * 0.28
        points.append((xx, yy))
    d.line(points, fill=(116, 205, 255, round(255 * alpha)), width=5, joint="curve")
    d.text((left + 25, top + 22), "y = sin(x)", font=base.font(27, semibold=True), fill=base.GOLD + (round(255 * alpha),))
    canvas.alpha_composite(layer)
    title_chip(canvas, "Explorez vos fonctions", t, start + 0.2, end, 490)
    badge = base.glass_chip("Grapheur interactif • zoom", 500, 27)
    canvas.alpha_composite(base.alpha_scaled(badge, alpha), ((WIDTH - badge.width) // 2, 1015))


def conversion(canvas: Image.Image, t: float) -> None:
    start, end = 22.6, 29.9
    layer, x, y, scale, alpha = phone_scene(t, start, end)
    sx = base.PHONE.width / 945
    left = x + round(70 * sx * scale)
    top = y + round(300 * sx * scale)
    right = x + round(875 * sx * scale)
    bottom = y + round(820 * sx * scale)
    d = ImageDraw.Draw(layer)
    d.rounded_rectangle((left, top, right, bottom), radius=30, fill=(8, 17, 45, round(248 * alpha)), outline=(91, 147, 230, round(180 * alpha)), width=2)
    d.text((left + 28, top + 28), "CONVERSIONS", font=base.font(25, bold=True), fill=base.CYAN + (round(255 * alpha),))
    rows = [("10 kilomètres", "10 km"), ("= 6,2137 miles", "6,21 mi")]
    for idx, (label, value) in enumerate(rows):
        yy = top + 105 + idx * 135
        d.rounded_rectangle((left + 25, yy, right - 25, yy + 105), radius=22, fill=(20, 35, 72, round(230 * alpha)))
        d.text((left + 48, yy + 18), label, font=base.font(24, semibold=True), fill=base.WHITE + (round(250 * alpha),))
        d.text((right - 48, yy + 61), value, font=base.font(28, bold=True), fill=base.GOLD + (round(255 * alpha),), anchor="ra")
    canvas.alpha_composite(layer)
    title_chip(canvas, "Convertissez en un instant", t, start + 0.2, end, 520)
    badge = base.glass_chip("Longueur • masse • température", 560, 25)
    canvas.alpha_composite(base.alpha_scaled(badge, alpha), ((WIDTH - badge.width) // 2, 1000))


def history(canvas: Image.Image, t: float) -> None:
    start, end = 29.3, 35.9
    layer, x, y, scale, alpha = phone_scene(t, start, end)
    sx = base.PHONE.width / 945
    left = x + round(62 * sx * scale)
    top = y + round(310 * sx * scale)
    right = x + round(883 * sx * scale)
    d = ImageDraw.Draw(layer)
    d.rounded_rectangle((left, top, right, top + 485), radius=28, fill=(7, 16, 42, round(248 * alpha)), outline=(91, 147, 230, round(170 * alpha)), width=2)
    d.text((left + 28, top + 25), "HISTORIQUE", font=base.font(25, bold=True), fill=base.CYAN + (round(255 * alpha),))
    entries = [("125 × 8", "1 000"), ("sin(π ÷ 2)", "1"), ("√144", "12")]
    for idx, (expr, result) in enumerate(entries):
        yy = top + 85 + idx * 118
        d.rounded_rectangle((left + 22, yy, right - 22, yy + 92), radius=20, fill=(18, 33, 69, round(235 * alpha)))
        d.text((left + 43, yy + 26), expr, font=base.font(24, semibold=True), fill=base.WHITE + (round(245 * alpha),))
        d.text((right - 45, yy + 24), result, font=base.font(29, bold=True), fill=base.GOLD + (round(255 * alpha),), anchor="ra")
    canvas.alpha_composite(layer)
    title_chip(canvas, "Retrouvez chaque résultat", t, start + 0.2, end, 520)
    badge = base.glass_chip("Recherche • favoris • copie", 500, 27)
    canvas.alpha_composite(base.alpha_scaled(badge, alpha), ((WIDTH - badge.width) // 2, 1000))


def benefits(canvas: Image.Image, t: float) -> None:
    start, end = 35.3, 40.7
    alpha = base.fade_window(t, start, end, 0.6)
    d = ImageDraw.Draw(canvas)
    base.draw_centered(d, "TOUJOURS PRÊTE", 215, base.font(44, bold=True), base.WHITE + (round(255 * alpha),))
    base.draw_centered(d, "même loin du réseau", 275, base.font(31, semibold=True), base.CYAN + (round(255 * alpha),))
    items = [("HORS LIGNE", "Vos calculs restent avec vous"), ("PERSISTANTE", "Historique et mémoire sauvegardés"), ("ACCESSIBLE", "Portrait, paysage, animations adaptées")]
    for idx, (heading, subtitle) in enumerate(items):
        item_alpha = alpha * base.ease((t - start - 0.45 - idx * 0.38) / 0.55)
        yy = 410 + idx * 190
        d.rounded_rectangle((90, yy, 630, yy + 140), radius=32, fill=(8, 18, 48, round(225 * item_alpha)), outline=(111, 185, 255, round(170 * item_alpha)), width=2)
        d.text((WIDTH // 2, yy + 24), heading, font=base.font(31, bold=True), fill=base.GOLD + (round(255 * item_alpha),), anchor="ma")
        d.text((WIDTH // 2, yy + 78), subtitle, font=base.font(22, semibold=True), fill=base.WHITE + (round(240 * item_alpha),), anchor="ma")


def outro(canvas: Image.Image, t: float) -> None:
    start = 40.1
    alpha = base.fade_window(t, start, 45.5, 0.65)
    progress = base.ease((t - start) / 0.9)
    size = round(250 * (0.84 + 0.16 * progress))
    logo = base.LOGO_IMAGE.resize((size, size), Image.Resampling.LANCZOS)
    canvas.alpha_composite(base.alpha_scaled(logo, alpha), ((WIDTH - size) // 2, 150))
    d = ImageDraw.Draw(canvas)
    base.draw_centered(d, "Simple. Scientifique.", 470, base.font(38, bold=True), base.WHITE + (round(255 * alpha),))
    base.draw_centered(d, "Infiniment cosmique.", 525, base.font(43, bold=True), base.GOLD + (round(255 * alpha),))
    base.draw_centered(d, "CALCULATRICE COSMIQUE", 665, base.font(41, bold=True), base.WHITE + (round(255 * alpha),), 2, (8, 16, 45, 220))
    base.draw_centered(d, "Disponible sur Google Play", 745, base.font(28, semibold=True), (190, 215, 255, round(255 * alpha)))
    button_alpha = alpha * base.ease((t - start - 1.1) / 0.55)
    d.rounded_rectangle((145, 850, 575, 940), radius=40, fill=(242, 215, 164, round(245 * button_alpha)), outline=(255, 244, 217, round(255 * button_alpha)), width=2)
    d.text((WIDTH // 2, 876), "TÉLÉCHARGEZ-LA", font=base.font(31, bold=True), fill=(7, 15, 40, round(255 * button_alpha)), anchor="ma")


def render_frame(index: int) -> Image.Image:
    t = index / FPS
    canvas = base.cosmic_background(t)
    if t < 4.4:
        opening(canvas, t)
    if 3.7 <= t < 10.3:
        calculation(canvas, t)
    if 9.7 <= t < 16.5:
        science(canvas, t)
    if 15.9 <= t < 23.2:
        graph(canvas, t)
    if 22.6 <= t < 29.9:
        conversion(canvas, t)
    if 29.3 <= t < 35.9:
        history(canvas, t)
    if 35.3 <= t < 40.7:
        benefits(canvas, t)
    if t >= 40.1:
        outro(canvas, t)
    vignette = Image.new("L", (WIDTH, HEIGHT), 0)
    ImageDraw.Draw(vignette).ellipse((-190, -170, WIDTH + 190, HEIGHT + 170), fill=230)
    vignette = vignette.filter(ImageFilter.GaussianBlur(95))
    shade = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
    shade.putalpha(vignette.point(lambda p: 255 - p))
    canvas.alpha_composite(shade)
    return canvas.convert("RGB")


def create_audio() -> None:
    rate = 44_100
    count = rate * DURATION
    t = np.arange(count, dtype=np.float64) / rate
    envelope = np.minimum(1.0, t / 1.8) * np.minimum(1.0, (DURATION - t) / 1.8)
    chord_roots = np.array([110.0, 130.81, 98.0, 146.83])
    section = np.minimum((t // 5.0).astype(int), len(chord_roots) - 1) % len(chord_roots)
    root = chord_roots[section]
    pad = 0.082 * np.sin(2 * np.pi * root * t) + 0.052 * np.sin(2 * np.pi * root * 1.5 * t + 0.35) + 0.036 * np.sin(2 * np.pi * root * 2.0 * t + 0.9)
    shimmer = 0.014 * np.sin(2 * np.pi * (510 + 34 * np.sin(t * 0.34)) * t)
    pulse = 0.025 * np.sin(2 * np.pi * 55 * t) * (0.45 + 0.55 * np.maximum(0, np.sin(2 * np.pi * 0.8 * t)))
    audio = (pad + shimmer + pulse) * envelope
    hits = [(0.5, 880), (4.0, 660), (7.2, 990), (10.0, 784), (13.2, 1175), (16.2, 740), (19.7, 932), (23.0, 659), (26.3, 988), (29.6, 784), (32.6, 1109), (35.6, 740), (38.2, 988), (40.5, 880), (42.0, 1320)]
    for hit, freq in hits:
        dt = t - hit
        active = (dt >= 0) & (dt < 1.35)
        audio += active * 0.075 * np.sin(2 * np.pi * freq * dt) * np.exp(-3.7 * np.maximum(dt, 0))
    audio = np.clip(audio, -0.92, 0.92)
    stereo = np.column_stack((audio, audio * 0.96))
    with wave.open(str(AUDIO), "wb") as wav:
        wav.setnchannels(2)
        wav.setsampwidth(2)
        wav.setframerate(rate)
        wav.writeframes((stereo * 32767).astype(np.int16).tobytes())


def main() -> None:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    sys.path.insert(0, str(ROOT / "build" / "video_tools"))
    import imageio_ffmpeg

    ffmpeg_getter = getattr(imageio_ffmpeg, "get_ffmpeg_exe", None)
    ffmpeg = ffmpeg_getter() if ffmpeg_getter else os.environ.get(
        "CALCULATRICE_FFMPEG",
        r"C:\Users\kevin\AppData\Local\Microsoft\WinGet\Packages\Gyan.FFmpeg_Microsoft.Winget.Source_8wekyb3d8bbwe\ffmpeg-8.1.2-full_build\bin\ffmpeg.exe",
    )
    command = [ffmpeg, "-y", "-f", "rawvideo", "-vcodec", "rawvideo", "-pix_fmt", "rgb24", "-s", f"{WIDTH}x{HEIGHT}", "-r", str(FPS), "-i", "-", "-an", "-c:v", "libx264", "-preset", "medium", "-crf", "18", "-pix_fmt", "yuv420p", "-movflags", "+faststart", str(SILENT_VIDEO)]
    process = subprocess.Popen(command, stdin=subprocess.PIPE)
    assert process.stdin is not None
    cover_frame = None
    for index in range(FRAMES):
        frame = render_frame(index)
        if index == round(FPS * 42.5):
            cover_frame = frame.copy()
        process.stdin.write(np.asarray(frame, dtype=np.uint8).tobytes())
        if index % FPS == 0:
            print(f"Rendu {index // FPS:02d}/{DURATION}s", flush=True)
    process.stdin.close()
    if process.wait() != 0:
        raise RuntimeError("L'encodage vidéo a échoué")
    create_audio()
    subprocess.run([ffmpeg, "-y", "-i", str(SILENT_VIDEO), "-i", str(AUDIO), "-c:v", "copy", "-c:a", "aac", "-b:a", "192k", "-shortest", "-movflags", "+faststart", str(OUTPUT)], check=True)
    if cover_frame is not None:
        cover_frame.save(COVER, quality=95)
    SILENT_VIDEO.unlink(missing_ok=True)
    AUDIO.unlink(missing_ok=True)
    print(f"Vidéo créée : {OUTPUT}")
    print(f"Couverture créée : {COVER}")


if __name__ == "__main__":
    main()
