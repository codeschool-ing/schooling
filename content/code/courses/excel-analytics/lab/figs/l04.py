"""Lesson 4's figures. The values are lesson 1's data and what lab/l04.py
printed."""
from engine import rows
from fig import Svg


def lookup(t):
    s = Svg(720, 300, "l04-lookup", t(
        "Row 2 of Sales holds sale S1001 with the product CER1K in D2. An arrow goes from D2 to the "
        "Products sheet, where CER1K is found in A5, the fourth row of A2:A7. The value on the same row "
        "of the List price column, F5, is 118, and a second arrow brings it back to J2 on Sales.",
        "A linha 2 de Sales tem a venda S1001 com o produto CER1K em D2. Uma seta vai de D2 até a "
        "planilha Products, onde CER1K é encontrado em A5, a quarta linha de A2:A7. O valor na mesma "
        "linha da coluna List price, F5, é 118, e uma segunda seta o traz de volta para J2 em Sales."))
    s.sans(40, 20, "Sales", size=12, weight="600")
    sw = [64, 74, 82]
    sx, sy, rh = 40, 50, 26
    s.grid(sx, sy, sw, [["Sale", "Product", "List price"], ["S1001", "CER1K", "118"]], rowh=rh,
           letters=["A", "D", "J"], numbers=["1", "2"],
           fills={(1, 1): "var(--scan)", (1, 2): "var(--scan)"},
           colours={(1, 1): "var(--amber)", (1, 2): "var(--phosphor)"}, anchors={2: "end"})
    px, py = 350, 50
    s.sans(px, 20, "Products", size=12, weight="600")
    data = rows("Products")
    pcells = [["Code", "List price"]] + [[r[0], str(r[5])] for r in data[1:]]
    pw = [80, 84]
    s.grid(px, py, pw, pcells, rowh=rh, letters=["A", "F"], numbers=[str(i) for i in range(1, 8)],
           fills={(4, 0): "var(--scan)", (4, 1): "var(--scan)"},
           colours={(4, 0): "var(--amber)", (4, 1): "var(--phosphor)"}, anchors={1: "end"})
    # 1: D2 down and across to A5.
    dx = sx + sw[0] + sw[1] / 2
    ay = py + 4 * rh + rh / 2
    s.path(f"M{dx:.1f} {sy + 2 * rh:.1f} L{dx:.1f} {ay:.1f} L{px - 44:.1f} {ay:.1f}", stroke="var(--amber)", sw=1.5)
    s.arrow(px - 44, ay, px - 18, ay, stroke="var(--amber)", sw=1.5)
    # 3: F5 out to the right, under both grids, back up to J2.
    fx = px + sum(pw)
    jx = sx + sw[0] + sw[1] + sw[2] / 2
    low = py + 7 * rh + 16
    s.path(f"M{fx:.1f} {ay:.1f} L{fx + 18:.1f} {ay:.1f} L{fx + 18:.1f} {low:.1f} L{jx:.1f} {low:.1f} "
           f"L{jx:.1f} {sy + 2 * rh + 26:.1f}", stroke="var(--phosphor)", sw=1.5)
    s.arrow(jx, sy + 2 * rh + 26, jx, sy + 2 * rh + 1, stroke="var(--phosphor)", sw=1.5)
    nx = fx + 30
    s.sans(nx, 90, t("1  find CER1K in A2:A7", "1  achar CER1K em A2:A7"), size=11, fill="var(--amber)")
    s.sans(nx, 140, t("2  it is the 4th row", "2  é a 4ª linha"), size=11, fill="var(--paper)")
    s.sans(nx, 173, t("3  the 4th value of F2:F7", "3  o 4º valor de F2:F7"), size=11, fill="var(--phosphor)")
    s.sans(nx, 190, t("    is 118", "    é 118"), size=11, fill="var(--phosphor)")
    s.mono(sx, 272, "=XLOOKUP(D2,Products!$A$2:$A$7,Products!$F$2:$F$7)" if t(1, 0)
           else "=PROCX(D2;Products!$A$2:$A$7;Products!$F$2:$F$7)", size=10.5, fill="var(--paper-dim)")
    cap = t("A lookup in three steps: the key from this row, its position in the other table's key "
            "column, and the value at the same position of the column to bring back.",
            "Uma busca em três passos: a chave desta linha, a posição dela na coluna-chave da outra "
            "tabela, e o valor na mesma posição da coluna a trazer de volta.")
    return s, cap


def approx(t):
    s = Svg(720, 250, "l04-approx", t(
        "The band table with the keys 1, 4 and 10 and the bands Small, Medium and Large, and a line of bag "
        "counts from 1 to 20 with the three keys marked on it. Three sales are placed on the line: 14 bags "
        "moves left to the key 10 and is Large, 6 bags moves left to 4 and is Medium, 1 bag sits on the "
        "key 1 and is Small.",
        "A tabela de faixas com as chaves 1, 4 e 10 e as faixas Small, Medium e Large, e uma reta de "
        "quantidades de sacos de 1 a 20 com as três chaves marcadas. Três vendas são postas na reta: 14 "
        "sacos anda para a esquerda até a chave 10 e é Large, 6 sacos anda até 4 e é Medium, 1 saco "
        "está sobre a chave 1 e é Small."))
    s.grid(40, 50, [56, 74], [["From", "Band"], ["1", "Small"], ["4", "Medium"], ["10", "Large"]],
           letters=["O", "P"], numbers=["1", "2", "3", "4"], anchors={0: "end"},
           colours={(3, 1): "var(--amber)", (2, 1): "var(--phosphor)"})
    x0, x1, ly = 240, 680, 60
    unit = (x1 - x0) / 19

    def X(n):
        return x0 + (n - 1) * unit

    s.line(x0, ly, x1, ly, stroke="var(--wire)", sw=1.2)
    for n in range(1, 21):
        s.line(X(n), ly - 4, X(n), ly + 4, stroke="var(--wire)")
    for n, col in ((1, "var(--paper)"), (4, "var(--phosphor)"), (10, "var(--amber)")):
        s.line(X(n), ly - 12, X(n), ly + 12, stroke=col, sw=2)
        s.mono(X(n), ly - 22, str(n), size=11, fill=col, anchor="middle", weight="600")
    s.mono(X(20), ly - 22, "20", size=10.5, fill="var(--paper-dim)", anchor="middle")
    for i, (v, key, band, col) in enumerate(((14, 10, "Large", "var(--amber)"), (6, 4, "Medium", "var(--phosphor)"),
                                             (1, 1, "Small", "var(--paper)"))):
        y = 108 + i * 36
        s.parts.append(f'<circle cx="{X(v):.1f}" cy="{y:.1f}" r="5" fill="{col}"></circle>')
        s.mono(X(v) + 10, y, f"E = {v}", size=10.5, fill=col)
        if v != key:
            s.arrow(X(v) - 8, y, X(key) + 2, y, stroke=col, sw=1.4)
        s.mono(X(key) - 8, y, band, size=11, fill=col, anchor="end", weight="600")
    s.sans(240, 222, t("the largest key that is not greater than the value", "a maior chave que não passa do valor"),
           size=11, fill="var(--paper-dim)")
    cap = t("An approximate match walks back from the value to the last threshold it has reached. 14 bags "
            "has passed 10, so it is Large; 6 has passed 4 but not 10.",
            "Uma correspondência aproximada volta do valor até o último limite que ele alcançou. 14 sacos "
            "passaram de 10, então é Large; 6 passou de 4, mas não de 10.")
    return s, cap


def shifted(t):
    s = Svg(720, 230, "l04-shifted", t(
        "Two copies of the header row of Products, counted from 1 under each column. Before: Code, "
        "Product, Origin, Roast, Grams, List price, Unit cost, and the column number 6 of the VLOOKUP "
        "points at List price. After a Supplier column is inserted after Grams, the number 6 points at "
        "the new, empty Supplier column, and List price has become column 7.",
        "Duas cópias da linha de cabeçalho de Products, contadas a partir de 1 embaixo de cada coluna. "
        "Antes: Code, Product, Origin, Roast, Grams, List price, Unit cost, e o número de coluna 6 do "
        "PROCV aponta para List price. Depois que uma coluna Supplier é inserida depois de Grams, o "
        "número 6 aponta para a nova coluna Supplier, vazia, e List price virou a coluna 7."))
    before = ["Code", "Product", "Origin", "Roast", "Grams", "List price", "Unit cost"]
    after = ["Code", "Product", "Origin", "Roast", "Grams", "Supplier", "List price", "Unit cost"]
    w = 74
    for k, (hdr, y, label) in enumerate(((before, 50, t("before", "antes")), (after, 150, t("after", "depois")))):
        x = 60
        s.sans(12, y + 13, label, size=11, fill="var(--paper-dim)")
        s.grid(x, y, [w] * len(hdr), [hdr], rowh=26, header=True,
               fills={(0, 5): "var(--panel)"} if k == 1 else {},
               colours={(0, 5): "var(--amber)"} if k == 1 else {(0, 5): "var(--phosphor)"}, size=10)
        for i in range(len(hdr)):
            col = "var(--paper-dim)"
            if i == 5:
                col = "var(--amber)" if k == 1 else "var(--phosphor)"
            s.mono(x + i * w + w / 2, y + 40, str(i + 1), size=10.5, fill=col, anchor="middle",
                   weight="600" if i == 5 else None)
    s.sans(60, 120, t("VLOOKUP(…, 6, FALSE) brings back List price", "PROCV(…; 6; FALSO) traz List price"),
           size=11, fill="var(--phosphor)")
    s.sans(60, 220, t("the same 6 now brings back the empty Supplier: 0 on every row",
                      "o mesmo 6 agora traz a Supplier vazia: 0 em toda linha"), size=11, fill="var(--amber)")
    cap = t("The column number is a count typed once. Insert a column inside the table and the count points "
            "at a different field, with no error.",
            "O número da coluna é uma contagem digitada uma vez. Insira uma coluna dentro da tabela e a "
            "contagem aponta para outro campo, sem erro nenhum.")
    return s, cap


FIGS = {"l04-lookup": lookup, "l04-approx": approx, "l04-shifted": shifted}
