"""Lesson 19: seaborn.

The charts are drawn from `le-mtd9h75r.json`, which `le-mtd9h75r-data.py` writes in the lab from the
same calculations as the lesson's cells.
"""
import json
import os

from draw import Fig

DATA = json.load(open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "le-mtd9h75r.json"),
                      encoding="utf-8"))


def axes_frame(f, x, y, w, h):
    f.line(x, y + h, x + w, y + h, stroke="paper-dim", width=1)
    f.line(x, y, x, y + h, stroke="paper-dim", width=1)


def num(v):
    return f"{v:,}", f"{v:,}".replace(",", ".")


def xtick(f, x, y, v, size=10):
    en, pt = num(v)
    f.line(x, y, x, y + 4, stroke="paper-dim", width=1)
    f.text(x, y + 14, en, pt, mono=True, size=size, fill="paper-dim")


def ytick(f, x, y, v, size=10):
    en, pt = num(v)
    f.line(x - 4, y, x, y, stroke="paper-dim", width=1)
    f.text(x - 8, y, en, pt, mono=True, size=size, fill="paper-dim", anchor="end")


# --- histogram ---------------------------------------------------------------------------------
hist = Fig(
    "hist", 720, 300,
    ("Histogram of trip lengths from 0 to 80 minutes in two-minute bars. The annual plan's bars are "
     "tall and peak around 10 to 12 minutes; the day plan's bars, drawn as outlines, are lower, peak "
     "around 16 to 18 minutes and spread further right.",
     "Histograma das durações de viagem de 0 a 80 minutos em barras de dois minutos. As barras do "
     "plano anual são altas e chegam ao máximo por volta de 10 a 12 minutos; as do plano diário, "
     "desenhadas só com contorno, são mais baixas, têm o máximo por volta de 16 a 18 minutos e se "
     "espalham mais para a direita."),
    ("What the cell draws, from the same numbers. The day passes' bars are outlines here so both can "
     "be seen.",
     "O que a célula desenha, a partir dos mesmos números. As barras dos passes diários aparecem só "
     "com contorno aqui para as duas serem vistas."))
f = hist
X, Y, W, H, HI = 80, 40, 600, 200, 3500
f.text(X + W / 2, 20, "Day passes ride longer, and their lengths spread wider", mono=True, size=12)
axes_frame(f, X, Y, W, H)
for v in (0, 1000, 2000, 3000):
    ytick(f, X, Y + H - v / HI * H, v)
bw = W / 40
for plan, fill, stroke in (("annual", "phosphor-dim", "phosphor"), ("day", None, "amber")):
    for i, c in enumerate(DATA["hist"][plan]):
        if c:
            top = Y + H - c / HI * H
            f.rect(X + i * bw, top, bw, Y + H - top, fill=fill, stroke=stroke, rx=0, width=1)
for m in (0, 20, 40, 60, 80):
    xtick(f, X + m / 80 * W, Y + H, m)
f.text(X + W / 2, Y + H + 32, "minutes", mono=True, size=10, fill="paper-dim")
f.text(X - 12, Y - 12, "count", mono=True, size=10, fill="paper-dim", anchor="end")
f.rect(X + W - 130, Y + 10, 14, 10, fill="phosphor-dim", stroke="phosphor", rx=0, width=1)
f.text(X + W - 110, Y + 15, "annual", mono=True, size=10, anchor="start")
f.rect(X + W - 130, Y + 30, 14, 10, fill=None, stroke="amber", rx=0, width=1)
f.text(X + W - 110, Y + 35, "day", mono=True, size=10, anchor="start")

# --- box plot ----------------------------------------------------------------------------------
box = Fig(
    "box", 720, 230,
    ("Two horizontal box plots of trip minutes. Annual: the box runs from about 9 to 18 minutes with "
     "the median at 12.4, the whiskers from 1.8 to 30.7, and 843 trips drawn as points beyond. Day: "
     "the box runs from 14 to 28 with the median at 19.9, the whiskers from 3.6 to 49.4, and 364 "
     "points beyond.",
     "Dois box plots horizontais dos minutos de viagem. Anual: a caixa vai de uns 9 a 18 minutos com a "
     "mediana em 12,4, os bigodes de 1,8 a 30,7, e 843 viagens desenhadas como pontos além deles. "
     "Diário: a caixa vai de 14 a 28 com a mediana em 19,9, os bigodes de 3,6 a 49,4, e 364 pontos "
     "além."),
    ("Every point right of a whisker is a real trip. A long tail draws many of them.",
     "Cada ponto à direita de um bigode é uma viagem real. Uma cauda longa desenha muitos deles."))
f = box
X, Y, W, H, HI = 80, 20, 620, 160, 180
axes_frame(f, X, Y, W, H)


def bx(v):
    return X + v / HI * W


for row, plan in enumerate(["day", "annual"]):
    s = DATA["box"][plan]
    cy = Y + 40 + row * 80
    f.text(X - 10, cy, plan, mono=True, size=11, anchor="end")
    f.line(bx(s["lo"]), cy, bx(s["q1"]), cy, stroke="paper", width=1.2)
    f.line(bx(s["q3"]), cy, bx(s["hi"]), cy, stroke="paper", width=1.2)
    f.line(bx(s["lo"]), cy - 10, bx(s["lo"]), cy + 10, stroke="paper", width=1.2)
    f.line(bx(s["hi"]), cy - 10, bx(s["hi"]), cy + 10, stroke="paper", width=1.2)
    f.rect(bx(s["q1"]), cy - 18, bx(s["q3"]) - bx(s["q1"]), 36,
           fill="phosphor-dim" if plan == "annual" else "panel",
           stroke="phosphor" if plan == "annual" else "amber", rx=0, width=1.2)
    f.line(bx(s["median"]), cy - 18, bx(s["median"]), cy + 18, stroke="paper", width=2)
    seen = set()
    for v in s["fliers"]:
        k = round(v)
        if k in seen:
            continue
        seen.add(k)
        f.rect(bx(v) - 2, cy - 2, 4, 4, fill=None, stroke="paper-dim", rx=2, width=0.8)
for m in (0, 30, 60, 90, 120, 150, 180):
    xtick(f, bx(m), Y + H, m)
f.text(X + W / 2, Y + H + 32, "minutes", mono=True, size=10, fill="paper-dim")

# --- scatter -----------------------------------------------------------------------------------
scatter = Fig(
    "scatter", 720, 300,
    ("Scatter plot of 359 days, rain in millimetres against trips. Weekdays form an upper band around "
     "110 trips and weekends a lower band around 70, while rain stays under 10 mm. Above 10 mm both "
     "bands drop, weekdays to around 60 trips and weekends to around 40.",
     "Gráfico de dispersão de 359 dias, chuva em milímetros contra viagens. Os dias úteis formam uma "
     "faixa de cima perto de 110 viagens e os fins de semana uma faixa de baixo perto de 70, enquanto "
     "a chuva fica abaixo de 10 mm. Acima de 10 mm as duas faixas caem, os dias úteis para perto de "
     "60 viagens e os fins de semana para perto de 40."),
    ("A step at 10 mm, not a slope. The dashed line marks 10 mm.",
     "Um degrau em 10 mm, não uma inclinação. A linha tracejada marca 10 mm."))
f = scatter
X, Y, W, H, XHI, YLO, YHI = 80, 30, 600, 210, 50, 20, 140
axes_frame(f, X, Y, W, H)
for v in (40, 60, 80, 100, 120, 140):
    ytick(f, X, Y + H - (v - YLO) / (YHI - YLO) * H, v)
for v in (0, 10, 20, 30, 40, 50):
    xtick(f, X + v / XHI * W, Y + H, v)
f.line(X + 10 / XHI * W, Y, X + 10 / XHI * W, Y + H, stroke="paper-dim", width=1, dash=True)
for rain, n, weekend in DATA["scatter"]:
    px, py = X + rain / XHI * W, Y + H - (n - YLO) / (YHI - YLO) * H
    if weekend:
        f.rect(px - 3, py - 3, 6, 6, fill="amber", stroke="amber", rx=3, width=0.5)
    else:
        f.rect(px - 3, py - 3, 6, 6, fill=None, stroke="phosphor", rx=3, width=1)
f.text(X + W / 2, Y + H + 32, "rain_mm", mono=True, size=10, fill="paper-dim")
f.text(X - 12, Y - 12, "trips", mono=True, size=10, fill="paper-dim", anchor="end")
f.rect(X + W - 150, Y + 8, 8, 8, fill=None, stroke="phosphor", rx=4, width=1)
f.text(X + W - 136, Y + 12, "weekend False", mono=True, size=10, anchor="start")
f.rect(X + W - 150, Y + 26, 8, 8, fill="amber", stroke="amber", rx=4, width=0.5)
f.text(X + W - 136, Y + 30, "weekend True", mono=True, size=10, anchor="start")

FIGURES = [hist, box, scatter]
