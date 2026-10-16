"""Lesson 14: merge, join and concat."""
from draw import Fig

how = Fig(
    "how", 720, 250,
    ("The keys each kind of join keeps. Left has S01, S02 and S03; right has S02, S03 and S04. Inner "
     "keeps S02 and S03. Left keeps S01, S02 and S03. Right keeps S02, S03 and S04. Outer keeps all "
     "four.",
     "As chaves que cada tipo de junção mantém. A esquerda tem S01, S02 e S03; a direita tem S02, S03 e "
     "S04. Inner mantém S02 e S03. Left mantém S01, S02 e S03. Right mantém S02, S03 e S04. Outer "
     "mantém as quatro."),
    ("Which keys survive each how. A dashed cell is a key the join dropped.",
     "Que chaves sobrevivem a cada how. Uma célula tracejada é uma chave que a junção descartou."))
f = how
keys = ["S01", "S02", "S03", "S04"]
x0, cw = 260, 100

for i, k in enumerate(keys):
    f.text(x0 + i * cw + cw / 2, 14, k, mono=True, size=11, weight="600")
f.text(130, 34, "in left", "na esquerda", size=10, fill="paper-dim", anchor="end")
f.text(130, 60, "in right", "na direita", size=10, fill="paper-dim", anchor="end")
for i, k in enumerate(keys):
    cx = x0 + i * cw + cw / 2
    f.text(cx, 34, "yes" if k != "S04" else "no", "sim" if k != "S04" else "não", size=10,
           fill="paper-dim")
    f.text(cx, 60, "yes" if k != "S01" else "no", "sim" if k != "S01" else "não", size=10,
           fill="paper-dim")
f.line(150, 80, 690, 80, stroke="wire", width=1)
rows = [("inner", {"S02", "S03"}), ("left", {"S01", "S02", "S03"}),
        ("right", {"S02", "S03", "S04"}), ("outer", set(keys))]
for r, (name, kept) in enumerate(rows):
    y = 92 + r * 38
    f.text(130, y + 14, f'how="{name}"', mono=True, size=11, anchor="end")
    for i, k in enumerate(keys):
        x = x0 + i * cw + 10
        if k in kept:
            f.box(x, y, cw - 20, 28, k, mono=True, size=11, weight=None)
        else:
            f.rect(x, y, cw - 20, 28, fill=None, dash=True)

fanout = Fig(
    "fanout", 720, 240,
    ("Three trips, two from S07 and one from S05, merged with a station table that has two rows for "
     "S07. Each S07 trip matches both S07 rows, so the result has five rows: each S07 trip appears "
     "twice, once as Rua da Hora and once as Espinheiro.",
     "Três viagens, duas da S07 e uma da S05, unidas a uma tabela de estações com duas linhas para a "
     "S07. Cada viagem da S07 casa com as duas linhas da S07, então o resultado tem cinco linhas: cada "
     "viagem da S07 aparece duas vezes, uma como Rua da Hora e outra como Espinheiro."),
    ("Two rows for one key on the right: every trip with that key comes out twice.",
     "Duas linhas para uma chave à direita: toda viagem com essa chave sai duas vezes."))
f = fanout
f.text(90, 22, "trips", "viagens", weight="600")
f.text(360, 22, "stations", "estações", weight="600")
f.text(615, 22, "result", "resultado", weight="600")
trip_rows = [("1  S07", 60), ("2  S07", 110), ("3  S05", 160)]
for label, y in trip_rows:
    f.box(20, y - 16, 140, 32, label, mono=True, size=11, weight=None)
st_rows = [("S07  Rua da Hora", 60), ("S07  Espinheiro", 110), ("S05  Praça do Derby", 160)]
for label, y in st_rows:
    f.box(265, y - 16, 190, 32, label, mono=True, size=11, weight=None)
f.line(164, 60, 261, 60, arrow=True)
f.line(164, 60, 261, 110, arrow=True)
f.line(164, 110, 261, 60, arrow=True)
f.line(164, 110, 261, 110, arrow=True)
f.line(164, 160, 261, 160, arrow=True)
res = ["1  Rua da Hora", "1  Espinheiro", "2  Rua da Hora", "2  Espinheiro", "3  Praça do Derby"]
for i, label in enumerate(res):
    f.box(520, 40 + i * 38, 190, 30, label, mono=True, size=11, weight=None,
          stroke="amber" if i < 4 else "wire")
f.text(360, 215, "3 trips in, 5 rows out", "3 viagens entram, 5 linhas saem", size=11,
       fill="amber")
f.line(459, 110, 516, 110, arrow=True)

asof = Fig(
    "asof", 720, 230,
    ("A timeline of 2025 for station S07. One station row starts on 1 January with the name Rua da "
     "Hora, another on 1 July with the name Espinheiro. A trip in March looks back to the January row; "
     "a trip in September looks back to the July row.",
     "Uma linha do tempo de 2025 para a estação S07. Uma linha de estação começa em 1º de janeiro com o "
     "nome Rua da Hora, outra em 1º de julho com o nome Espinheiro. Uma viagem em março olha para trás "
     "até a linha de janeiro; uma viagem em setembro olha para trás até a linha de julho."),
    ("Each trip takes the last station row whose valid_from is on or before its start.",
     "Cada viagem pega a última linha de estação cujo valid_from é igual ou anterior ao seu início."))
f = asof
X0, X1 = 60, 680
def mx(m):  # x of the start of month m (1..13)
    return X0 + (X1 - X0) * (m - 1) / 12
f.line(X0, 120, X1, 120, stroke="paper-dim", width=1.5)
for m, (en, pt) in enumerate([("Jan", "jan"), ("Apr", "abr"), ("Jul", "jul"), ("Oct", "out")]):
    x = mx(1 + 3 * m)
    f.line(x, 114, x, 126, stroke="paper-dim", width=1)
    f.text(x + 6, 106, en, pt, size=10, fill="paper-dim", anchor="start")
f.box(mx(1) - 10, 40, 170, 44, "Rua da Hora", "Rua da Hora", sub=("valid_from 2025-01-01",), sub_mono=True,
      size=12, weight="600")
f.box(mx(7) - 10, 40, 170, 44, "Espinheiro", "Espinheiro", sub=("valid_from 2025-07-01",), sub_mono=True,
      size=12, weight="600")
f.line(mx(1), 84, mx(1), 116, stroke="phosphor", width=1.5)
f.line(mx(7), 84, mx(7), 116, stroke="phosphor", width=1.5)
for m, target, (en, pt) in [(3.5, 1, ("trip in March", "viagem em março")),
                            (9.5, 7, ("trip in September", "viagem em setembro"))]:
    x = mx(m)
    f.rect(x - 6, 164, 12, 12, fill="amber", stroke="amber", rx=6)
    f.text(x, 196, en, pt, size=10, fill="paper")
    f.path(f"M{x - 8} 170 Q{(x + mx(target)) / 2} 205 {mx(target) + 4} 128", stroke="amber",
           arrow=True)

FIGURES = [how, fanout, asof]
