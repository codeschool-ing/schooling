"""Lesson 1's figures."""
from fig import Svg


def shapes(t):
    s = Svg(760, 470, "l01-shapes", t(
        "Two sheets holding the same bags. On the left, a report: a merged title, months across the "
        "columns, products grouped under a label row, subtotals and a total between the data rows and "
        "blank rows between groups. On the right, the same sales as records: one row per sale, with "
        "the columns Sale, Date, Product and Bags.",
        "Duas planilhas com os mesmos sacos. À esquerda, um relatório: título mesclado, meses nas "
        "colunas, produtos agrupados sob uma linha de rótulo, subtotais e um total entre as linhas de "
        "dados e linhas em branco entre os grupos. À direita, as mesmas vendas como registros: uma linha "
        "por venda, com as colunas Sale, Date, Product e Bags."))
    s.sans(30, 18, t("shaped for a person to read", "feita para uma pessoa ler"), size=12, weight="600")
    s.sans(470, 18, t("shaped for analysis", "feita para análise"), size=12, weight="600")
    w = [78, 44, 44, 44, 52]
    rows = [
        [t("Bags sold, first quarter 2025", "Sacos vendidos, 1º trimestre de 2025"), "", "", "", ""],
        ["", "", "", "", ""],
        ["Product", "Jan", "Feb", "Mar", "Total"],
        [t("250 g bags", "Sacos de 250 g"), "", "", "", ""],
        ["SUL250", "2", "5", "0", "7"],
        ["CER250", "0", "0", "0", "0"],
        ["MOG250", "0", "7", "6", "13"],
        ["DEC250", "1", "14", "19", "34"],
        ["Subtotal", "3", "26", "25", "54"],
        ["", "", "", "", ""],
        [t("1 kg bags", "Sacos de 1 kg"), "", "", "", ""],
        ["SUL1K", "17", "4", "17", "38"],
        ["CER1K", "19", "5", "0", "24"],
        ["Subtotal", "36", "9", "17", "62"],
        ["Total", "39", "35", "42", "116"],
    ]
    x0, y0, rh = 50, 46, 22
    # Draw cell by cell so the merged rows can be drawn as one cell.
    for r, row in enumerate(rows):
        y = y0 + r * rh
        s.mono(x0 - 8, y + rh / 2, str(r + 1), size=9.5, fill="var(--paper-dim)", anchor="end")
        if r in (0, 3, 10):
            s.rect(x0, y, sum(w), rh, fill="var(--scan)" if r == 0 else "var(--panel)")
            if r == 0:
                s.sans(x0 + sum(w) / 2, y + rh / 2, row[0], size=10.5, anchor="middle", weight="600")
            else:
                s.sans(x0 + 6, y + rh / 2, row[0], size=10.5, fill="var(--paper-dim)")
            continue
        cx = x0
        for c, cw in enumerate(w):
            sub = row[0] in ("Subtotal", "Total")
            s.rect(cx, y, cw, rh, fill="var(--scan)" if (r == 2 or sub) else "var(--panel)")
            v = row[c]
            if v:
                if c == 0:
                    s.mono(cx + 6, y + rh / 2 + 0.5, v, size=10.5, weight="600" if (r == 2 or sub) else None,
                           fill="var(--amber)" if sub else "var(--paper)")
                else:
                    s.mono(cx + cw - 6, y + rh / 2 + 0.5, v, size=10.5, anchor="end",
                           weight="600" if r == 2 else None, fill="var(--amber)" if sub else "var(--paper)")
            cx += cw
    # Numbered marks.
    marks = [(1, x0 + sum(w) + 16, y0 + rh / 2), (2, x0 + sum(w) + 16, y0 + 2 * rh + rh / 2),
             (3, x0 + sum(w) + 16, y0 + 3 * rh + rh / 2), (4, x0 + sum(w) + 16, y0 + 8 * rh + rh / 2),
             (5, x0 + sum(w) + 16, y0 + 9 * rh + rh / 2)]
    for n, mx, my in marks:
        s.parts.append(f'<circle cx="{mx:.1f}" cy="{my:.1f}" r="8" fill="var(--amber)"></circle>')
        s.mono(mx, my + 0.5, str(n), size=10, fill="var(--ink)", anchor="middle", weight="600")
    notes = [
        t("1  a title merged across the columns", "1  um título mesclado sobre as colunas"),
        t("2  months as columns, not values", "2  meses como colunas, não como valores"),
        t("3  a group label in place of a column", "3  um rótulo de grupo no lugar de uma coluna"),
        t("4  subtotals among the data rows", "4  subtotais entre as linhas de dados"),
        t("5  blank rows as decoration", "5  linhas em branco como enfeite"),
    ]
    for i, n in enumerate(notes):
        s.sans(30, 393 + i * 15, n, size=10.5, fill="var(--paper-dim)")
    # The record-shaped side.
    w2 = [62, 92, 66, 44]
    rec = [["Sale", "Date", "Product", "Bags"],
           ["S1001", "2025-01-02", "CER1K", "14"],
           ["S1002", "2025-01-05", "SUL1K", "17"],
           ["S1003", "2025-01-13", "CER1K", "1"],
           ["S1004", "2025-01-21", "DEC250", "1"],
           ["S1005", "2025-01-22", "CER1K", "4"],
           ["S1006", "2025-01-27", "SUL250", "2"],
           ["S1007", "2025-02-04", "MOG250", "4"],
           ["S1008", "2025-02-05", "SUL250", "5"],
           ["…", "…", "…", "…"]]
    s.grid(480, 46, w2, rec, rowh=22, numbers=[str(i) for i in range(1, 10)] + [""],
           anchors={3: "end"})
    s.sans(480, 278, t("one row per sale, 108 rows", "uma linha por venda, 108 linhas"), size=10.5,
           fill="var(--phosphor)")
    s.sans(480, 296, t("one column per field", "uma coluna por campo"), size=10.5, fill="var(--phosphor)")
    s.sans(480, 314, t("the months are in the Date column", "os meses estão na coluna Date"), size=10.5,
           fill="var(--phosphor)")
    s.sans(480, 332, t("no totals: a total is a question", "sem totais: total é uma pergunta"),
           size=10.5, fill="var(--phosphor)")
    cap = t("The same bags in two shapes. The report on the left is easy to read and hard to analyse; "
            "the records on the right are the opposite, and a report can always be built from them.",
            "Os mesmos sacos em duas formas. O relatório da esquerda é fácil de ler e difícil de "
            "analisar; os registros da direita são o contrário, e sempre dá para montar um relatório a "
            "partir deles.")
    return s, cap


FIGS = {"l01-shapes": shapes}
