"""Lesson 12's figures: charts of the course's own data. Every value drawn is
computed here from the rows of lesson 1's tables, the same numbers the
lesson's formulas and pivot table give (lab/l12.py prints them)."""
import math

from engine import rows
from fig import Svg

MONTHS = [(2025, m) for m in range(1, 13)] + [(2026, m) for m in range(1, 7)]
PT_MON = ["jan", "fev", "mar", "abr", "mai", "jun", "jul", "ago", "set", "out", "nov", "dez"]
EN_MON = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]


def _sales():
    head, *body = rows("Sales")
    return [dict(zip(head, r)) for r in body]


def _n(t, v, dec=0):
    s = f"{v:,.{dec}f}"
    return t(s, s.replace(",", "§").replace(".", ",").replace("§", "."))


def _pct(t, v):
    return t(f"{v:.1f}%", f"{v:.1f}%".replace(".", ","))


def _bar(s, x, y, w, h, fill):
    """A horizontal bar, square at the baseline (x) and 4px round at its end."""
    r = min(4, w / 2, h / 2)
    s.path(f"M{x:.1f} {y:.1f} L{x + w - r:.1f} {y:.1f} Q{x + w:.1f} {y:.1f} {x + w:.1f} {y + r:.1f} "
           f"L{x + w:.1f} {y + h - r:.1f} Q{x + w:.1f} {y + h:.1f} {x + w - r:.1f} {y + h:.1f} "
           f"L{x:.1f} {y + h:.1f} Z", stroke="none", fill=fill)


def _col(s, x, base, w, h, fill):
    """A column standing on `base`, rounded at the top."""
    if h <= 0:
        return
    r = min(3, w / 2, h)
    y = base - h
    s.path(f"M{x:.1f} {base:.1f} L{x:.1f} {y + r:.1f} Q{x:.1f} {y:.1f} {x + r:.1f} {y:.1f} "
           f"L{x + w - r:.1f} {y:.1f} Q{x + w:.1f} {y:.1f} {x + w:.1f} {y + r:.1f} L{x + w:.1f} {base:.1f} Z",
           stroke="none", fill=fill)


def pie_bar(t):
    by = {}
    for x in _sales():
        by[x["Product"]] = by.get(x["Product"], 0) + x["Price"] * x["Bags"]
    total = sum(by.values())
    order = sorted(by, key=lambda k: -by[k])
    a, b2 = order[0], order[1]
    s = Svg(760, 330, "l12-pie-bar", t(
        f"The revenue of the six products drawn twice. On the left, a pie: the two largest slices, {a} at "
        f"{100 * by[a] / total:.1f}% and {b2} at {100 * by[b2] / total:.1f}%, look the same size. On the "
        f"right, the same values as bars sorted from largest to smallest, starting at zero, with the value "
        f"at the end of each bar: {a} {by[a]}, {b2} {by[b2]}, and the other four far below.",
        f"A receita dos seis produtos desenhada duas vezes. À esquerda, uma pizza: as duas maiores fatias, "
        f"{a} com {100 * by[a] / total:.1f}% e {b2} com {100 * by[b2] / total:.1f}%, parecem do mesmo "
        f"tamanho. À direita, os mesmos valores em barras ordenadas da maior para a menor, a partir do zero, "
        f"com o valor na ponta de cada barra: {a} {by[a]}, {b2} {by[b2]}, e os outros quatro bem abaixo."))
    s.sans(40, 20, t("a pie: which slice is bigger?", "uma pizza: qual fatia é maior?"), size=12, weight="600")
    cx, cy, r = 170, 175, 115
    ang = -math.pi / 2
    fills = {a: "var(--phosphor)", b2: "var(--amber)"}
    for k in order:
        sweep = 2 * math.pi * by[k] / total
        x1, y1 = cx + r * math.cos(ang), cy + r * math.sin(ang)
        x2, y2 = cx + r * math.cos(ang + sweep), cy + r * math.sin(ang + sweep)
        large = 1 if sweep > math.pi else 0
        s.path(f"M{cx} {cy} L{x1:.1f} {y1:.1f} A{r} {r} 0 {large} 1 {x2:.1f} {y2:.1f} Z",
               stroke="var(--ink)", sw=2, fill=fills.get(k, "var(--wire)"))
        mid = ang + sweep / 2
        if k in fills:
            lx, ly = cx + (r + 18) * math.cos(mid), cy + (r + 18) * math.sin(mid)
            s.mono(lx, ly, k, size=11, anchor="start" if math.cos(mid) > 0 else "end", weight="600")
        ang += sweep
    s.sans(40, 316, t("the four small slices together: ", "as quatro fatias pequenas juntas: ")
           + _pct(t, 100 * sum(by[k] for k in order[2:]) / total), size=10.5, fill="var(--paper-dim)")
    # Bars.
    x0, y0, bh, gap = 470, 60, 22, 16
    s.sans(400, 20, t("bars, sorted, from zero", "barras, ordenadas, a partir do zero"), size=12, weight="600")
    s.line(x0, y0 - 8, x0, y0 + 6 * (bh + gap) - gap + 8, stroke="var(--wire)")
    scale = 200 / by[a]
    for i, k in enumerate(order):
        y = y0 + i * (bh + gap)
        s.mono(x0 - 8, y + bh / 2, k, size=11, anchor="end")
        w = by[k] * scale
        _bar(s, x0, y, w, bh, fills.get(k, "var(--phosphor-dim)"))
        s.mono(x0 + w + 6, y + bh / 2, _n(t, by[k]), size=10.5, fill="var(--paper)")
    s.sans(400, 316, t(f"{a} leads {b2} by R$ {by[a] - by[b2]}, which the pie cannot show",
                       f"{a} passa {b2} por R$ {by[a] - by[b2]}, o que a pizza não consegue mostrar"),
           size=10.5, fill="var(--paper-dim)")
    cap = t("The same six numbers as a pie and as sorted bars. An eye compares lengths along one baseline "
            "far better than angles, so the bars show what the pie hides: which product leads, and by how "
            "little.",
            "Os mesmos seis números como pizza e como barras ordenadas. O olho compara comprimentos sobre uma "
            "mesma linha de base muito melhor que ângulos, então as barras mostram o que a pizza esconde: "
            "qual produto lidera, e por quão pouco.")
    return s, cap


def _monthly():
    rev, bags = {k: 0 for k in MONTHS}, {k: 0 for k in MONTHS}
    for x in _sales():
        k = (x["Date"].year, x["Date"].month)
        rev[k] += x["Price"] * x["Bags"]
        bags[k] += x["Bags"]
    return [rev[k] for k in MONTHS], [bags[k] for k in MONTHS]


def two_axes(t):
    rev, bags = _monthly()
    s = Svg(760, 330, "l12-two-axes", t(
        "Two copies of one combo chart of Café Serra's months, January 2025 to June 2026: revenue as "
        "columns on the left axis, from 0 to 6,000 reais, and bags as a line on a second axis on the right. "
        "In the first copy the right axis runs from 0 to 60 and the line rides on top of the columns. In "
        "the second it runs from 0 to 200 and the same line lies flat along the bottom.",
        "Duas cópias do mesmo gráfico de combinação dos meses da Café Serra, de janeiro de 2025 a junho de "
        "2026: a receita em colunas no eixo da esquerda, de 0 a 6.000 reais, e os sacos em linha num "
        "segundo eixo, à direita. Na primeira cópia o eixo da direita vai de 0 a 60 e a linha acompanha o "
        "topo das colunas. Na segunda vai de 0 a 200 e a mesma linha fica achatada no fundo."))
    # Legend: two series, so a legend; the marks carry the colour, the text does not.
    s.rect(40, 14, 12, 12, fill="var(--phosphor-dim)", stroke="none", rx=2)
    s.sans(58, 20, t("revenue, left axis (R$)", "receita, eixo da esquerda (R$)"), size=10.5)
    s.line(250, 20, 266, 20, stroke="var(--amber)", sw=2)
    s.sans(272, 20, t("bags, right axis", "sacos, eixo da direita"), size=10.5)
    panels = [(40, 60, t("right axis from 0 to 60", "eixo da direita de 0 a 60"),
               t("bags seem to follow revenue", "os sacos parecem seguir a receita")),
              (420, 200, t("right axis from 0 to 200", "eixo da direita de 0 a 200"),
               t("bags seem not to move at all", "os sacos parecem nem se mexer"))]
    top, base = 70, 270
    for px, rmax, title, story in panels:
        s.sans(px, 50, title, size=11.5, weight="600")
        left, right = px + 40, px + 290
        for v in (0, 2000, 4000, 6000):
            y = base - (base - top) * v / 6000
            s.line(left, y, right, y, stroke="var(--scan)")
            s.mono(left - 6, y, t(f"{v // 1000}K", f"{v // 1000} mil") if v else "0", size=9.5,
                   fill="var(--paper-dim)", anchor="end")
        for i in range(5):
            v = rmax * i // 4 if rmax == 200 else rmax * i // 3
            if i == 4 and rmax == 60:
                break
            y = base - (base - top) * v / rmax
            s.mono(right + 6, y, str(v), size=9.5, fill="var(--paper-dim)")
        step = (right - left) / len(rev)
        for i, v in enumerate(rev):
            _col(s, left + i * step + 2, base, step - 4, (base - top) * v / 6000, "var(--phosphor-dim)")
        pts = " L".join(f"{left + i * step + step / 2:.1f} {base - (base - top) * v / rmax:.1f}"
                        for i, v in enumerate(bags))
        s.parts.append(f'<path d="M{pts}" stroke="var(--amber)" stroke-width="2" fill="none" '
                       f'stroke-linejoin="round" stroke-linecap="round"></path>')
        s.line(left, base, right, base, stroke="var(--wire)")
        for i, lab in ((0, t("Jan 2025", "jan 2025")), (12, t("Jan 2026", "jan 2026")),
                       (17, t("Jun", "jun"))):
            s.sans(left + i * step + step / 2, base + 14, lab, size=9.5, fill="var(--paper-dim)",
                   anchor="middle")
        s.sans(px, 312, story, size=10.5, fill="var(--paper-dim)")
    cap = t("Same data, same chart, two settings of the right-hand axis. Where a second axis puts its line "
            "is a choice somebody made, so a combo chart with two axes can be made to tell either story.",
            "Mesmos dados, mesmo gráfico, dois ajustes do eixo da direita. Onde um segundo eixo põe a linha "
            "é uma escolha de alguém, então um gráfico de combinação com dois eixos pode contar qualquer "
            "uma das duas histórias.")
    return s, cap


def sparklines(t):
    per = {}
    for x in _sales():
        p = per.setdefault(x["Product"], {k: 0 for k in MONTHS})
        p[(x["Date"].year, x["Date"].month)] += x["Bags"]
    codes = sorted(per)
    top_all = max(max(v.values()) for v in per.values())
    s = Svg(760, 300, "l12-sparklines", t(
        f"Bags sold per month, January 2025 to June 2026, as one small line per product, drawn twice. "
        f"In the first column every line is scaled to its own highest month, so CER250, whose best month "
        f"was {max(per['CER250'].values())} bags, swings as wildly as CER1K, whose best was "
        f"{max(per['CER1K'].values())}. In the second column every line shares one scale, from 0 to "
        f"{top_all} bags, and the small products lie almost flat.",
        f"Sacos vendidos por mês, de janeiro de 2025 a junho de 2026, numa linha pequena por produto, "
        f"desenhada duas vezes. Na primeira coluna cada linha tem a escala do próprio mês mais alto, então "
        f"CER250, cujo melhor mês teve {max(per['CER250'].values())} sacos, oscila tanto quanto CER1K, cujo "
        f"melhor teve {max(per['CER1K'].values())}. Na segunda coluna todas as linhas dividem uma escala, "
        f"de 0 a {top_all} sacos, e os produtos pequenos ficam quase retos."))
    cols = [(130, t("each sparkline, its own scale", "cada minigráfico, a própria escala")),
            (400, t("one scale for all, 0 to ", "uma escala para todos, de 0 a ") + str(top_all))]
    for x, title in cols:
        s.sans(x, 22, title, size=11.5, weight="600")
    s.sans(668, 22, t("best month", "melhor mês"), size=11.5, weight="600")
    w, h, y0, rh = 230, 26, 44, 40
    for r, code in enumerate(codes):
        vals = [per[code][k] for k in MONTHS]
        y = y0 + r * rh
        s.rect(30, y - 4, 700, rh - 4, fill="var(--panel)", stroke="none", rx=3)
        s.mono(44, y + h / 2, code, size=11, weight="600")
        own = max(vals)
        for x, mx in ((130, own), (400, top_all)):
            step = w / (len(vals) - 1)
            pts = [(x + i * step, y + h - h * v / mx) for i, v in enumerate(vals)]
            d = " L".join(f"{px:.1f} {py:.1f}" for px, py in pts)
            s.parts.append(f'<path d="M{d}" stroke="var(--phosphor)" stroke-width="1.6" fill="none" '
                           f'stroke-linejoin="round" stroke-linecap="round"></path>')
            hi = vals.index(own)
            s.parts.append(f'<circle cx="{pts[hi][0]:.1f}" cy="{pts[hi][1]:.1f}" r="3.5" fill="var(--amber)" '
                           f'stroke="var(--panel)" stroke-width="1.5"></circle>')
        s.mono(712, y + h / 2, str(own), size=11, anchor="end")
    s.sans(130, 290, t("the dot marks the high point, as Sparkline › High Point does",
                       "o ponto marca o ponto alto, como Minigráfico › Ponto Alto faz"),
           size=10.5, fill="var(--paper-dim)")
    cap = t("Sparklines scaled one by one show the shape of each product's months and hide their size; "
            "one shared scale shows the size and flattens the small ones. Which is right depends on whether "
            "the rows are being compared with each other.",
            "Minigráficos com escala própria mostram a forma dos meses de cada produto e escondem o tamanho; "
            "uma escala comum mostra o tamanho e achata os pequenos. Qual está certo depende de as linhas "
            "estarem sendo comparadas entre si.")
    return s, cap


FIGS = {"l12-pie-bar": pie_bar, "l12-two-axes": two_axes, "l12-sparklines": sparklines}
