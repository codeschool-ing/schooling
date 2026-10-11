"""Lesson 9's figures. The numbers they draw are taken from the pasted data
here and checked against Calc's by lab/l09.py, which prints the same grid and
the same counts."""
from collections import defaultdict

from engine import rows
from fig import Svg

SALES = rows("Sales")[1:]
MONTHS = [(2025 + i // 12, i % 12 + 1) for i in range(18)]
CHANNELS = ("Wholesale", "Online", "Shop")
MON_EN = "Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec".split()
MON_PT = "jan fev mar abr mai jun jul ago set out nov dez".split()


def shade(s, x, y, w, h, frac):
    s.rect(x, y, w, h, fill="var(--panel)", stroke="var(--wire)")
    if frac > 0:
        s.parts.append(f'<rect x="{x:.1f}" y="{y:.1f}" width="{w:.1f}" height="{h:.1f}" fill="var(--phosphor)" '
                       f'fill-opacity="{0.06 + 0.5 * frac:.2f}" stroke="none"></rect>')


def anchor(t):
    s = Svg(760, 250, "l09-anchor", t(
        "Three copies of the first six rows of Sales, columns A to H, each coloured by the same rule with "
        "the dollar sign in a different place. With $G2, rows 2 and 3, the wholesale sales, are coloured "
        "across all eight columns. With G2, only cells A2 and A3 are coloured. With $G$2, every cell is "
        "coloured.",
        "Três cópias das seis primeiras linhas de Sales, colunas A a H, cada uma colorida pela mesma regra "
        "com o cifrão num lugar diferente. Com $G2, as linhas 2 e 3, as vendas de atacado, ficam coloridas "
        "nas oito colunas. Com G2, só as células A2 e A3. Com $G$2, todas as células."))
    chans = [r[6] for r in SALES[:6]]
    rules = [('=$G2="Wholesale"', lambda r, c: chans[r] == "Wholesale",
              t("the right rows: 304 cells", "as linhas certas: 304 células")),
             ('=G2="Wholesale"', lambda r, c: c == 0 and chans[r] == "Wholesale",
              t("column A only: 38 cells", "só a coluna A: 38 células")),
             ('=$G$2="Wholesale"', lambda r, c: chans[0] == "Wholesale",
              t("everything: 864 cells", "tudo: 864 células"))]
    cw, rh = 25, 20
    for p, (rule, on, result) in enumerate(rules):
        x0, y0 = 40 + p * 245, 62
        s.mono(x0, 18, rule, size=11.5, weight="600", fill="var(--amber)")
        s.sans(x0, 38, result, size=11)
        for c, letter in enumerate("ABCDEFGH"):
            s.mono(x0 + c * cw + cw / 2, y0 - 9, letter, size=9.5, anchor="middle",
                   fill="var(--amber)" if letter == "G" else "var(--paper-dim)")
        for r in range(6):
            s.mono(x0 - 6, y0 + r * rh + rh / 2, str(r + 2), size=9.5, anchor="end", fill="var(--paper-dim)")
            for c in range(8):
                lit = on(r, c)
                s.rect(x0 + c * cw, y0 + r * rh, cw, rh, fill="var(--amber)" if lit else "var(--panel)")
                if c == 6:
                    s.mono(x0 + c * cw + cw / 2, y0 + r * rh + rh / 2 + 0.5, chans[r][0], size=9.5,
                           anchor="middle", fill="var(--ink)" if lit else "var(--paper)")
    s.sans(40, 207, t("Column G holds the channel: W for Wholesale, O for Online, S for Shop.",
                      "A coluna G guarda o canal: W de Wholesale, O de Online, S de Shop."),
           size=10.5, fill="var(--paper-dim)")
    s.sans(40, 225, t("The counts under each formula are for all 108 rows and eight columns.",
                      "As contagens sob cada fórmula valem para as 108 linhas e oito colunas."),
           size=10.5, fill="var(--paper-dim)")
    cap = t("One rule, three places for the dollar sign. Fixing the column of the test and leaving the row "
            "free makes every cell of a row ask about its own row's channel.",
            "Uma regra, três lugares para o cifrão. Fixar a coluna do teste e deixar a linha livre faz cada "
            "célula de uma linha perguntar pelo canal da própria linha.")
    return s, cap


def heat(t):
    rev = defaultdict(int)
    for r in SALES:
        rev[(r[1].year, r[1].month, r[6])] += r[4] * r[5]
    grid = [[rev[(y, m, ch)] for ch in CHANNELS] for y, m in MONTHS]
    s = Svg(760, 440, "l09-heat", t(
        "The same grid of revenue by month and channel, January 2025 to June 2026, shaded twice. On the "
        "left one colour scale covers all three channels: the Wholesale column is dark and the Shop column "
        "pale all the way down. On the right each column has its own scale, and each channel's strong and "
        "empty months show, including the Shop's four months with no sales.",
        "A mesma grade de receita por mês e canal, de janeiro de 2025 a junho de 2026, sombreada duas vezes. "
        "À esquerda uma escala de cor cobre os três canais: a coluna Wholesale fica escura e a coluna Shop "
        "clara de cima a baixo. À direita cada coluna tem sua escala, e aparecem os meses fortes e vazios "
        "de cada canal, inclusive os quatro meses da loja sem vendas."))
    allmax = max(max(row) for row in grid)
    colmax = [max(row[c] for row in grid) for c in range(3)]
    mw, cw, rh = 62, 62, 19
    panels = [(30, t("one scale for the whole grid", "uma escala para a grade inteira"), lambda v, c: v / allmax),
              (400, t("one scale per column", "uma escala por coluna"), lambda v, c: v / colmax[c])]
    mon = MON_EN if t("en", "pt") == "en" else MON_PT
    for x0, title, frac in panels:
        y0 = 50
        s.sans(x0, 18, title, size=12, weight="600")
        s.rect(x0, y0 - rh, mw, rh, fill="var(--scan)")
        s.mono(x0 + 6, y0 - rh / 2 + 0.5, "Month", size=9.5, weight="600")
        for c, ch in enumerate(CHANNELS):
            s.rect(x0 + mw + c * cw, y0 - rh, cw, rh, fill="var(--scan)")
            s.mono(x0 + mw + c * cw + cw / 2, y0 - rh / 2 + 0.5, ch, size=9.5, anchor="middle", weight="600")
        for r, (y, m) in enumerate(MONTHS):
            yy = y0 + r * rh
            s.rect(x0, yy, mw, rh, fill="var(--panel)")
            s.sans(x0 + 6, yy + rh / 2 + 0.5, f"{mon[m - 1]} {y}", size=9.5, fill="var(--paper-dim)")
            for c in range(3):
                v = grid[r][c]
                shade(s, x0 + mw + c * cw, yy, cw, rh, frac(v, c))
                s.mono(x0 + mw + c * cw + cw - 5, yy + rh / 2 + 0.5, f"{v:,}" if t("en", "pt") == "en"
                       else f"{v:,}".replace(",", "."), size=9.5, anchor="end")
    s.sans(30, 412, t("Darker means larger, measured against the scale's own smallest and largest value.",
                      "Mais escuro quer dizer maior, medido contra o menor e o maior valor da própria escala."),
           size=10.5, fill="var(--paper-dim)")
    cap = t("One scale over the grid answers which channel is biggest, which you knew. A scale per column "
            "answers which months were strong or empty for each channel.",
            "Uma escala sobre a grade responde qual canal é o maior, o que você já sabia. Uma escala por "
            "coluna responde quais meses foram fortes ou vazios em cada canal.")
    return s, cap


def icons(t):
    vals = sorted(r[4] * r[5] for r in SALES)
    lo_v, hi_v = min(vals), max(vals)
    lo = lo_v + 0.33 * (hi_v - lo_v)
    hi = lo_v + 0.67 * (hi_v - lo_v)
    zones = [sum(v < lo for v in vals), sum(lo <= v < hi for v in vals), sum(v >= hi for v in vals)]
    s = Svg(760, 330, "l09-icons", t(
        f"A dot for each of the 108 sales, placed by revenue from 0 to 2,200 and piled up where sales are "
        f"close. Two vertical lines mark 33 and 67 percent of the distance from the smallest revenue, 34, "
        f"to the largest, 2,120: at 722.38 and 1,431.62. {zones[0]} dots fall left of the first line, "
        f"{zones[1]} between the lines and {zones[2]} right of the second.",
        f"Um ponto para cada uma das 108 vendas, posto pela receita de 0 a 2.200 e empilhado onde as vendas "
        f"são próximas. Duas linhas verticais marcam 33 e 67 por cento da distância da menor receita, 34, à "
        f"maior, 2.120: em 722,38 e 1.431,62. {zones[0]} pontos caem à esquerda da primeira linha, {zones[1]} "
        f"entre as linhas e {zones[2]} à direita da segunda."))
    x0, x1, base = 40, 720, 250
    scale = (x1 - x0) / 2200
    X = lambda v: x0 + v * scale  # noqa: E731
    s.line(x0, base, x1, base, stroke="var(--paper-dim)")
    for v in range(0, 2201, 500):
        s.line(X(v), base, X(v), base + 5, stroke="var(--paper-dim)")
        s.mono(X(v), base + 16, f"{v:,}" if t("en", "pt") == "en" else f"{v:,}".replace(",", "."), size=9.5,
               anchor="middle", fill="var(--paper-dim)")
    piles = defaultdict(int)
    for v in vals:
        b = int(X(v) // 7)
        piles[b] += 1
        cy = base - 5 - (piles[b] - 1) * 6.5
        col = "var(--amber)" if v < lo else ("var(--paper-dim)" if v < hi else "var(--phosphor)")
        s.parts.append(f'<circle cx="{b * 7 + 3.5:.1f}" cy="{cy:.1f}" r="2.9" fill="{col}"></circle>')
    for v, label in ((lo, t("33% of the range", "33% da faixa")), (hi, t("67% of the range", "67% da faixa"))):
        s.line(X(v), 40, X(v), base, stroke="var(--wire)", dash="4 3")
        num = f"{v:,.2f}" if t("en", "pt") == "en" else f"{v:,.2f}".replace(",", " ").replace(".", ",").replace(" ", ".")
        s.sans(X(v) + 6, 48, label, size=10.5, fill="var(--paper-dim)")
        s.mono(X(v) + 6, 64, num, size=10.5, fill="var(--paper-dim)")
    s.sans(X(lo) - 8, 100, t(f"{zones[0]} sales: red arrow, down", f"{zones[0]} vendas: seta vermelha, para baixo"),
           size=11, anchor="end", fill="var(--amber)", weight="600")
    s.sans(X(lo) + 6, 140, t(f"{zones[1]}: yellow, sideways", f"{zones[1]}: amarela, de lado"), size=11,
           fill="var(--paper)")
    s.sans(X(hi) + 6, 140, t(f"{zones[2]}: green, up", f"{zones[2]}: verde, para cima"), size=11,
           fill="var(--phosphor)")
    s.sans(x0, 300, t("Revenue per sale, in reais. Each dot is one sale.", "Receita por venda, em reais. Cada ponto é uma venda."),
           size=10.5, fill="var(--paper-dim)")
    cap = t("The default icon thresholds are shares of the range, not of the sales. A few large wholesale "
            "orders stretch the range, and most sales land under the red arrow.",
            "Os limites padrão dos ícones são frações da faixa, não das vendas. Alguns pedidos grandes de "
            "atacado esticam a faixa, e a maioria das vendas cai sob a seta vermelha.")
    return s, cap


FIGS = {"l09-anchor": anchor, "l09-heat": heat, "l09-icons": icons}
