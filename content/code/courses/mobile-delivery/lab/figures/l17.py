"""Lesson 17: the four cohorts as curves."""
from fig import Fig

DATA = {"2026-09-07": [100, 36, 25, 23, 22], "2026-09-14": [100, 41, 30, 25, 25],
        "2026-09-21": [100, 37, 26, 20, 19], "2026-09-28": [100, 38, 24, 22]}
T = {
    "en": dict(aria="Four retention curves, one per weekly cohort of September 2026. All four start at 100% in week 0, fall to between 36% and 41% in week 1, and then flatten: between 24% and 30% in week 2, 20% to 25% in week 3, and 19% to 25% in week 4, where the last cohort has no data yet.",
               week="week", y="share of the cohort that opened the app",
               drop="the first week loses six in ten", flat="then the curve flattens",
               cap="The four cohorts drawn from the table. The steep part is week 1 and the flat part is the people the app is for; every curve has the same shape."),
    "pt": dict(aria="Quatro curvas de retenção, uma por coorte semanal de setembro de 2026. As quatro começam em 100% na semana 0, caem para entre 36% e 41% na semana 1, e então se achatam: entre 24% e 30% na semana 2, de 20% a 25% na semana 3, e de 19% a 25% na semana 4, em que a última coorte ainda não tem dados.",
               week="semana", y="fração da coorte que abriu o app",
               drop="a primeira semana perde seis em dez", flat="depois a curva se achata",
               cap="As quatro coortes desenhadas a partir da tabela. A parte íngreme é a semana 1 e a parte plana são as pessoas para quem o app existe; toda curva tem a mesma forma."),
}


def figures(lang):
    t = T[lang]
    f = Fig("l17-curves", 720, 280, t["aria"])
    x0, x1, y0, y1 = 90, 520, 230, 30
    X = lambda w: x0 + w * (x1 - x0) / 4
    Y = lambda v: y0 - v * (y0 - y1) / 100
    for v in (0, 25, 50, 75, 100):
        f.arrow([(x0 - 6, Y(v)), (x1 + 10, Y(v))], color="wire", head=False, width=0.6)
        f.text(x0 - 12, Y(v), f"{v}%", anchor="end", mono=True, size=9, fill="paper-dim")
    for w in range(5):
        f.text(X(w), y0 + 16, str(w), mono=True, size=9, fill="paper-dim")
    f.text((x0 + x1) / 2, y0 + 34, t["week"], size=9.5, fill="paper-dim")
    f.text(20, 12, t["y"], anchor="start", size=9.5, fill="paper-dim")
    colors = ["phosphor", "amber", "paper", "paper-dim"]
    for (name, vals), c in zip(DATA.items(), colors):
        f.arrow([(X(i), Y(v)) for i, v in enumerate(vals)], color=c, head=False, width=1.6)
    for i, ((name, vals), c) in enumerate(zip(DATA.items(), colors)):
        ly = 180 + i * 18
        f.arrow([(560, ly), (590, ly)], color=c, head=False, width=1.6)
        f.text(598, ly, name, anchor="start", mono=True, size=8.5, fill=c)
    f.text(560, 60, t["drop"], anchor="start", size=9.5, fill="amber", italic=True)
    f.text(560, 100, t["flat"], anchor="start", size=9.5, fill="amber", italic=True)
    return {"l17-curves": f.json(t["cap"])}
