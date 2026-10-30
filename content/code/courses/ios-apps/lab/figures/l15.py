"""Lesson 15 figures."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from fig import Fig, lesson

L = "le-53aev2fx"
k = 400 / 4032                                   # every rectangle is drawn to one scale
f = Fig("l15-pixels", 720, 360,
        "Three rectangles drawn to the same scale, each the pixel grid of a decoded picture. The largest, 4032 by 3024 pixels, is the phone photograph: 48,771,072 bytes decoded, from a 40,614-byte file. Beside it, a 1200 by 800 course cover: 3,840,000 bytes. In the photograph's top-left corner, a small square of 240 by 240 pixels, the thumbnail an 80-point square needs on a 3x screen: 230,400 bytes.",
        "Três retângulos desenhados na mesma escala, cada um a grade de pixels de uma imagem decodificada. O maior, de 4032 por 3024 pixels, é a fotografia do telefone: 48.771.072 bytes decodificada, a partir de um arquivo de 40.614 bytes. Ao lado, uma capa de curso de 1200 por 800: 3.840.000 bytes. No canto superior esquerdo da fotografia, um quadrado pequeno de 240 por 240 pixels, a miniatura de que um quadrado de 80 pontos precisa numa tela 3x: 230.400 bytes.")
x0, y0 = 30, 30
w, h = round(4032 * k), round(3024 * k)
f.box(x0, y0, w, h, stroke="amber", fill="ink")
f.text(x0 + w / 2, y0 + h / 2 - 12, "the photograph, 4032 x 3024", "a fotografia, 4032 x 3024", size=12, fill="amber", weight="600")
f.text(x0 + w / 2, y0 + h / 2 + 10, "48,771,072 bytes decoded", "48.771.072 bytes decodificada", size=11)
f.text(x0 + w / 2, y0 + h / 2 + 28, "from a file of 40,614", "de um arquivo de 40.614", size=10, fill="paper-dim")
t = round(240 * k)
f.box(x0 + 4, y0 + 4, t, t, stroke="phosphor", fill="panel", sw=1.6)
f.line(x0 + 4 + t + 2, y0 + 4 + t / 2, x0 + 70, y0 + 4 + t / 2, color="phosphor", arrow=False)
f.text(x0 + 74, y0 + 4 + t / 2 - 6, "the thumbnail, 240 x 240", "a miniatura, 240 x 240", size=10, fill="phosphor", anchor="start")
f.text(x0 + 74, y0 + 4 + t / 2 + 9, "230,400 bytes", "230.400 bytes", size=10, fill="phosphor", anchor="start")
cx = x0 + w + 40
cw, ch = round(1200 * k), round(800 * k)
f.box(cx, y0, cw, ch, stroke="wire")
f.text(cx + cw / 2, y0 + ch + 16, "a course cover", "uma capa de curso", size=11, fill="paper")
f.text(cx + cw / 2, y0 + ch + 32, "1200 x 800", "1200 x 800", mono=True, size=10, fill="paper-dim")
f.text(cx + cw / 2, y0 + ch + 48, "3,840,000 bytes", "3.840.000 bytes", size=10, fill="paper-dim")
f.text(360, 346, "one scale for all three: the area is the memory", "uma escala só para os três: a área é a memória", size=10, fill="paper-dim")
f.write(lesson(L, "memory-sums"),
        "Memory follows the pixels, not the file. The square in the corner is everything the list's 80-point thumbnail needs of the photograph.",
        "A memória segue os pixels, não o arquivo. O quadrado no canto é tudo o que a miniatura de 80 pontos da lista precisa da fotografia.")
