#!/usr/bin/env python3
"""
Generate a modern macOS-style App Icon for MiniCam.
Creates a 1024x1024 master icon and exports all sizes for iconutil.
"""
import os
import math
import subprocess
from PIL import Image, ImageDraw, ImageFilter

def create_master_icon(size=1024):
    # Canvas with transparency
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # 1. Background Squircle / Rounded Rect
    margin = int(size * 0.08)
    rect_box = [margin, margin, size - margin, size - margin]
    corner_radius = int(size * 0.22)

    # Base gradient on background
    bg_mask = Image.new("L", (size, size), 0)
    mask_draw = ImageDraw.Draw(bg_mask)
    mask_draw.rounded_rectangle(rect_box, radius=corner_radius, fill=255)

    # Draw gradient background (Dark titanium gradient)
    bg = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    bg_draw = ImageDraw.Draw(bg)
    for y in range(size):
        ratio = y / size
        # Smooth deep space grey to dark obsidian with subtle cool tint
        r = int(32 * (1 - ratio) + 14 * ratio)
        g = int(36 * (1 - ratio) + 16 * ratio)
        b = int(48 * (1 - ratio) + 24 * ratio)
        bg_draw.line([(0, y), (size, y)], fill=(r, g, b, 255))
    
    # Apply mask with shadow
    img.paste(bg, (0, 0), bg_mask)

    # Inner border / glow
    border_draw = ImageDraw.Draw(img)
    border_draw.rounded_rectangle(rect_box, radius=corner_radius, outline=(255, 255, 255, 35), width=int(size*0.008))

    center = size // 2

    # 2. Outer Camera Metallic Bezel / Ring
    outer_r = int(size * 0.33)
    bezel_box = [center - outer_r, center - outer_r, center + outer_r, center + outer_r]
    
    # Outer ring shadow
    bezel_shadow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    s_draw = ImageDraw.Draw(bezel_shadow)
    s_draw.ellipse([bezel_box[0]-4, bezel_box[1]+8, bezel_box[2]+4, bezel_box[3]+16], fill=(0, 0, 0, 180))
    bezel_shadow = bezel_shadow.filter(ImageFilter.GaussianBlur(int(size * 0.02)))
    img.alpha_composite(bezel_shadow)

    # Metallic ring gradient simulation
    border_draw.ellipse(bezel_box, fill=(28, 30, 36, 255), outline=(90, 95, 110, 255), width=int(size * 0.015))
    
    inner_bezel_r = int(size * 0.30)
    inner_bezel_box = [center - inner_bezel_r, center - inner_bezel_r, center + inner_bezel_r, center + inner_bezel_r]
    border_draw.ellipse(inner_bezel_box, fill=(18, 20, 24, 255), outline=(40, 44, 52, 255), width=int(size * 0.008))

    # 3. Lens Optical Glass Layers (Deep Blue & Violet multicoating)
    lens_r = int(size * 0.27)
    lens_box = [center - lens_r, center - lens_r, center + lens_r, center + lens_r]
    
    lens_img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    l_draw = ImageDraw.Draw(lens_img)
    l_draw.ellipse(lens_box, fill=(10, 15, 30, 255))
    
    # Lens reflection arcs / aperture
    for step in range(3):
        cur_r = int(lens_r * (0.85 - step * 0.2))
        cur_box = [center - cur_r, center - cur_r, center + cur_r, center + cur_r]
        l_draw.ellipse(cur_box, outline=(30 + step * 25, 45 + step * 30, 90 + step * 40, 80), width=int(size * 0.006))

    # Core sensor pupil
    pupil_r = int(size * 0.11)
    pupil_box = [center - pupil_r, center - pupil_r, center + pupil_r, center + pupil_r]
    l_draw.ellipse(pupil_box, fill=(6, 8, 16, 255), outline=(0, 210, 255, 120), width=int(size * 0.008))

    # Glass highlight glare (Curved soft reflection)
    glare_box = [center - int(lens_r*0.8), center - int(lens_r*0.8), center + int(lens_r*0.2), center + int(lens_r*0.2)]
    l_draw.arc(glare_box, start=200, end=330, fill=(255, 255, 255, 140), width=int(size * 0.02))

    # Second subtle warm flare
    warm_flare_box = [center - int(lens_r*0.1), center - int(lens_r*0.1), center + int(lens_r*0.75), center + int(lens_r*0.75)]
    l_draw.arc(warm_flare_box, start=30, end=140, fill=(255, 120, 60, 90), width=int(size * 0.012))

    img.alpha_composite(lens_img)

    # 4. Recording Indicator LED (Top right near bezel)
    led_x = center + int(size * 0.27)
    led_y = center - int(size * 0.27)
    led_r = int(size * 0.032)
    
    # Red LED Glow
    led_glow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    g_draw = ImageDraw.Draw(led_glow)
    g_draw.ellipse([led_x - led_r*3, led_y - led_r*3, led_x + led_r*3, led_y + led_r*3], fill=(255, 59, 48, 60))
    led_glow = led_glow.filter(ImageFilter.GaussianBlur(int(size * 0.02)))
    img.alpha_composite(led_glow)

    # Red LED Solid
    draw.ellipse([led_x - led_r, led_y - led_r, led_x + led_r, led_y + led_r], fill=(255, 69, 58, 255), outline=(255, 150, 140, 200), width=int(size * 0.004))
    draw.ellipse([led_x - led_r//2, led_y - led_r//2, led_x, led_y], fill=(255, 230, 230, 220))

    # 5. Top Flash / Sensor dot
    flash_x = center - int(size * 0.27)
    flash_y = center - int(size * 0.27)
    flash_r = int(size * 0.022)
    draw.ellipse([flash_x - flash_r, flash_y - flash_r, flash_x + flash_r, flash_y + flash_r], fill=(240, 200, 80, 220), outline=(255, 255, 255, 100), width=int(size * 0.003))

    return img

def main():
    base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    iconset_dir = os.path.join(base_dir, "Resources", "AppIcon.iconset")
    os.makedirs(iconset_dir, exist_ok=True)

    master = create_master_icon(1024)
    master_path = os.path.join(base_dir, "Resources", "icon_1024.png")
    master.save(master_path, "PNG")
    print(f"Saved master icon to {master_path}")

    sizes = [
        (16, "icon_16x16.png"),
        (32, "icon_16x16@2x.png"),
        (32, "icon_32x32.png"),
        (64, "icon_32x32@2x.png"),
        (128, "icon_128x128.png"),
        (256, "icon_128x128@2x.png"),
        (256, "icon_256x256.png"),
        (512, "icon_256x256@2x.png"),
        (512, "icon_512x512.png"),
        (1024, "icon_512x512@2x.png"),
    ]

    for px, filename in sizes:
        resized = master.resize((px, px), Image.Resampling.LANCZOS)
        resized.save(os.path.join(iconset_dir, filename), "PNG")

    # Convert to icns
    icns_path = os.path.join(base_dir, "Resources", "AppIcon.icns")
    res = subprocess.run(["iconutil", "-c", "icns", iconset_dir, "-o", icns_path], capture_output=True, text=True)
    if res.returncode == 0:
        print(f"Successfully generated {icns_path}")
    else:
        print(f"iconutil failed: {res.stderr}")

if __name__ == "__main__":
    main()
