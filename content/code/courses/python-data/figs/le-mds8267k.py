"""Lesson 9: Series, DataFrame and the index."""
from draw import Fig

align = Fig(
    "align", 720, 250,
    ("Left: docks with labels S01 14, S02 20, S03 12. Middle: added with labels S03 4, S01 2, S04 6, in "
     "another order. Right: docks + added, matched by label: S01 16, S02 NaN, S03 16, S04 NaN. Lines join "
     "equal labels across the two inputs; S02 and S04 have no partner.",
     "À esquerda: docks com rótulos S01 14, S02 20, S03 12. No meio: added com rótulos S03 4, S01 2, S04 "
     "6, em outra ordem. À direita: docks + added, casados por rótulo: S01 16, S02 NaN, S03 16, S04 NaN. "
     "Linhas ligam rótulos iguais entre as duas entradas; S02 e S04 não têm par."),
    ("pandas matches labels before it adds. A label on one side only gives NaN.",
     "O pandas casa rótulos antes de somar. Um rótulo de um lado só dá NaN."))
f = align

def series(x, title, rows, highlight=()):
    f.text(x + 60, 24, title, mono=True, weight="600")
    for i, (lab, val) in enumerate(rows):
        y = 40 + i * 40
        f.rect(x, y, 56, 30, fill="panel", stroke="wire", rx=2, width=1)
        f.text(x + 28, y + 15, lab, mono=True, size=11, fill="paper-dim")
        f.rect(x + 60, y, 60, 30, fill="scan" if lab in highlight else "panel",
               stroke="amber" if lab in highlight else "wire", rx=2, width=1)
        f.text(x + 90, y + 15, val, mono=True, size=11, fill="amber" if lab in highlight else "paper")

series(20, "docks", [("S01", "14"), ("S02", "20"), ("S03", "12")])
series(260, "added", [("S03", "4"), ("S01", "2"), ("S04", "6")])
series(560, "docks + added", [("S01", "16.0"), ("S02", "NaN"), ("S03", "16.0"), ("S04", "NaN")],
       highlight=("S02", "S04"))
f.line(144, 55, 256, 95, stroke="phosphor")
f.line(144, 135, 256, 55, stroke="phosphor")
f.text(200, 210, "S02: no partner", "S02: sem par", size=10, fill="amber")
f.text(320, 210, "S04: no partner", "S04: sem par", size=10, fill="amber")

FIGURES = [align]
