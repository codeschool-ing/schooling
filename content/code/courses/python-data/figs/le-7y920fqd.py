"""Lesson 13: groupby."""
from draw import Fig

sac = Fig(
    "sac", 720, 260,
    ("Split: the trips table is divided into two groups by plan, annual and day. Apply: the mean of "
     "minutes is computed in each group, 14.1 and 22.6. Combine: the two means form one Series indexed "
     "by plan.",
     "Dividir: a tabela de viagens é separada em dois grupos por plano, annual e day. Aplicar: a média de "
     "minutes é calculada em cada grupo, 14.1 e 22.6. Combinar: as duas médias formam uma Series indexada "
     "por plano."),
    ("trips.groupby(\"plan\")[\"minutes\"].mean(): split by plan, a mean per group, one Series.",
     "trips.groupby(\"plan\")[\"minutes\"].mean(): dividir por plano, uma média por grupo, uma Series."))
f = sac
f.text(85, 20, "split", "dividir", weight="600")
f.text(360, 20, "apply", "aplicar", weight="600")
f.text(620, 20, "combine", "combinar", weight="600")
f.box(20, 40, 130, 190, "trips", mono=True, sub=("33,337 rows", "33.337 linhas"))
f.box(260, 40, 200, 80, "plan == annual", mono=True, weight=None, sub=("23,438 rows", "23.438 linhas"))
f.box(260, 150, 200, 80, "plan == day", mono=True, weight=None, sub=("9,899 rows", "9.899 linhas"))
f.line(154, 110, 256, 80, arrow=True)
f.line(154, 160, 256, 190, arrow=True)
f.text(360, 136, "mean of minutes", "média de minutes", size=10, fill="paper-dim")
f.rect(540, 70, 160, 130)
f.text(580, 110, "annual", mono=True, size=11, fill="paper-dim")
f.text(660, 110, "14.1", mono=True, size=12, fill="amber")
f.text(580, 160, "day", mono=True, size=11, fill="paper-dim")
f.text(660, 160, "22.6", mono=True, size=12, fill="amber")
f.line(464, 80, 536, 110, arrow=True)
f.line(464, 190, 536, 160, arrow=True)

FIGURES = [sac]
