"""Lesson 11: loc, iloc and Copy-on-Write."""
from draw import Fig

chained = Fig(
    "chained", 720, 230,
    ("Top: trips[\"bike\"][mask] = \"e-bike\". The first brackets make a separate object from the bike "
     "column; the assignment lands in that object, which is thrown away, and trips is unchanged. Bottom: "
     "trips.loc[mask, \"bike\"] = \"e-bike\". One step, and the assignment lands in trips.",
     "Em cima: trips[\"bike\"][mask] = \"e-bike\". Os primeiros colchetes criam um objeto separado a partir "
     "da coluna bike; a atribuição cai nesse objeto, que é jogado fora, e trips não muda. Embaixo: "
     "trips.loc[mask, \"bike\"] = \"e-bike\". Um passo, e a atribuição cai em trips."),
    ("Two selections then an assignment write into the middle object. One loc writes into the table.",
     "Duas seleções e depois uma atribuição escrevem no objeto do meio. Um loc escreve na tabela."))
f = chained
f.text(20, 22, 'trips["bike"][mask] = "e-bike"', mono=True, anchor="start", weight="600")
f.box(20, 40, 150, 60, "trips", mono=True, sub=("unchanged", "não muda"))
f.box(285, 40, 170, 60, 'trips["bike"]', mono=True, sub=("a separate object", "um objeto separado"))
f.box(560, 40, 140, 60, "= \"e-bike\"", mono=True, sub=("lands here, then lost", "cai aqui, e se perde"),
      stroke="amber", ink="amber")
f.line(174, 70, 281, 70, arrow=True)
f.line(459, 70, 556, 70, arrow=True, stroke="amber")
f.text(20, 140, 'trips.loc[mask, "bike"] = "e-bike"', mono=True, anchor="start", weight="600")
f.box(20, 158, 150, 60, "trips", mono=True, sub=("changed in place", "muda no lugar"), stroke="phosphor")
f.box(285, 158, 170, 60, "one step", "um passo", sub=("rows and column together", "linhas e coluna juntas"))
f.line(281, 188, 174, 188, arrow=True, stroke="phosphor")

FIGURES = [chained]
