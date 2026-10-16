"""Lesson 7: indexing and masks."""
from draw import Fig

vals = [0.0, 6.8, 7.9, 15.7, 0.0, 0.0, 1.3, 0.0]
mask = [v > 5 for v in vals]

masking = Fig(
    "masking", 720, 250,
    ("Top row: the first eight rain readings, 0.0, 6.8, 7.9, 15.7, 0.0, 0.0, 1.3, 0.0. Middle row: the "
     "mask rain > 5, True under 6.8, 7.9 and 15.7 and False elsewhere. Bottom: indexing with the mask "
     "gives a new, shorter array, 6.8, 7.9, 15.7, which is a copy.",
     "Linha de cima: as oito primeiras leituras de chuva, 0.0, 6.8, 7.9, 15.7, 0.0, 0.0, 1.3, 0.0. Linha "
     "do meio: a máscara rain > 5, True sob 6.8, 7.9 e 15.7 e False no resto. Embaixo: indexar com a "
     "máscara dá um array novo e mais curto, 6.8, 7.9, 15.7, que é uma cópia."),
    ("A mask keeps the elements under True, in order, in a new array.",
     "Uma máscara guarda os elementos sob True, em ordem, num array novo."))
f = masking
x0, w = 150, 64
f.text(20, 40, "rain[:8]", mono=True, anchor="start", size=11)
f.text(20, 90, "rain[:8] > 5", mono=True, anchor="start", size=11)
f.text(20, 190, "rain[:8][mask]", mono=True, anchor="start", size=11)
for i, (v, m) in enumerate(zip(vals, mask)):
    x = x0 + i * w
    f.rect(x, 24, w - 6, 32, fill="scan" if m else "panel", stroke="amber" if m else "wire", rx=2, width=1)
    f.text(x + (w - 6) / 2, 40, f"{v:.1f}", mono=True, size=11)
    f.rect(x, 74, w - 6, 32, fill="panel", stroke="wire", rx=2, width=1)
    f.text(x + (w - 6) / 2, 90, "True" if m else "False", mono=True, size=11,
           fill="amber" if m else "paper-dim")
picked = [(i, v) for i, (v, m) in enumerate(zip(vals, mask)) if m]
for j, (i, v) in enumerate(picked):
    x = x0 + j * w
    f.rect(x, 174, w - 6, 32, fill="scan", stroke="amber", rx=2, width=1)
    f.text(x + (w - 6) / 2, 190, f"{v:.1f}", mono=True, size=11)
    f.line(x0 + i * w + (w - 6) / 2, 110, x + (w - 6) / 2, 170, arrow=True, stroke="wire")
f.text(x0 + 3 * w + 10, 190, "a new array, three long: a copy", "um array novo, de três: uma cópia",
       anchor="start", size=11, fill="paper-dim")

FIGURES = [masking]
