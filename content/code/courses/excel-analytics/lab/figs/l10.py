"""Lesson 10's figures. The totals they draw are summed here from the pasted
data; lab/l10.py prints the same totals from Calc's pivot tables and checks
each against a SUMIFS."""
from collections import defaultdict

from engine import rows
from fig import Svg

SALES = rows("Sales")[1:]
CH = ("Online", "Shop", "Wholesale")


def fmt(t, v):
    s = f"{v:,}"
    return s if t("en", "pt") == "en" else s.replace(",", ".")


def areas(t):
    rev = defaultdict(int)
    for r in SALES:
        rev[(r[3], r[6])] += r[4] * r[5]
    prods = sorted({r[3] for r in SALES})
    s = Svg(760, 380, "l10-areas", t(
        "On the left, the bottom of the PivotTable Fields pane with its four boxes: Customer in Filters, "
        "Channel in Columns, Product in Rows and Sum of Revenue in Values. On the right, the pivot they "
        "produce, with each region outlined in the colour of its box: the Customer filter above, the "
        "channels across the top, the products down the side and the sums of revenue in the body.",
        "À esquerda, a parte de baixo do painel Campos da Tabela Dinâmica com as quatro caixas: Customer em "
        "Filtros, Channel em Colunas, Product em Linhas e Soma de Revenue em Valores. À direita, a tabela "
        "dinâmica que elas produzem, com cada região contornada na cor da sua caixa: o filtro Customer em "
        "cima, os canais no alto, os produtos na lateral e as somas de receita no corpo."))
    boxes = [(t("Filters", "Filtros"), "Customer", "var(--amber)", 0, 0),
             (t("Columns", "Colunas"), "Channel", "var(--phosphor)", 1, 0),
             (t("Rows", "Linhas"), "Product", "var(--paper)", 0, 1),
             (t("Values", "Valores"), t("Sum of Revenue", "Soma de Revenue"), "var(--paper-dim)", 1, 1)]
    s.sans(30, 22, t("the four boxes of the field list", "as quatro caixas da lista de campos"), size=12, weight="600")
    for label, field, col, cx, cy in boxes:
        x, y = 30 + cx * 140, 44 + cy * 92
        s.sans(x, y + 8, label, size=11, fill=col, weight="600")
        s.rect(x, y + 18, 128, 56, fill="var(--panel)", stroke=col, rx=3, sw=1.5)
        s.rect(x + 8, y + 32, 112, 22, fill="var(--scan)", stroke="var(--wire)", rx=2)
        if field in ("Customer", "Channel", "Product"):
            s.mono(x + 14, y + 43.5, field, size=10.5)
        else:
            s.sans(x + 14, y + 43.5, field, size=10.5)
    s.sans(30, 252, t("Rows and Columns group the records.", "Linhas e Colunas agrupam os registros."),
           size=10.5, fill="var(--paper-dim)")
    s.sans(30, 270, t("Values says what is added up.", "Valores diz o que é somado."), size=10.5,
           fill="var(--paper-dim)")
    s.sans(30, 288, t("Filters says which records count.", "Filtros diz quais registros contam."), size=10.5,
           fill="var(--paper-dim)")
    # The pivot.
    x0, y0, lw, cw, rh = 340, 44, 78, 74, 22
    s.sans(x0, 22, t("the pivot they build", "a tabela dinâmica que elas montam"), size=12, weight="600")
    s.mono(x0, y0 + 11, "Customer", size=10.5)
    s.mono(x0 + lw + 6, y0 + 11, t("(All)", "(Tudo)"), size=10.5)
    s.rect(x0 - 4, y0, lw + 70, rh, fill="none", stroke="var(--amber)", sw=1.5, rx=3)
    gy = y0 + 2 * rh
    heads = CH + (t("Grand Total", "Total Geral"),)
    for i, h in enumerate(heads):
        s.rect(x0 + lw + i * cw, gy, cw, rh, fill="var(--scan)")
        (s.mono if i < 3 else s.sans)(x0 + lw + i * cw + cw / 2, gy + rh / 2 + 0.5, h, size=10, anchor="middle",
                                       weight="600")
    s.rect(x0, gy, lw, rh, fill="var(--scan)")
    for r, p in enumerate(prods):
        yy = gy + (r + 1) * rh
        s.rect(x0, yy, lw, rh, fill="var(--panel)")
        s.mono(x0 + 6, yy + rh / 2 + 0.5, p, size=10)
        for i, ch in enumerate(CH):
            v = rev[(p, ch)]
            s.rect(x0 + lw + i * cw, yy, cw, rh, fill="var(--panel)")
            if v:
                s.mono(x0 + lw + (i + 1) * cw - 6, yy + rh / 2 + 0.5, fmt(t, v), size=10, anchor="end")
        tot = sum(rev[(p, ch)] for ch in CH)
        s.rect(x0 + lw + 3 * cw, yy, cw, rh, fill="var(--panel)")
        s.mono(x0 + lw + 4 * cw - 6, yy + rh / 2 + 0.5, fmt(t, tot), size=10, anchor="end")
    ty = gy + (len(prods) + 1) * rh
    s.rect(x0, ty, lw, rh, fill="var(--scan)")
    s.sans(x0 + 6, ty + rh / 2 + 0.5, t("Grand Total", "Total Geral"), size=10, weight="600")
    for i in range(4):
        v = sum(rev[(p, CH[i])] for p in prods) if i < 3 else sum(rev.values())
        s.rect(x0 + lw + i * cw, ty, cw, rh, fill="var(--scan)")
        s.mono(x0 + lw + (i + 1) * cw - 6, ty + rh / 2 + 0.5, fmt(t, v), size=10, anchor="end", weight="600")
    # Region outlines.
    s.rect(x0 + lw - 2, gy - 2, 3 * cw + 4, rh + 4, fill="none", stroke="var(--phosphor)", sw=1.8, rx=3)
    s.rect(x0 - 2, gy + rh - 2, lw + 4, len(prods) * rh + 4, fill="none", stroke="var(--paper)", sw=1.8, rx=3,
           dash="5 3")
    s.rect(x0 + lw - 2, gy + rh + 3, 3 * cw + 4, len(prods) * rh - 1, fill="none", stroke="var(--paper-dim)",
           sw=1.8, rx=3, dash="2 3")
    s.sans(x0, ty + rh + 26, t("A blank cell: that product was never sold through that channel.",
                               "Célula em branco: aquele produto nunca foi vendido por aquele canal."),
           size=10.5, fill="var(--paper-dim)")
    cap = t("Each box of the field list fills one region of the pivot. Moving a field to another box "
            "rearranges the same totals; nothing has to be typed again.",
            "Cada caixa da lista de campos preenche uma região da tabela dinâmica. Mover um campo para outra "
            "caixa rearranja os mesmos totais; nada precisa ser digitado de novo.")
    return s, cap


def quarters(t):
    rev = defaultdict(int)
    for r in SALES:
        rev[(r[1].year, (r[1].month - 1) // 3 + 1, r[6])] += r[4] * r[5]
    qs = [(2025, 1), (2025, 2), (2025, 3), (2025, 4), (2026, 1), (2026, 2)]
    tot = {q: sum(rev[q + (c,)] for c in CH) for q in qs}
    s = Svg(760, 300, "l10-quarters", t(
        "Horizontal bars for the six quarters from the first of 2025 to the second of 2026, each split into "
        "Wholesale, Online and Shop revenue. The first quarter of 2026 is the longest bar, 12,139. The "
        "second quarter of 2026 is the shortest by far, 3,804, and almost all of the drop is in its "
        "wholesale segment, 1,166.",
        "Barras horizontais para os seis trimestres, do primeiro de 2025 ao segundo de 2026, cada uma "
        "dividida em receita de Wholesale, Online e Shop. O primeiro trimestre de 2026 é a barra mais longa, "
        "12.139. O segundo trimestre de 2026 é de longe a mais curta, 3.804, e quase toda a queda está no "
        "pedaço de atacado, 1.166."))
    cols = {"Wholesale": "var(--phosphor)", "Online": "var(--amber)", "Shop": "var(--paper-dim)"}
    x0, y0, bh, gap = 110, 50, 24, 12
    scale = 520 / 13000
    lx = x0
    for ch in ("Wholesale", "Online", "Shop"):
        s.rect(lx, 16, 12, 12, fill=cols[ch], stroke="none")
        s.mono(lx + 18, 22.5, ch, size=10.5)
        lx += 120
    for i, q in enumerate(qs):
        y = y0 + i * (bh + gap)
        s.sans(x0 - 10, y + bh / 2, t(f"Q{q[1]} {q[0]}", f"{q[1]}º tri {q[0]}"), size=10.5, anchor="end")
        x = x0
        for ch in ("Wholesale", "Online", "Shop"):
            w = rev[q + (ch,)] * scale
            if w:
                s.rect(x, y, w, bh, fill=cols[ch], stroke="var(--ink)", sw=0.5)
            x += w
        s.mono(x + 8, y + bh / 2 + 0.5, fmt(t, tot[q]), size=10.5,
               weight="600" if q in ((2026, 1), (2026, 2)) else None)
        if q == (2026, 2):
            s.sans(x + 70, y + bh / 2, t(f"wholesale: {fmt(t, rev[q + ('Wholesale',)])}",
                                         f"atacado: {fmt(t, rev[q + ('Wholesale',)])}"), size=10.5,
                   fill="var(--phosphor)")
    cap = t("Revenue by quarter and channel. The year total hid that the best quarter and the worst are "
            "next to each other, and that the fall is wholesale.",
            "Receita por trimestre e canal. O total do ano escondia que o melhor trimestre e o pior estão lado "
            "a lado, e que a queda é do atacado.")
    return s, cap


def cache(t):
    s = Svg(760, 300, "l10-cache", t(
        "The Sales table, after sale S1001 was changed from 14 to 15 bags, holds a revenue of 1,560. A "
        "formula reads the table directly and already answers 38,835. The pivot reads the pivot cache, a "
        "copy taken at the last refresh, which still holds 14 bags and 1,456, so the pivot still answers "
        "38,731. A Refresh arrow from the table to the cache replaces the copy.",
        "A tabela Sales, depois que a venda S1001 passou de 14 para 15 sacos, tem receita de 1.560. Uma "
        "fórmula lê a tabela diretamente e já responde 38.835. A tabela dinâmica lê o cache, uma cópia feita "
        "na última atualização, que ainda tem 14 sacos e 1.456, então ela ainda responde 38.731. Uma seta "
        "Atualizar, da tabela para o cache, troca a cópia."))
    w = [62, 44, 60]
    def mini(x, y, title, bags, rev, col):
        s.sans(x, y - 12, title, size=11.5, weight="600")
        s.grid(x, y, w, [["Sale", "Bags", "Revenue"], ["S1001", bags, rev], ["S1002", "17", "1972"], ["…", "…", "…"]],
               rowh=22, anchors={1: "end", 2: "end"}, colours={(1, 1): col, (1, 2): col})
    mini(30, 60, t("table Sales, now", "tabela Sales, agora"), "15", "1560", "var(--phosphor)")
    mini(340, 60, t("pivot cache: a copy", "cache: uma cópia"), "14", "1456", "var(--amber)")
    # Pivot result.
    s.sans(590, 48, t("pivot", "tabela dinâmica"), size=11.5, weight="600")
    s.grid(590, 60, [80, 80], [["Channel", t("Sum", "Soma")], ["Wholesale", fmt(t, 38731)]], rowh=22,
           anchors={1: "end"}, colours={(1, 1): "var(--amber)"})
    s.arrow(340 + sum(w) + 8, 93, 582, 93, stroke="var(--paper-dim)")
    # Formula.
    s.sans(590, 168, t("formula", "fórmula"), size=11.5, weight="600")
    s.rect(590, 180, 160, 22, fill="var(--panel)")
    s.mono(744, 191.5, fmt(t, 38835), size=10.5, anchor="end", fill="var(--phosphor)")
    s.mono(590, 216, "=SUMIFS(Sales[Revenue], …)", size=9.5, fill="var(--paper-dim)")
    s.path(f"M{30 + sum(w) / 2} {60 + 4 * 22 + 6} L{30 + sum(w) / 2} 191 L582 191", stroke="var(--phosphor)", sw=1.6)
    s.arrow(575, 191, 583, 191, stroke="var(--phosphor)")
    s.sans(30 + sum(w) / 2 + 8, 176, t("reads the table, recalculates at once", "lê a tabela, recalcula na hora"),
           size=10.5, fill="var(--phosphor)")
    # Refresh arrow.
    s.arrow(30 + sum(w) + 8, 82, 332, 82, stroke="var(--amber)")
    s.sans(30 + sum(w) + 12, 70, t("Refresh copies again", "Atualizar copia de novo"), size=10.5, fill="var(--amber)")
    s.sans(30, 262, t("Until somebody refreshes, the pivot and the formula disagree, and both are right about",
                      "Até alguém atualizar, a tabela dinâmica e a fórmula discordam, e as duas estão certas sobre"),
           size=10.5, fill="var(--paper-dim)")
    s.sans(30, 280, t("what they read.", "o que leem."), size=10.5, fill="var(--paper-dim)")
    cap = t("A pivot answers from its cache, a copy of the table taken at the last refresh. A formula answers "
            "from the table itself.",
            "Uma tabela dinâmica responde a partir do cache, uma cópia da tabela feita na última atualização. "
            "Uma fórmula responde a partir da própria tabela.")
    return s, cap


FIGS = {"l10-areas": areas, "l10-quarters": quarters, "l10-cache": cache}
