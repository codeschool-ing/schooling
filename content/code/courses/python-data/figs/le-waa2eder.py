"""Lesson 15: pivot and melt."""
from draw import Fig

shapes = Fig(
    "shapes", 720, 270,
    ("The same four counts in two shapes. Long: four rows, each with a month, a plan and a number of "
     "trips. Wide: two rows, one per month, with a column for each plan. pivot goes from long to wide; "
     "melt goes back.",
     "As mesmas quatro contagens em dois formatos. Longo: quatro linhas, cada uma com um mês, um plano e "
     "um número de viagens. Largo: duas linhas, uma por mês, com uma coluna por plano. pivot vai do "
     "longo ao largo; melt volta."),
    ("Long has a row per observation; wide has a row per month and a column per plan.",
     "O longo tem uma linha por observação; o largo tem uma linha por mês e uma coluna por plano."))
f = shapes
f.text(140, 22, "long", "longo", weight="600")
f.text(570, 22, "wide", "largo", weight="600")
cols = [("month", 60), ("plan", 140), ("trips", 220)]
rows = [("1", "annual", "2016"), ("1", "day", "896"), ("2", "annual", "1902"), ("2", "day", "854")]
f.rect(20, 40, 240, 190)
for name, x in cols:
    f.text(x, 60, name, mono=True, size=11, fill="paper-dim")
f.line(30, 74, 250, 74, width=1)
for r, row in enumerate(rows):
    y = 95 + r * 36
    for (name, x), v in zip(cols, row):
        f.text(x, y, v, mono=True, size=12, fill="amber" if name == "trips" else "paper")
f.rect(450, 70, 240, 120)
for name, x in [("month", 500), ("annual", 580), ("day", 655)]:
    f.text(x, 92, name, mono=True, size=11, fill="paper-dim")
f.line(460, 106, 680, 106, width=1)
for r, (m, a, d) in enumerate([("1", "2016", "896"), ("2", "1902", "854")]):
    y = 130 + r * 36
    f.text(500, y, m, mono=True, size=12)
    f.text(580, y, a, mono=True, size=12, fill="amber")
    f.text(655, y, d, mono=True, size=12, fill="amber")
f.line(280, 110, 430, 110, arrow=True)
f.text(355, 96, "pivot", mono=True, size=12, fill="paper", weight="600")
f.line(430, 160, 280, 160, arrow=True)
f.text(355, 176, "melt", mono=True, size=12, fill="paper", weight="600")
f.text(355, 250, "the same four numbers", "os mesmos quatro números", size=11, fill="paper-dim")

FIGURES = [shapes]
