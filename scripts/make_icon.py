# Regenerates the app icon. Run from the repo root: python3 scripts/make_icon.py (needs Pillow)
from PIL import Image, ImageDraw, ImageFilter

S = 2048  # supersample, downscale to 1024
img = Image.new("RGB", (S, S), (42, 36, 32))  # leather
d = ImageDraw.Draw(img)

def rr(box, r, fill, outline=None, width=0):
    d.rounded_rectangle(box, radius=r, fill=fill, outline=outline, width=width)

# warm background gradient
for y in range(S):
    t = y / S
    c = (int(58 - 18 * t), int(50 - 16 * t), int(44 - 14 * t))
    d.line([(0, y), (S, y)], fill=c)

# camera body (bone)
bx0, by0, bx1, by1 = 260, 520, 1788, 1700
rr((bx0 + 14, by0 + 34, bx1 + 14, by1 + 34), 150, (20, 16, 14))        # shadow
rr((bx0, by0, bx1, by1), 150, (237, 230, 214))                          # body
rr((bx0, by0, bx1, by0 + 90), 150, (246, 241, 229))                     # top highlight
d.rectangle((bx0, by0 + 60, bx1, by0 + 100), fill=(237, 230, 214))

# top deck: viewfinder window + flash bar
rr((bx0 + 120, by0 - 120, bx0 + 520, by0 + 10), 36, (237, 230, 214))
rr((bx0 + 170, by0 - 80, bx0 + 470, by0 - 10), 18, (42, 36, 32))
rr((bx1 - 560, by0 - 90, bx1 - 120, by0 + 10), 30, (217, 208, 188))
rr((bx1 - 530, by0 - 66, bx1 - 150, by0 - 8), 16, (250, 246, 236))

# warm three band stripe (original, earth palette)
sy = by0 + 150
for i, c in enumerate([(217, 98, 43), (232, 163, 61), (122, 160, 150)]):
    d.rectangle((bx0, sy + i * 44, bx1, sy + i * 44 + 44), fill=c)

# lens assembly
cx, cy = (bx0 + bx1) // 2, by0 + 700
for r, c in [(430, (30, 26, 24)), (390, (58, 52, 48)), (340, (22, 19, 18)),
             (270, (36, 40, 46)), (200, (18, 22, 28)), (120, (28, 36, 48))]:
    d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=c)
d.ellipse((cx - 430, cy - 430, cx + 430, cy + 430), outline=(217, 208, 188), width=14)
# glass highlights
d.ellipse((cx - 150, cy - 170, cx - 40, cy - 70), fill=(120, 150, 180))
d.ellipse((cx + 40, cy + 40, cx + 90, cy + 90), fill=(70, 96, 120))

# shutter button
sx, sy2 = bx1 - 190, by0 + 330
d.ellipse((sx - 70, sy2 - 70, sx + 70, sy2 + 70), fill=(217, 98, 43))
d.ellipse((sx - 70, sy2 - 70, sx + 70, sy2 + 70), outline=(170, 70, 28), width=8)

img = img.resize((1024, 1024), Image.LANCZOS)
img.save("Roll/Assets.xcassets/AppIcon.appiconset/AppIcon.png")
print("ok")
