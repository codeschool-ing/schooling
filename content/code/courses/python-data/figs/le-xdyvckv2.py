"""Lesson 17: apply and map."""
from draw import Fig

loop = Fig(
    "loop", 720, 250,
    ("Two ways to compute trip lengths. On the left, apply with axis=1 builds a Series for each of the "
     "33,337 rows and calls a Python function on it, one row at a time. On the right, two whole columns "
     "are subtracted once, in compiled code.",
     "Dois jeitos de calcular durações de viagem. À esquerda, o apply com axis=1 monta uma Series para "
     "cada uma das 33.337 linhas e chama uma função Python nela, uma linha por vez. À direita, duas "
     "colunas inteiras são subtraídas uma vez, em código compilado."),
    ("apply with axis=1 is a Python loop that builds a row for every call; a column expression is one "
     "call.",
     "O apply com axis=1 é um laço Python que monta uma linha a cada chamada; uma expressão de colunas é "
     "uma chamada só."))
f = loop
f.text(180, 22, "apply(minutes_of, axis=1)", mono=True, size=12, weight="600")
f.text(540, 22, "ended_at - started_at", mono=True, size=12, weight="600")
for i, y in enumerate([50, 92, 134]):
    f.box(20, y, 110, 32, f"row {i}", f"linha {i}", mono=True, size=11, weight=None)
    f.line(134, y + 16, 196, y + 16, arrow=True)
    f.box(200, y, 140, 32, "minutes_of(row)", mono=True, size=11, weight=None, stroke="amber")
f.text(75, 196, "… 33,337 times", "… 33.337 vezes", size=11, fill="amber")
f.text(180, 226, "a Series built, and a Python call, per row",
       "uma Series montada, e uma chamada Python, por linha", size=10, fill="paper-dim")
f.line(380, 40, 380, 230, stroke="wire", width=1, dash=True)
f.box(420, 60, 100, 120, "ended_at", mono=True, size=11, weight=None,
      sub=("33,337", "33.337"), sub_mono=True)
f.box(560, 60, 100, 120, "started_at", mono=True, size=11, weight=None,
      sub=("33,337", "33.337"), sub_mono=True)
f.text(540, 120, "−", mono=True, size=16)
f.text(540, 210, "one subtraction, in compiled code", "uma subtração, em código compilado",
       size=10, fill="paper-dim")

FIGURES = [loop]
