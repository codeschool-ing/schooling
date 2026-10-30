"""Lesson 7: the same 48 dp square on three densities, and the ladder of buckets."""
from fig import Fig

T = {
    "en": dict(
        s_aria="Three squares drawn the same physical size, each a 48 dp touch target. On an mdpi screen at 160 dpi it is 48 pixels across, drawn as a grid of 6 by 6 cells; on xhdpi at 320 dpi it is 96 pixels, 12 by 12 cells; on xxhdpi at 480 dpi it is 144 pixels, 18 by 18 cells. Each cell stands for 8 by 8 pixels.",
        s_head="the same 48 dp target, the same size under the finger; one cell stands for 8 x 8 pixels",
        px="48 dp = {} px",
        s_cap="The size stays and the pixel count follows the screen: 48, 96 and 144 pixels across for one 48 dp square. A layout written in dp never has to know which of the three it is on.",
        b_aria="Five squares side by side, drawn to scale in pixels: the files for one 24 dp icon. mdpi at 160 dpi is 24 by 24 pixels, scale 1x; hdpi at 240 dpi is 36 by 36, 1.5x; xhdpi at 320 dpi is 48 by 48, 2x; xxhdpi at 480 dpi is 72 by 72, 3x; xxxhdpi at 640 dpi is 96 by 96, 4x.",
        dec=".",
        b_head="one 24 dp icon as a raster file per bucket, drawn to scale",
        b_cap="Android's buckets as a ladder. Each step is a folder with its own copy of the image, and the largest copy has sixteen times the pixels of the smallest.",
    ),
    "pt": dict(
        s_aria="Três quadrados desenhados com o mesmo tamanho físico, cada um um alvo de toque de 48 dp. Numa tela mdpi de 160 dpi ele tem 48 pixels de lado, desenhado como uma grade de 6 por 6 células; em xhdpi de 320 dpi tem 96 pixels, 12 por 12 células; em xxhdpi de 480 dpi tem 144 pixels, 18 por 18 células. Cada célula representa 8 por 8 pixels.",
        s_head="o mesmo alvo de 48 dp, do mesmo tamanho sob o dedo; uma célula vale 8 x 8 pixels",
        px="48 dp = {} px",
        s_cap="O tamanho fica e a contagem de pixels acompanha a tela: 48, 96 e 144 pixels de lado para um quadrado de 48 dp. Um layout escrito em dp nunca precisa saber em qual das três está.",
        b_aria="Cinco quadrados lado a lado, desenhados em escala, em pixels: os arquivos de um ícone de 24 dp. mdpi de 160 dpi tem 24 por 24 pixels, escala 1x; hdpi de 240 dpi tem 36 por 36, 1,5x; xhdpi de 320 dpi tem 48 por 48, 2x; xxhdpi de 480 dpi tem 72 por 72, 3x; xxxhdpi de 640 dpi tem 96 por 96, 4x.",
        dec=",",
        b_head="um ícone de 24 dp como arquivo raster por bucket, em escala",
        b_cap="Os buckets do Android como uma escada. Cada degrau é uma pasta com a própria cópia da imagem, e a maior cópia tem dezesseis vezes os pixels da menor.",
    ),
}

DENS = [("mdpi", 160, 48), ("xhdpi", 320, 96), ("xxhdpi", 480, 144)]
LADDER = [("mdpi", 160, "1x", 24), ("hdpi", 240, "1.5x", 36), ("xhdpi", 320, "2x", 48),
          ("xxhdpi", 480, "3x", 72), ("xxxhdpi", 640, "4x", 96)]


def square(t):
    f = Fig("l07-same-square", 720, 250, t["s_aria"])
    f.text(360, 20, t["s_head"], size=10, fill="paper-dim", italic=True)
    side = 132
    for i, (name, dpi, px) in enumerate(DENS):
        x, y = 70 + i * 220, 40
        f.rect(x, y, side, side, stroke="phosphor", fill="panel", width=1.6, rx=2)
        n = px // 8
        for k in range(1, n):
            d = round(side * k / n, 2)
            f.arrow([(x + d, y), (x + d, y + side)], color="wire", head=False, width=0.6)
            f.arrow([(x, y + d), (x + side, y + d)], color="wire", head=False, width=0.6)
        f.text(x + side / 2, y + side + 20, f"{name}, {dpi} dpi", size=10, mono=True)
        f.text(x + side / 2, y + side + 38, t["px"].format(px), size=10, fill="phosphor")
    return f


def ladder(t):
    f = Fig("l07-buckets", 720, 210, t["b_aria"])
    f.text(360, 20, t["b_head"], size=10, fill="paper-dim", italic=True)
    base = 150
    x = 60
    for name, dpi, scale, px in LADDER:
        f.rect(x, base - px, px, px, stroke="amber", fill="panel", width=1.4, rx=2)
        cx = x + px / 2
        f.text(cx, base - px - 12, f"{px} x {px}", size=9.5, mono=True, fill="amber")
        f.text(cx, base + 16, name, size=10, mono=True)
        f.text(cx, base + 32, f"{dpi} dpi", size=9.5, fill="paper-dim")
        f.text(cx, base + 47, scale.replace(".", t["dec"]), size=9.5, fill="paper-dim")
        x += max(px, 70) + 50
    return f


def figures(lang):
    t = T[lang]
    return {
        "l07-same-square": square(t).json(t["s_cap"], same=None if lang == "en" else ["48 dp = 48 px", "48 dp = 96 px", "48 dp = 144 px"]),
        "l07-buckets": ladder(t).json(t["b_cap"], same=None if lang == "en" else ["160 dpi", "240 dpi", "320 dpi", "480 dpi", "640 dpi", "1x", "2x", "3x", "4x"]),
    }
