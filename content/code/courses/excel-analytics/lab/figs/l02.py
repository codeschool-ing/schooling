"""Lesson 2's figures. Every number drawn is one lab/l02.py printed."""
from fig import Svg


def fill(t):
    s = Svg(720, 300, "l02-fill", t(
        "Columns E to I of the Sales sheet. H2 holds =E2*F2; filled down, H3 holds =E3*F3, H4 holds "
        "=E4*F4 and H109 holds =E109*F109, each multiplying the bags and the price of its own row, and "
        "showing 1456, 1972, 115 and 225. H2 pasted one column to the right, in I2, becomes =F2*G2 and "
        "shows #VALUE!, because G2 is the text Wholesale.",
        "Colunas E a I da planilha Sales. H2 tem =E2*F2; preenchida para baixo, H3 tem =E3*F3, H4 tem "
        "=E4*F4 e H109 tem =E109*F109, cada uma multiplicando os sacos e o preço da própria linha, e "
        "mostrando 1456, 1972, 115 e 225. H2 colada uma coluna à direita, em I2, vira =F2*G2 e mostra "
        "#VALOR!, porque G2 é o texto Wholesale."))
    x0, y0, rh = 56, 44, 26
    w = [52, 52, 84, 104, 92]
    cells = [["Bags", "Price", "Channel", "Revenue", ""],
             ["14", "104", "Wholesale", "=E2*F2", "=F2*G2"],
             ["17", "116", "Wholesale", "=E3*F3", ""],
             ["1", "115", "Online", "=E4*F4", ""],
             ["…", "…", "…", "…", ""],
             ["5", "45", "Online", "=E109*F109", ""]]
    fills = {(r, 3): "var(--scan)" for r in range(1, 6)}
    fills[(1, 4)] = "var(--scan)"
    colours = {(r, 3): "var(--phosphor)" for r in range(1, 6)}
    colours[(1, 4)] = "var(--amber)"
    s.grid(x0, y0, w, cells, rowh=rh, letters=["E", "F", "G", "H", "I"],
           numbers=["1", "2", "3", "4", "", "109"], fills=fills, colours=colours,
           anchors={0: "end", 1: "end"})
    right = x0 + sum(w)
    shows = ["1456", "1972", "115", "", "225"]
    vx = right + 30
    s.sans(vx, y0 + rh / 2, t("shows", "mostra"), size=10.5, fill="var(--paper-dim)")
    for i, v in enumerate(shows):
        if v:
            s.mono(vx, y0 + (i + 1) * rh + rh / 2, v, size=11, fill="var(--paper)")
    # The fill: an arrow down beside column H.
    s.arrow(right + 14, y0 + rh + 4, right + 14, y0 + 6 * rh - 4, stroke="var(--phosphor)")
    note_y = y0 + 6 * rh + 26
    s.sans(x0, note_y, t("H2 filled down: every copy reads its own row,",
                         "H2 preenchida para baixo: cada cópia lê a própria linha,"),
           size=11, fill="var(--phosphor)")
    s.sans(x0, note_y + 17, t("three columns left times two columns left",
                              "três colunas à esquerda vezes duas colunas à esquerda"),
           size=11, fill="var(--phosphor)")
    nx = vx + 70
    s.sans(nx, y0 + rh + rh / 2, t("H2 pasted in I2:", "H2 colada em I2:"), size=10.5,
           fill="var(--amber)")
    s.sans(nx, y0 + rh + rh / 2 + 17, t("price times channel,", "preço vezes canal,"), size=10.5,
           fill="var(--amber)")
    s.mono(nx, y0 + rh + rh / 2 + 34, "#VALUE!" if t("en", "pt") == "en" else "#VALOR!", size=11,
           fill="var(--amber)")
    cap = t("One formula, typed once in H2. Filled down, each copy multiplies the cells of its own row; "
            "pasted one column to the right, every address moves one column too.",
            "Uma fórmula, digitada uma vez em H2. Preenchida para baixo, cada cópia multiplica as células "
            "da própria linha; colada uma coluna à direita, todo endereço anda uma coluna também.")
    return s, cap


def anchor(t):
    s = Svg(720, 250, "l02-anchor", t(
        "Two copies of the share column. On the left, =H2/L2 filled down: J3 holds =H3/L3 and J4 holds "
        "=H4/L4, each arrow pointing at its own row of column L, where only L2 holds the total, so J3 "
        "and J4 show #DIV/0!. On the right, =H2/$L$2 filled down: every arrow points at L2, and the "
        "cells show 2.8%, 3.8% and 0.2%.",
        "Duas cópias da coluna de participação. À esquerda, =H2/L2 preenchida para baixo: J3 tem =H3/L3 "
        "e J4 tem =H4/L4, cada seta apontando para a própria linha da coluna L, onde só L2 tem o total, "
        "então J3 e J4 mostram #DIV/0!. À direita, =H2/$L$2 preenchida para baixo: toda seta aponta "
        "para L2, e as células mostram 2,8%, 3,8% e 0,2%."))

    def side(x, title, forms, shows, colour, fixed):
        s.sans(x, 22, title, size=12, weight="600")
        rh, jw, gap, lw = 28, 108, 60, 66
        y0 = 60
        cells = [["Share"] + [""] * 1]
        for f in forms:
            cells.append([f])
        s.grid(x + 24, y0, [jw], cells, rowh=rh, letters=["J"], numbers=["1", "2", "3", "4"],
               colours={(r, 0): colour for r in range(1, 4)})
        lx = x + 24 + jw + gap
        s.grid(lx, y0, [lw], [["Total"], ["51494"], [""], [""]], rowh=rh, letters=["L"],
               anchors={0: "end"})
        for r in range(1, 4):
            ty = y0 + (1 if fixed else r) * rh + rh / 2
            s.arrow(x + 24 + jw + 4, y0 + r * rh + rh / 2, lx - 4, ty, stroke=colour, sw=1.4)
        for r, v in enumerate(shows):
            s.mono(x + 24, y0 + 4 * rh + 22 + r * 17, v, size=10.5, fill=colour)

    side(20, t("=H2/L2, filled down", "=H2/L2, preenchida"), ["=H2/L2", "=H3/L3", "=H4/L4"],
         ["J2  2.8%" if t(1, 0) else "J2  2,8%", "J3  #DIV/0!", "J4  #DIV/0!"], "var(--amber)", False)
    side(380, t("=H2/$L$2, filled down", "=H2/$L$2, preenchida"), ["=H2/$L$2", "=H3/$L$2", "=H4/$L$2"],
         ["J2  2.8%", "J3  3.8%", "J4  0.2%"] if t(1, 0) else ["J2  2,8%", "J3  3,8%", "J4  0,2%"],
         "var(--phosphor)", True)
    cap = t("A relative reference to the total moves with every row and finds an empty cell. With dollars, "
            "every row points at the one cell that holds it.",
            "Uma referência relativa ao total anda com cada linha e encontra uma célula vazia. Com cifrões, "
            "toda linha aponta para a única célula que o guarda.")
    return s, cap


def mixed(t):
    s = Svg(720, 300, "l02-mixed", t(
        "The Products sheet with the list prices in column F, the discounts 5%, 10% and 15% in I1 to K1, "
        "and the grid of discounted prices below them. K7 holds =ROUND($F7*(1-K$1),0) and shows 38: "
        "one arrow goes left along row 7 to the list price in F7, the other up column K to the "
        "discount in K1.",
        "A planilha Products com os preços de tabela na coluna F, os descontos 5%, 10% e 15% em I1 a "
        "K1 e a grade de preços com desconto abaixo deles. K7 tem =ARRED($F7*(1-K$1);0) e mostra 38: "
        "uma seta vai para a esquerda pela linha 7 até o preço de tabela em F7, a outra sobe a coluna "
        "K até o desconto em K1."))
    pt = t("en", "pt") == "pt"
    x0, y0, rh = 46, 40, 26
    w = [70, 76, 24, 52, 52, 52]
    head = ["Code", "List price", "", "5%", "10%", "15%"]
    data = [["SUL250", "41", "", "39", "37", "35"],
            ["SUL1K", "132", "", "125", "119", "112"],
            ["CER250", "37", "", "35", "33", "31"],
            ["CER1K", "118", "", "112", "106", "100"],
            ["MOG250", "55", "", "52", "50", "47"],
            ["DEC250", "45", "", "43", "41", "38"]]
    cells = [head] + data
    fills = {(r, 2): "var(--ink)" for r in range(7)}
    colours = {}
    for r in range(1, 7):
        fills[(r, 1)] = "var(--scan)"
        colours[(r, 1)] = "var(--phosphor)"
    for c in (3, 4, 5):
        colours[(0, c)] = "var(--amber)"
    fills[(6, 5)] = "var(--scan)"
    s.grid(x0, y0, w, cells, rowh=rh, letters=["A", "F", "H", "I", "J", "K"],
           numbers=[str(i) for i in range(1, 8)], fills=fills, colours=colours,
           anchors={1: "end", 3: "end", 4: "end", 5: "end"})
    kx = x0 + sum(w[:5])
    ky = y0 + 6 * rh
    # Two routes from K7, drawn outside the cells: under the grid to F7, and up
    # the right-hand side to K1.
    fx = x0 + w[0] + w[1] / 2
    s.path(f"M{kx + w[5] / 2:.1f} {ky + rh:.1f} L{kx + w[5] / 2:.1f} {ky + rh + 14:.1f} "
           f"L{fx:.1f} {ky + rh + 14:.1f}", stroke="var(--phosphor)", sw=1.4)
    s.arrow(fx, ky + rh + 14, fx, ky + rh + 1, stroke="var(--phosphor)", sw=1.4)
    rx = kx + w[5] + 12
    s.path(f"M{kx + w[5]:.1f} {ky + rh / 2:.1f} L{rx:.1f} {ky + rh / 2:.1f} L{rx:.1f} {y0 + rh / 2:.1f}",
           stroke="var(--amber)", sw=1.4)
    s.arrow(rx, y0 + rh / 2, kx + w[5] + 1, y0 + rh / 2, stroke="var(--amber)", sw=1.4)
    nx = x0 + sum(w) + 36
    s.mono(nx, 66, "K7: =ARRED($F7*(1-K$1);0)" if pt else "K7: =ROUND($F7*(1-K$1),0)", size=11.5,
           fill="var(--paper)")
    s.mono(nx, 92, "$F7", size=11.5, fill="var(--phosphor)", weight="600")
    s.sans(nx + 40, 92, t("column F fixed, the row moves:", "coluna F fixa, a linha anda:"), size=11,
           fill="var(--phosphor)")
    s.sans(nx + 40, 110, t("each row reads its own price", "cada linha lê o próprio preço"), size=11,
           fill="var(--phosphor)")
    s.mono(nx, 140, "K$1", size=11.5, fill="var(--amber)", weight="600")
    s.sans(nx + 40, 140, t("row 1 fixed, the column moves:", "linha 1 fixa, a coluna anda:"), size=11,
           fill="var(--amber)")
    s.sans(nx + 40, 158, t("each column reads its own discount", "cada coluna lê o próprio desconto"),
           size=11, fill="var(--amber)")
    s.sans(nx, 196, t("one formula typed in I2,", "uma fórmula digitada em I2,"), size=11,
           fill="var(--paper-dim)")
    s.sans(nx, 214, t("copied to all eighteen cells", "copiada para as dezoito células"), size=11,
           fill="var(--paper-dim)")
    cap = t("Eighteen prices from one formula. Each half of it is fixed in one direction only, so every "
            "copy finds its own product's price and its own column's discount.",
            "Dezoito preços a partir de uma fórmula. Cada metade dela é fixa numa direção só, então cada "
            "cópia encontra o preço do próprio produto e o desconto da própria coluna.")
    return s, cap


FIGS = {"l02-fill": fill, "l02-anchor": anchor, "l02-mixed": mixed}
