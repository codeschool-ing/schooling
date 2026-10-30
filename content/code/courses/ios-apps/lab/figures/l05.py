"""Lesson 5 figures."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from fig import Fig, lesson

L = "le-7ed1hvpa"

f = Fig("l05-order", 720, 260,
        "Two chains side by side, each drawn as nested boxes. Left, text then padding then background: the background box, drawn in amber, is the outer box, 80 by 52, and the padding and the text sit inside it. Right, text then background then padding: the outer box is the padding, 80 by 52, unpainted; the amber background box inside it is only 48 by 20, the size of the text.",
        "Duas cadeias lado a lado, cada uma desenhada como caixas aninhadas. À esquerda, texto, depois padding, depois fundo: a caixa do fundo, em âmbar, é a de fora, 80 por 52, e o padding e o texto ficam dentro dela. À direita, texto, depois fundo, depois padding: a caixa de fora é o padding, 80 por 52, sem pintura; a caixa âmbar do fundo dentro dela tem só 48 por 20, o tamanho do texto.")
for x0, first in ((40, True), (390, False)):
    f.box(x0, 50, 290, 150, stroke="amber" if first else "wire", fill="scan" if first else "ink", dashed=not first)
    f.box(x0 + 60, 90, 170, 70, stroke="amber" if not first else "wire", fill="scan" if not first else "panel", dashed=first)
    f.text(x0 + 145, 125, "50 min", mono=True, size=12, fill="paper")
    f.text(x0 + 145, 216, "outer: 80 by 52", "fora: 80 por 52", size=10, fill="paper-dim")
f.text(185, 30, ".padding().background(.yellow)", mono=True, size=11, fill="paper")
f.text(535, 30, ".background(.yellow).padding()", mono=True, size=11, fill="paper")
f.text(185, 70, "background: 80 by 52", "fundo: 80 por 52", size=10, fill="amber")
f.text(185, 176, "padding inside", "padding dentro", size=10, fill="paper-dim")
f.text(535, 70, "padding: nothing painted", "padding: nada pintado", size=10, fill="paper-dim")
f.text(535, 176, "background: 48 by 20", "fundo: 48 por 20", size=10, fill="amber")
f.write(lesson(L, "order-matters"),
        "The same three pieces in two orders. The background is the size of whatever it wraps, so the order decides how much yellow there is.",
        "As mesmas três peças em duas ordens. O fundo tem o tamanho do que embrulha, então a ordem decide quanto amarelo existe.")
