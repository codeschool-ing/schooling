"""Lesson 6: broadcasting."""
from draw import Fig

broadcast = Fig(
    "broadcast", 720, 250,
    ("Three panels. Left: a table of shape (52, 7) and a row of shape (7,); the row is repeated down "
     "every week, drawn dashed. Middle: the same table and a column of shape (52, 1); the column is "
     "repeated across every day. Right: the table and a flat (52,) lined up from the right, 7 against "
     "52, which fails.",
     "Três painéis. À esquerda: uma tabela de formato (52, 7) e uma linha de formato (7,); a linha é "
     "repetida em cada semana, tracejada. No meio: a mesma tabela e uma coluna de formato (52, 1); a "
     "coluna é repetida em cada dia. À direita: a tabela e um (52,) plano alinhado pela direita, 7 "
     "contra 52, o que falha."),
    ("Shapes line up from the right; a length of 1 stretches, any other mismatch is an error.",
     "Formatos se alinham pela direita; um comprimento 1 estica, qualquer outra diferença é erro."))
f = broadcast

def grid(x, y, cols=7, rows=5, w=22, h=18, dash_rows=(), dash_cols=(), solid_row=None, solid_col=None):
    for r in range(rows):
        for c in range(cols):
            solid = (solid_row is not None and r == solid_row) or (solid_col is not None and c == solid_col)
            f.rect(x + c * w, y + r * h, w, h, fill="scan" if solid else "panel",
                   stroke="amber" if solid else "wire", rx=0, width=1,
                   dash=(not solid) and (r in dash_rows or c in dash_cols))

f.text(105, 22, "(52, 7) − (7,)", mono=True, weight="600")
grid(28, 40)
grid(28, 145, rows=4, dash_rows=(1, 2, 3), solid_row=0)
f.text(105, 236, "the row repeats down", "a linha se repete para baixo", size=10, fill="paper-dim")

f.text(360, 22, "(52, 7) − (52, 1)", mono=True, weight="600")
grid(283, 40)
grid(283, 145, rows=4, dash_cols=(1, 2, 3, 4, 5, 6), solid_col=0)
f.text(360, 236, "the column repeats across", "a coluna se repete para o lado", size=10, fill="paper-dim")

f.text(615, 22, "(52, 7) − (52,)", mono=True, weight="600")
grid(538, 40)
f.text(615, 150, "lined up from the right:", "alinhados pela direita:", size=10, fill="paper-dim")
f.text(615, 170, "(52, 7)", mono=True, size=11)
f.text(615, 188, "(52,)", mono=True, size=11)
f.text(615, 212, "7 against 52: error", "7 contra 52: erro", size=11, fill="amber", weight="600")

FIGURES = [broadcast]
