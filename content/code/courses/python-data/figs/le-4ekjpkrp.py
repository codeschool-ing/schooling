"""Lesson 18: matplotlib.

The charts are drawn from `le-4ekjpkrp.json`, which `le-4ekjpkrp-data.py` writes in the lab from the
same calculations as the lesson's cells, so a bar here is the length of the bar under the cell.
"""
import json
import os

from draw import Fig

DATA = json.load(open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "le-4ekjpkrp.json"),
                      encoding="utf-8"))
MONTHS = [("Jan", "jan"), ("Feb", "fev"), ("Mar", "mar"), ("Apr", "abr"), ("May", "mai"),
          ("Jun", "jun"), ("Jul", "jul"), ("Aug", "ago"), ("Sep", "set"), ("Oct", "out"),
          ("Nov", "nov"), ("Dec", "dez")]
MONTH_START = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334]


def axes_frame(f, x, y, w, h):
    f.line(x, y + h, x + w, y + h, stroke="paper-dim", width=1)
    f.line(x, y, x, y + h, stroke="paper-dim", width=1)


def yticks(f, x, y, h, lo, hi, ticks):
    for t in ticks:
        ty = y + h - (t - lo) / (hi - lo) * h
        f.line(x - 4, ty, x, ty, stroke="paper-dim", width=1)
        f.text(x - 8, ty, f"{t:,}", f"{t:,}".replace(",", "."), mono=True, size=10,
               fill="paper-dim", anchor="end")


# --- the anatomy ------------------------------------------------------------------------------
anatomy = Fig(
    "anatomy", 720, 300,
    ("A Figure, the whole picture, holds an Axes. The Axes holds the data area with its line, a "
     "title above it, an x axis and a y axis with their labels, and a legend. Methods of fig act on "
     "the picture; methods of ax act on the chart.",
     "Uma Figure, a imagem inteira, contém um Axes. O Axes contém a área de dados com a linha, um "
     "título acima, um eixo x e um eixo y com os rótulos, e uma legenda. Métodos de fig agem na "
     "imagem; métodos de ax agem no gráfico."),
    ("fig is the picture; ax is one chart inside it, with everything that belongs to that chart.",
     "fig é a imagem; ax é um gráfico dentro dela, com tudo o que pertence a esse gráfico."))
f = anatomy
f.rect(20, 20, 680, 260, fill="panel", stroke="wire", dash=True)
f.text(34, 36, "fig", mono=True, size=12, fill="amber", anchor="start", weight="600")
f.text(66, 36, "Figure: size, layout, savefig", "Figure: tamanho, layout, savefig", size=10,
       fill="paper-dim", anchor="start")
f.rect(90, 56, 420, 190, fill="ink", stroke="amber")
f.text(104, 72, "ax", mono=True, size=12, fill="amber", anchor="start", weight="600")
f.text(350, 72, "ax.set_title", mono=True, size=11)
axes_frame(f, 210, 90, 280, 120)
f.path("M210 180 L245 150 L280 165 L315 120 L350 140 L385 110 L420 130 L455 100 L490 115",
       stroke="paper", width=2)
f.text(350, 232, "ax.set_xlabel", mono=True, size=11)
f.text(104, 150, "ax.set_ylabel", mono=True, size=11, anchor="start")
f.rect(400, 170, 80, 30, fill="panel", stroke="wire", rx=2)
f.text(440, 185, "ax.legend", mono=True, size=10)
f.text(600, 100, "one chart:", "um gráfico:", size=10, fill="paper-dim")
f.text(600, 118, "its data, axes,", "seus dados, eixos,", size=10, fill="paper-dim")
f.text(600, 136, "title and legend", "título e legenda", size=10, fill="paper-dim")
f.line(560, 120, 514, 120, arrow=True)

# --- the line ---------------------------------------------------------------------------------
line = Fig(
    "line", 720, 300,
    ("Trips per day in 2025, drawn as a thin grey line that swings between about 30 and 134 every "
     "week, with the seven-day mean as a thick line in front of it, staying between about 70 and 106 "
     "all year with no slope.",
     "Viagens por dia em 2025, desenhadas como uma linha cinza fina que oscila entre uns 30 e 134 toda "
     "semana, com a média de sete dias como uma linha grossa na frente, ficando entre uns 70 e 106 o "
     "ano todo sem inclinação."),
    ("What the cell draws, from the same numbers: no trend, a weekly rhythm.",
     "O que a célula desenha, a partir dos mesmos números: sem tendência, um ritmo semanal."))
f = line
X, Y, W, H, LO, HI = 70, 40, 620, 200, 20, 140
f.text(X + W / 2, 18, "Trips per day in 2025: no trend, a weekly rhythm",
       "Trips per day in 2025: no trend, a weekly rhythm", mono=True, size=12)
axes_frame(f, X, Y, W, H)
yticks(f, X, Y, H, LO, HI, [40, 60, 80, 100, 120])


def px(i):
    return X + i / 364 * W


def py(v):
    return Y + H - (v - LO) / (HI - LO) * H


f.path("M" + " L".join(f"{px(i):.1f} {py(v):.1f}" for i, v in enumerate(DATA["daily"])),
       stroke="paper-dim", width=0.8)
pts = [(i, v) for i, v in enumerate(DATA["week"]) if v is not None]
f.path("M" + " L".join(f"{px(i):.1f} {py(v):.1f}" for i, v in pts), stroke="amber", width=2.5)
for m, start in enumerate(MONTH_START):
    f.line(px(start), Y + H, px(start), Y + H + 4, stroke="paper-dim", width=1)
    f.text(px(start) + 2, Y + H + 16, MONTHS[m][0], MONTHS[m][1], mono=True, size=10,
           fill="paper-dim", anchor="start")
f.text(X - 8, Y - 12, "trips", mono=True, size=10, fill="paper-dim", anchor="end")
f.line(X + 20, 278, X + 50, 278, stroke="paper-dim", width=0.8)
f.text(X + 58, 278, "each day", mono=True, size=10, anchor="start")
f.line(X + 150, 278, X + 180, 278, stroke="amber", width=2.5)
f.text(X + 188, 278, "7-day mean", mono=True, size=10, anchor="start")

# --- bars from zero, and cut ------------------------------------------------------------------
bars = Fig(
    "bars", 720, 290,
    ("Trips per month drawn twice. On the left the axis starts at zero and the twelve bars are nearly "
     "equal, from 2,519 in June to 3,011 in October. On the right the axis starts at 2,400 and June's "
     "bar is about a fifth as long as October's.",
     "Viagens por mês desenhadas duas vezes. À esquerda o eixo começa em zero e as doze barras são "
     "quase iguais, de 2.519 em junho a 3.011 em outubro. À direita o eixo começa em 2.400 e a barra "
     "de junho tem cerca de um quinto do comprimento da de outubro."),
    ("The same twelve numbers. Only the start of the axis differs.",
     "Os mesmos doze números. Só o começo do eixo muda."))
f = bars
for (X, LO, HI, ticks, en, pt) in [
        (70, 0, 3200, [0, 1000, 2000, 3000], "axis from 0", "eixo a partir de 0"),
        (430, 2400, 3100, [2400, 2600, 2800, 3000], "axis from 2,400", "eixo a partir de 2.400")]:
    Y, W, H = 40, 270, 200
    f.text(X + W / 2, 20, en, pt, size=11, weight="600")
    axes_frame(f, X, Y, W, H)
    yticks(f, X, Y, H, LO, HI, ticks)
    bw = W / 12
    for m, v in enumerate(DATA["monthly"]):
        top = Y + H - (v - LO) / (HI - LO) * H
        f.rect(X + m * bw + 3, top, bw - 6, Y + H - top, fill="phosphor-dim", stroke="phosphor",
               rx=0, width=1)
        if m % 2 == 0:
            f.text(X + m * bw + bw / 2, Y + H + 14, MONTHS[m][0], MONTHS[m][1], mono=True, size=9,
                   fill="paper-dim")
f.text(205, 278, "June ≈ October", "junho ≈ outubro", size=11, fill="amber")
f.text(565, 278, "June looks a fifth of October", "junho parece um quinto de outubro", size=11,
       fill="amber")

# --- clipped labels ---------------------------------------------------------------------------
clipped = Fig(
    "clipped", 720, 250,
    ("Two versions of the station chart. Left: the saved file, whose edge cuts the long names, so "
     "they read do Derby, da Aurora and spinheiro. Right: the same chart with layout constrained, the "
     "axes moved right inside the figure and every name whole.",
     "Duas versões do gráfico de estações. À esquerda: o arquivo salvo, cuja borda corta os nomes "
     "longos, que ficam do Derby, da Aurora e spinheiro. À direita: o mesmo gráfico com layout "
     "constrained, os eixos movidos para a direita dentro da figura e todos os nomes inteiros."),
    ("The four busiest stations of the chart, as the file was saved and as it should be.",
     "As quatro estações mais movimentadas do gráfico, como o arquivo foi salvo e como deveria ser."))
f = clipped
top4 = list(reversed(DATA["stations"][-4:]))
cut = ["do Derby", "da Aurora", "spinheiro", "Madalena"]
for (X0, label, labels, ax_x) in [(20, ("stations.png, as saved", "stations.png, como salvo"), cut, 82),
                                  (380, ("layout=\"constrained\"", "layout=\"constrained\""),
                                   [n for n, _ in top4], 520)]:
    f.rect(X0, 40, 320, 190, fill="ink", stroke="paper-dim", width=1.5)
    if label[0].startswith("layout"):
        f.text(X0 + 160, 24, label[0], mono=True, size=11, weight="600")
    else:
        f.text(X0 + 160, 24, label[0], label[1], size=11, weight="600")
    f.line(ax_x, 60, ax_x, 210, stroke="paper-dim", width=1)
    for i, ((name, v), shown) in enumerate(zip(top4, labels)):
        y = 70 + i * 36
        w = v / 4154 * (X0 + 300 - ax_x)
        f.rect(ax_x, y, w, 24, fill="phosphor-dim", stroke="phosphor", rx=0, width=1)
        f.text(ax_x - 4, y + 12, shown, mono=True, size=10, anchor="end")
f.text(30, 238, "the names begin outside the picture", "os nomes começam fora da imagem", size=10,
       fill="amber", anchor="start")

# --- small multiples --------------------------------------------------------------------------
small = Fig(
    "small", 720, 290,
    ("Trips per day in each hour, on two charts with one vertical scale. Monday to Friday has two "
     "peaks, near 12 trips at 7 in the morning and near 11 at 5 in the afternoon. Saturday and Sunday "
     "rise slowly to under 5 around midday and fall in the evening.",
     "Viagens por dia em cada hora, em dois gráficos com uma escala vertical só. De segunda a sexta "
     "há dois picos, perto de 12 viagens às 7 da manhã e perto de 11 às 5 da tarde. Sábado e domingo "
     "sobem devagar até menos de 5 por volta do meio-dia e caem à noite."),
    ("Weekdays have two rush hours; weekends have none. One scale for both, so the heights compare.",
     "Dias úteis têm dois horários de pico; fins de semana, nenhum. Uma escala para os dois, então as "
     "alturas se comparam."))
f = small
for (X, key, en, pt) in [(70, "weekday", "Monday to Friday", "Monday to Friday"),
                         (420, "weekend", "Saturday and Sunday", "Saturday and Sunday")]:
    Y, W, H, HI = 40, 280, 200, 12
    f.text(X + W / 2, 22, en, pt, mono=True, size=11)
    axes_frame(f, X, Y, W, H)
    if key == "weekday":
        yticks(f, X, Y, H, 0, HI, [0, 4, 8, 12])
    bw = W / 24
    for h, v in enumerate(DATA[key]):
        top = Y + H - v / HI * H
        f.rect(X + h * bw + 1, top, bw - 2, Y + H - top, fill="phosphor-dim", stroke="phosphor",
               rx=0, width=0.8)
    for h in (0, 6, 12, 18):
        f.text(X + h * bw + bw / 2, Y + H + 14, str(h), mono=True, size=9, fill="paper-dim")
    f.text(X + W / 2, Y + H + 32, "hour", mono=True, size=10, fill="paper-dim")

FIGURES = [anatomy, line, bars, clipped, small]
