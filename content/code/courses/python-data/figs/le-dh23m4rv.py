"""Lesson 5: vectorised operations."""
from draw import Fig

axis = Fig(
    "axis", 720, 230,
    ("A table of 52 weeks by 7 days. mean with axis=1 runs along each row and leaves 52 weekly means, "
     "one per row. mean with axis=0 runs down each column and leaves 7 means, one per day position. "
     "The axis that is named is the one that disappears.",
     "Uma tabela de 52 semanas por 7 dias. mean com axis=1 percorre cada linha e deixa 52 médias "
     "semanais, uma por linha. mean com axis=0 desce cada coluna e deixa 7 médias, uma por posição do "
     "dia. O eixo nomeado é o que some."),
    ("The axis you name is the one that disappears: (52, 7) becomes (52,) or (7,).",
     "O eixo que você nomeia é o que some: (52, 7) vira (52,) ou (7,)."))
f = axis
x0, y0, cw, rh = 40, 40, 34, 24
f.text(x0, 24, "weeks, shape (52, 7)", "weeks, formato (52, 7)", anchor="start", weight="600")
for r in range(5):
    for c in range(7):
        f.rect(x0 + c * cw, y0 + r * rh, cw, rh, fill="panel", stroke="wire", rx=0, width=1)
f.text(x0 + 3.5 * cw, y0 + 5 * rh + 12, "⋮", mono=True, fill="paper-dim")
f.line(x0 + 4, y0 + 12, x0 + 7 * cw - 4, y0 + 12, arrow=True, stroke="amber")
f.line(x0 + 17, y0 + 4, x0 + 17, y0 + 5 * rh - 4, arrow=True, stroke="phosphor")
f.box(330, 30, 340, 70, "weeks.mean(axis=1)", mono=True, weight=None, size=12,
      sub=("along each row: 52 values, shape (52,)", "ao longo de cada linha: 52 valores, formato (52,)"))
f.box(330, 140, 340, 70, "weeks.mean(axis=0)", mono=True, weight=None, size=12,
      sub=("down each column: 7 values, shape (7,)", "descendo cada coluna: 7 valores, formato (7,)"))
f.line(x0 + 7 * cw + 8, y0 + 12, 326, 65, arrow=True, stroke="amber")
f.line(x0 + 17, y0 + 5 * rh + 2, 326, 175, arrow=True, stroke="phosphor")

FIGURES = [axis]
