"""Lesson 2: the figure of the-time-zone."""
from fig import Fig

T = {
    "en": dict(
        aria="Two timelines, one above the other, covering Tuesday 20 and Wednesday 21 October 2026. The upper one is UTC, the lower one is São Paulo, three hours behind. new Date(\"2026-10-21\") is marked at midnight on the 21st in UTC, and the same instant falls at 21:00 on Tuesday the 20th in São Paulo. getDay() reads the lower line and answers Tuesday, so the week computed from it starts a day late.",
        utc="UTC", sp="São Paulo (UTC−3)",
        tue="Tuesday 20", wed="Wednesday 21",
        mark='new Date("2026-10-21")', inst="the same instant",
        reads="getDay() reads this line: Tuesday",
        cap="A date with no time is read as midnight in UTC. Three hours behind, that instant is still the evening before, and every local method answers for the evening before.",
    ),
    "pt": dict(
        aria="Duas linhas do tempo, uma acima da outra, cobrindo a terça 20 e a quarta 21 de outubro de 2026. A de cima é o UTC, a de baixo é São Paulo, três horas atrás. new Date(\"2026-10-21\") está marcado à meia-noite do dia 21 no UTC, e o mesmo instante cai às 21:00 da terça 20 em São Paulo. O getDay() lê a linha de baixo e responde terça, então a semana calculada a partir dele começa um dia atrasada.",
        utc="UTC", sp="São Paulo (UTC−3)",
        tue="terça 20", wed="quarta 21",
        mark='new Date("2026-10-21")', inst="o mesmo instante",
        reads="o getDay() lê esta linha: terça",
        cap="Uma data sem hora é lida como meia-noite no UTC. Três horas atrás, esse instante ainda é a noite anterior, e todo método local responde pela noite anterior.",
    ),
}


def figures(lang):
    t = T[lang]
    f = Fig("l02-midnight", 720, 230, t["aria"])
    x0, x1 = 150, 690          # 48 hours: Tue 00:00 UTC .. Thu 00:00 UTC
    hx = (x1 - x0) / 48

    def line(y, label, shift):
        f.text(x0 - 12, y, label, anchor="end", size=9.5, bold=True)
        f.arrow([(x0, y), (x1, y)], head=False, color="wire")
        # day boundaries in this zone's local time: shift hours after UTC midnight
        for d, name in ((0, t["tue"]), (24, t["wed"])):
            xb = x0 + (d + shift) * hx
            if x0 <= xb <= x1:
                f.arrow([(xb, y - 8), (xb, y + 8)], head=False, color="paper-dim")
                f.text(xb + 4, y - 14, name, anchor="start", size=9, fill="paper-dim")
    line(70, t["utc"], 0)
    line(160, t["sp"], 3)
    xi = x0 + 24 * hx
    f.arrow([(xi, 40), (xi, 172)], head=False, color="amber", dashed=True)
    f.text(xi, 28, t["mark"], mono=True, size=9.5, fill="amber")
    f.text(xi + 6, 100, t["inst"], anchor="start", size=9, fill="amber", italic=True)
    f.rect(x0 + 3 * hx, 176, 24 * hx, 22, stroke="phosphor", fill="panel", width=1)
    f.text(x0 + 15 * hx, 187, t["reads"], size=9)
    f.text(xi - 6, 145, "21:00", anchor="end", mono=True, size=9, fill="amber")
    f.text(xi - 6, 84, "00:00", anchor="end", mono=True, size=9, fill="amber")
    return {"l02-midnight": f.json(t["cap"], same=["UTC", "São Paulo (UTC−3)"] if lang == "pt" else None)}
