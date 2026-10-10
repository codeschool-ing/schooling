"""Lesson 5's figures. The numbers are computed here from the pasted data,
and l05.py shows that Calc answers the same."""
import datetime

from engine import rows
from fig import Svg
from ptformula import to_pt


def _f(t, formula):
    """A formula as the reader's Excel spells it."""
    return t(formula, to_pt(formula))


def _sales():
    return rows("Sales")[1:]


def sumifs(t):
    s = Svg(760, 362, "l05-sumifs", t(
        "The first ten sales with two tests beside each row: is the product CER1K, and is the channel "
        "Online. Only the rows that pass both tests have their revenue added, and the total is 575.",
        "As dez primeiras vendas com dois testes ao lado de cada linha: o produto é CER1K, e o canal é "
        "Online. Só as linhas que passam nos dois testes têm a receita somada, e o total é 575."))
    s.mono(30, 20, _f(t, '=SUMIFS(H2:H11, D2:D11, "CER1K", G2:G11, "Online")'), size=12, fill="var(--amber)")
    data = _sales()[:10]
    w = [58, 70, 84, 66]
    cells = [["Sale", "Product", "Channel", "Revenue"]]
    for r in data:
        cells.append([r[0], r[3], r[6], str(r[4] * r[5])])
    passes = [(r[3] == "CER1K", r[6] == "Online") for r in data]
    colours = {}
    for i, (a, b) in enumerate(passes):
        if a and b:
            colours[(i + 1, 3)] = "var(--amber)"
    x0, y0, rh = 60, 62, 24
    s.grid(x0, y0, w, cells, rowh=rh, letters=["A", "D", "G", "H"],
           numbers=[str(i) for i in range(1, 12)], anchors={3: "end"}, colours=colours)
    tx = [x0 + sum(w) + 52, x0 + sum(w) + 152]
    s.sans(tx[0], y0 + rh / 2 - 2, t("Product = CER1K", "Product = CER1K"), size=10.5, anchor="middle")
    s.sans(tx[1], y0 + rh / 2 - 2, t("Channel = Online", "Channel = Online"), size=10.5, anchor="middle")
    total = 0
    for i, (a, b) in enumerate(passes):
        cy = y0 + (i + 1) * rh + rh / 2
        for x, ok in zip(tx, (a, b)):
            if ok:
                s.parts.append(f'<circle cx="{x:.1f}" cy="{cy:.1f}" r="6" fill="var(--phosphor)"></circle>')
            else:
                s.parts.append(f'<circle cx="{x:.1f}" cy="{cy:.1f}" r="6" fill="none" '
                               f'stroke="var(--paper-dim)" stroke-width="1.4"></circle>')
        if a and b:
            v = data[i][4] * data[i][5]
            total += v
            s.arrow(x0 + sum(w) + 4, cy, x0 + sum(w) + 22, cy, stroke="var(--amber)")
            s.mono(tx[1] + 70, cy + 0.5, f"+ {v}", size=11, fill="var(--amber)")
    s.line(tx[1] + 66, y0 + 11 * rh + 6, tx[1] + 150, y0 + 11 * rh + 6, stroke="var(--amber)")
    s.mono(tx[1] + 70, y0 + 11 * rh + 20, f"= {total}", size=12, fill="var(--amber)", weight="600")
    s.sans(x0, y0 + 11 * rh + 22, t(
        "filled: the test passes. A row is added only when both are filled.",
        "cheio: o teste passa. Uma linha só é somada quando os dois estão cheios."),
        size=10.5, fill="var(--paper-dim)")
    cap = t(f"The first ten sales read the way SUMIFS reads them. Each row is tested against every "
            f"condition, and only the rows that pass all of them are added: two sales, R$ {total}.",
            f"As dez primeiras vendas lidas como o SOMASES as lê. Cada linha é testada contra todas as "
            f"condições, e só as que passam em todas são somadas: duas vendas, R$ {total}.")
    return s, cap


def grid(t):
    s = Svg(760, 272, "l05-grid", t(
        "The Report sheet: six product codes in A3 to A8, the first days of January, February and "
        "March 2025 in B2 to D2, bags in every cell and totals in column E and row 9. Cell B7 is "
        "outlined, and so are the two cells it reads: A7, which gives its product, and B2, which gives its month.",
        "A planilha Report: seis códigos de produto de A3 a A8, os primeiros dias de janeiro, fevereiro "
        "e março de 2025 de B2 a D2, sacos em cada célula e totais na coluna E e na linha 9. A célula B7 "
        "está contornada, e também as duas células que ela lê: A7, que dá o produto, e B2, que dá o mês."))
    codes = ["SUL250", "CER250", "MOG250", "DEC250", "SUL1K", "CER1K"]
    months = [datetime.date(2025, m, 1) for m in (1, 2, 3)]
    data = _sales()
    vals = []
    for c in codes:
        row = []
        for m in months:
            nxt = datetime.date(2025, m.month + 1, 1)
            row.append(sum(r[4] for r in data if r[3] == c and m <= r[1] < nxt))
        vals.append(row)
    cells = [["Product"] + [m.isoformat() for m in months] + ["Total"]]
    for c, row in zip(codes, vals):
        cells.append([c] + [str(v) for v in row] + [str(sum(row))])
    cols = [sum(v[i] for v in vals) for i in range(3)]
    cells.append(["Total"] + [str(v) for v in cols] + [str(sum(cols))])
    w = [76, 92, 92, 92, 60]
    x0, y0, rh = 50, 46, 26
    fills = {(5, 1): "var(--scan)", (5, 0): "var(--panel)", (0, 1): "var(--panel)"}
    colours = {(5, 1): "var(--amber)", (5, 0): "var(--phosphor)", (0, 1): "var(--phosphor)"}
    for c in range(5):
        fills[(7, c)] = "var(--scan)"
    for r in range(1, 7):
        fills[(r, 4)] = "var(--scan)"
    s.grid(x0, y0, w, cells, rowh=rh, letters=list("ABCDE"), numbers=[str(i) for i in range(2, 10)],
           anchors={1: "end", 2: "end", 3: "end", 4: "end"}, fills=fills, colours=colours)
    # B7 in amber; the two cells it reads, A7 and B2, in phosphor.
    for (cx, cy, cw, col) in ((x0 + w[0], y0 + 5 * rh, w[1], "var(--amber)"),
                              (x0, y0 + 5 * rh, w[0], "var(--phosphor)"),
                              (x0 + w[0], y0, w[1], "var(--phosphor)")):
        s.parts.append(f'<rect x="{cx:.1f}" y="{cy:.1f}" width="{cw:.1f}" height="{rh:.1f}" rx="0" '
                       f'fill="none" stroke="{col}" stroke-width="2"></rect>')
    nx = x0 + sum(w) + 30
    s.mono(nx, y0 + 14, "B7", size=12, fill="var(--amber)", weight="600")
    s.mono(nx, y0 + 36, _f(t, '=SUMIFS(…, $A7,'), size=11)
    s.mono(nx, y0 + 54, _f(t, '  …, ">="&B$2,'), size=11)
    s.mono(nx, y0 + 72, _f(t, '  …, "<"&EDATE(B$2, 1))'), size=11)
    s.sans(nx, y0 + 104, t("$A7: always column A,", "$A7: sempre a coluna A,"), size=10.5, fill="var(--phosphor)")
    s.sans(nx, y0 + 120, t("the row moves when filled down", "a linha anda ao preencher para baixo"),
           size=10.5, fill="var(--phosphor)")
    s.sans(nx, y0 + 144, t("B$2: always row 2,", "B$2: sempre a linha 2,"), size=10.5, fill="var(--phosphor)")
    s.sans(nx, y0 + 160, t("the column moves when filled right", "a coluna anda ao preencher para a direita"),
           size=10.5, fill="var(--phosphor)")
    s.sans(nx, y0 + 192, t("one formula, typed once in B3,", "uma fórmula, digitada uma vez em B3,"),
           size=10.5, fill="var(--paper-dim)")
    s.sans(nx, y0 + 208, t("fills all eighteen cells", "preenche as dezoito células"),
           size=10.5, fill="var(--paper-dim)")
    cap = t(f"The Report grid for the first quarter of 2025. Cell B7, {vals[4][0]} bags of SUL1K in January, "
            f"finds its product in column A and its month in row 2, and so does every other cell. The "
            f"grand total, {sum(cols)}, matches a single SUMIFS over the quarter.",
            f"A grade de Report do primeiro trimestre de 2025. A célula B7, {vals[4][0]} sacos de SUL1K em "
            f"janeiro, acha o produto na coluna A e o mês na linha 2, como toda outra célula. O total "
            f"geral, {sum(cols)}, bate com um único SOMASES sobre o trimestre.")
    return s, cap


FIGS = {"l05-sumifs": sumifs, "l05-grid": grid}
