"""Lesson 7's figures."""
from engine import rows
from fig import Svg


def _rows():
    out = []
    for r in rows("Sales")[1:]:
        out.append([r[0], r[1].isoformat(), r[2], r[3], str(r[4]), str(r[5]), r[6], str(r[4] * r[5])])
    return out


def table(t):
    s = Svg(760, 310, "l07-table", t(
        "The Sales table drawn with its header row, its first three rows, its last row and a total row. "
        "Labels name each part: Sales[#Headers] is the header row, Sales[Bags] the data cells of the Bags "
        "column, [@Bags] one cell of that column on the formula's own row, Sales[#Totals] the total row, "
        "and Sales the whole data area.",
        "A tabela Sales desenhada com a linha de cabeçalho, as três primeiras linhas, a última e uma linha "
        "de total. Rótulos nomeiam cada parte: Sales[#Cabeçalhos] é a linha de cabeçalho, Sales[Bags] as "
        "células de dados da coluna Bags, [@Bags] uma célula dessa coluna na própria linha da fórmula, "
        "Sales[#Totais] a linha de total, e Sales a área de dados inteira."))
    data = _rows()
    hdr = ["Sale", "Date", "Customer", "Product", "Bags", "Price", "Channel", "Revenue"]
    body = data[:3] + [["…"] * 8] + [data[-1]]
    total = ["Total", "", "", "", "591", "", "", "51494"]
    cells = [hdr] + body + [total]
    w = [52, 82, 64, 62, 44, 44, 76, 64]
    x0, y0, rh = 100, 54, 26
    fills = {(6, c): "var(--scan)" for c in range(8)}
    colours = {(2, 7): "var(--phosphor)", (2, 4): "var(--phosphor)"}
    s.grid(x0, y0, w, cells, rowh=rh, letters=list("ABCDEFGH"), numbers=["1", "2", "3", "4", "", "109", ""],
           anchors={4: "end", 5: "end", 7: "end"}, fills=fills, colours=colours, size=10)
    right = x0 + sum(w)
    bx = x0 + sum(w[:4])
    # Sales[Bags]: the data cells of column E.
    s.rect(bx, y0 + rh, w[4], 5 * rh, fill="none", stroke="var(--amber)", sw=2)
    # [@Bags] on row 3.
    s.rect(bx + 3, y0 + 2 * rh + 3, w[4] - 6, rh - 6, fill="none", stroke="var(--phosphor)", sw=2)
    # Sales: the data area, bracketed on the left.
    s.path(f"M{x0 - 32} {y0 + rh + 2} L{x0 - 38} {y0 + rh + 2} L{x0 - 38} {y0 + 6 * rh - 2} "
           f"L{x0 - 32} {y0 + 6 * rh - 2}", stroke="var(--paper)", sw=1.4)
    s.mono(x0 - 44, y0 + 3.5 * rh, "Sales", size=10.5, anchor="end")
    # Labels on the right.
    lx = right + 14
    s.mono(lx, y0 + rh / 2, t("Sales[#Headers]", "Sales[#Cabeçalhos]"), size=10.5)
    s.mono(lx, y0 + 6 * rh + rh / 2, t("Sales[#Totals]", "Sales[#Totais]"), size=10.5)
    s.mono(bx + w[4] / 2, y0 + 7 * rh + 20, "Sales[Bags]", size=10.5, fill="var(--amber)", anchor="middle")
    s.sans(bx + w[4] / 2, y0 + 7 * rh + 38, t("the data cells of one column", "as células de dados de uma coluna"),
           size=10.5, fill="var(--amber)", anchor="middle")
    s.mono(right - w[7] / 2, y0 + 7 * rh + 20, "=[@Bags]*[@Price]", size=10.5, fill="var(--phosphor)",
           anchor="middle")
    s.sans(right - w[7] / 2, y0 + 7 * rh + 38, t("H3 reads E3 and F3, its own row", "H3 lê E3 e F3, a própria linha"),
           size=10.5, fill="var(--phosphor)", anchor="middle")
    cap = t("The parts of the Sales table and the names a formula calls them by. Sales[Bags] covers every "
            "data row of the column however many there are, and never the header or the total row.",
            "As partes da tabela Sales e os nomes pelos quais uma fórmula as chama. Sales[Bags] cobre toda "
            "linha de dados da coluna, quantas forem, e nunca o cabeçalho nem a linha de total.")
    return s, cap


def grow(t):
    s = Svg(760, 280, "l07-grow", t(
        "The last rows of the Sales table, 107 to 110, with the new sale S1109 on row 110 inside the table. "
        "A bracket for E2:E109 stops at row 109 and adds up to 591; a bracket for Sales[Bags] reaches row "
        "110 and adds up to 597. H110 already holds the revenue of the new sale, 636.",
        "As últimas linhas da tabela Sales, de 107 a 110, com a venda nova S1109 na linha 110, dentro da "
        "tabela. Um colchete para E2:E109 para na linha 109 e soma 591; um colchete para Sales[Bags] chega "
        "à linha 110 e soma 597. H110 já guarda a receita da venda nova, 636."))
    data = _rows()
    hdr = ["Sale", "Date", "Customer", "Product", "Bags", "Price", "Channel", "Revenue"]
    new = ["S1109", "2026-06-29", "C01", "CER1K", "6", "106", "Wholesale", "636"]
    cells = [hdr, ["…"] * 8] + data[-3:] + [new]
    w = [52, 82, 64, 62, 44, 44, 76, 64]
    x0, y0, rh = 70, 40, 26
    fills = {(5, c): "var(--scan)" for c in range(8)}
    colours = {(5, c): "var(--amber)" for c in range(8)}
    s.grid(x0, y0, w, cells, rowh=rh, numbers=["1", "", "107", "108", "109", "110"],
           anchors={4: "end", 5: "end", 7: "end"}, fills=fills, colours=colours, size=10)
    right = x0 + sum(w)
    # E2:E109 stops at 109; Sales[Bags] reaches 110.
    s.path(f"M{right + 10} {y0 + rh + 2} L{right + 18} {y0 + rh + 2} L{right + 18} {y0 + 5 * rh - 2} "
           f"L{right + 10} {y0 + 5 * rh - 2}", stroke="var(--paper-dim)", sw=1.6)
    s.mono(right + 26, y0 + 2.5 * rh, "E2:E109", size=10.5, fill="var(--paper-dim)")
    s.mono(right + 26, y0 + 3.3 * rh, "= 591", size=10.5, fill="var(--paper-dim)")
    s.path(f"M{right + 100} {y0 + rh + 2} L{right + 108} {y0 + rh + 2} L{right + 108} {y0 + 6 * rh - 2} "
           f"L{right + 100} {y0 + 6 * rh - 2}", stroke="var(--amber)", sw=1.6)
    s.mono(right + 116, y0 + 3.0 * rh, "Sales[Bags]", size=10.5, fill="var(--amber)")
    s.mono(right + 116, y0 + 3.8 * rh, "= 597", size=10.5, fill="var(--amber)")
    s.sans(x0, y0 + 6 * rh + 24, t("row 110 typed under the table: the table takes it in, and the Revenue "
                                    "formula fills H110 by itself",
                                    "linha 110 digitada debaixo da tabela: a tabela a incorpora, e a fórmula "
                                    "de Revenue preenche H110 sozinha"),
           size=10.5, fill="var(--amber)")
    s.sans(x0, y0 + 6 * rh + 44, t("the address still ends at 109, and no error says so",
                                    "o endereço continua terminando em 109, e nenhum erro avisa"),
           size=10.5, fill="var(--paper-dim)")
    cap = t("One sale added under the table. The formula that names the table counts its six bags; the one "
            "that gives an address does not, and both look equally finished.",
            "Uma venda acrescentada debaixo da tabela. A fórmula que nomeia a tabela conta os seis sacos dela; "
            "a que dá um endereço não conta, e as duas parecem igualmente prontas.")
    return s, cap


FIGS = {"l07-table": table, "l07-grow": grow}
