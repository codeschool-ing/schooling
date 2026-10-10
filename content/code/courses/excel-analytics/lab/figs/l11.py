"""Lesson 11's figures. Every number drawn is computed here from the rows of
lesson 1's tables, the same rows the lesson's pivot tables summarise."""
from engine import rows
from fig import Svg


def _sales():
    head, *body = rows("Sales")
    return [dict(zip(head, r)) for r in body]


def _n(t, v, dec=0):
    s = f"{v:,.{dec}f}"
    return t(s, s.replace(",", "§").replace(".", ",").replace("§", "."))


def sums(t):
    sales = [s for s in _sales() if s["Product"] == "CER250"]
    sp = sum(s["Price"] for s in sales)
    sb = sum(s["Bags"] for s in sales)
    rev = sum(s["Price"] * s["Bags"] for s in sales)
    avg = sp / len(sales)
    s = Svg(760, 420, "l11-sums", t(
        f"The {len(sales)} sales of CER250 with their Price, Bags and Revenue, and three numbers a pivot "
        f"table can show for them. The Revenue column summed gives {rev}. A calculated field =Price*Bags "
        f"multiplies the sum of the prices, {sp}, by the sum of the bags, {sb}, and gives {sp * sb}. A "
        f"calculated field =Revenue/Bags divides {rev} by {sb} and gives the price of an average bag.",
        f"As {len(sales)} vendas de CER250 com Price, Bags e Revenue, e três números que uma tabela "
        f"dinâmica pode mostrar para elas. A coluna Revenue somada dá {rev}. Um campo calculado "
        f"=Price*Bags multiplica a soma dos preços, {sp}, pela soma dos sacos, {sb}, e dá {sp * sb}. Um "
        f"campo calculado =Revenue/Bags divide {rev} por {sb} e dá o preço de um saco médio."))
    s.sans(40, 18, t("the sales of CER250", "as vendas de CER250"), size=12, weight="600")
    cells = [["Sale", "Price", "Bags", "Revenue"]]
    for x in sales:
        cells.append([x["Sale"], str(x["Price"]), str(x["Bags"]), str(x["Price"] * x["Bags"])])
    cells.append(["Σ", str(sp), str(sb), str(rev)])
    n = len(cells)
    s.grid(40, 34, [62, 56, 50, 70], cells, rowh=24, anchors={1: "end", 2: "end", 3: "end"},
           fills={(n - 1, c): "var(--scan)" for c in range(4)},
           colours={(n - 1, 1): "var(--amber)", (n - 1, 2): "var(--amber)", (n - 1, 3): "var(--phosphor)"})
    x0 = 330
    s.sans(x0, 18, t("what the pivot table shows", "o que a tabela dinâmica mostra"), size=12, weight="600")
    boxes = [
        ("var(--phosphor)", t("the Revenue column, summed", "a coluna Revenue, somada"),
         t("Sum of Revenue", "Soma de Revenue"), f"= {rev}", t("right: each sale's own price times its bags",
                                          "certo: o preço de cada venda vezes os sacos dela")),
        ("var(--amber)", t("a calculated field =Price*Bags", "um campo calculado =Price*Bags"),
         t("Sum of Price × Sum of Bags", "Soma de Price × Soma de Bags"), f"= {sp} × {sb} = {_n(t, sp * sb)}",
         t("wrong: every price times every bag", "errado: todo preço vezes todo saco")),
        ("var(--phosphor)", t("a calculated field =Revenue/Bags", "um campo calculado =Revenue/Bags"),
         t("Sum of Revenue ÷ Sum of Bags", "Soma de Revenue ÷ Soma de Bags"), f"= {rev} ÷ {sb} = {_n(t, rev / sb, 2)}",
         t(f"right: an average bag; the average of the prices is {_n(t, avg, 2)}",
           f"certo: um saco médio; a média dos preços é {_n(t, avg, 2)}")),
    ]
    y = 34
    for colour, title, what, val, verdict in boxes:
        s.rect(x0, y, 400, 104, fill="var(--panel)", stroke=colour, rx=4, sw=1.4)
        s.sans(x0 + 14, y + 20, title, size=11.5, weight="600", fill=colour)
        s.mono(x0 + 14, y + 46, what, size=11)
        s.mono(x0 + 14, y + 66, val, size=11, weight="600", fill=colour)
        s.sans(x0 + 14, y + 88, verdict, size=10.5, fill="var(--paper-dim)")
        y += 122
    cap = t("A calculated field never sees a row. It applies its formula to the sums, so a ratio of two "
            "sums comes out right and a product of two sums comes out more than ten times too big.",
            "Um campo calculado nunca vê uma linha. Ele aplica a fórmula às somas, então a razão entre "
            "duas somas sai certa e o produto de duas somas sai mais de dez vezes grande demais.")
    return s, cap


def item(t):
    sales = _sales()
    by = {}
    for x in sales:
        by[x["Channel"]] = by.get(x["Channel"], 0) + x["Price"] * x["Bags"]
    total = sum(by.values())
    direct = by["Online"] + by["Shop"]
    s = Svg(760, 250, "l11-item", t(
        f"Two pivot tables of revenue by channel. On the left, a calculated item Direct, equal to Online "
        f"plus Shop, sits in the Channel field beside them, and the grand total adds all four rows: "
        f"{total + direct} instead of {total}. On the right, Online and Shop are grouped under Direct "
        f"and the grand total stays {total}.",
        f"Duas tabelas dinâmicas de receita por canal. À esquerda, um item calculado Direct, igual a "
        f"Online mais Shop, fica no campo Channel ao lado deles, e o total geral soma as quatro linhas: "
        f"{total + direct} em vez de {total}. À direita, Online e Shop estão agrupados em Direct e o "
        f"total geral continua {total}."))
    s.sans(40, 18, t("a calculated item: Direct = Online + Shop", "um item calculado: Direct = Online + Shop"),
           size=12, weight="600")
    head = [t("Row Labels", "Rótulos de Linha"), t("Sum of Revenue", "Soma de Revenue")]
    left = [head, ["Online", _n(t, by["Online"])], ["Shop", _n(t, by["Shop"])],
            ["Wholesale", _n(t, by["Wholesale"])], ["Direct", _n(t, direct)],
            [t("Grand Total", "Total Geral"), _n(t, total + direct)]]
    s.grid(40, 34, [150, 140], left, rowh=26, anchors={1: "end"},
           fills={(5, 0): "var(--scan)", (5, 1): "var(--scan)"},
           colours={(4, 0): "var(--amber)", (4, 1): "var(--amber)", (5, 1): "var(--amber)"})
    # A bracket from Online and Shop to Direct: the same money, twice.
    bx = 340
    s.path(f"M{bx - 8} 73 L{bx} 73 L{bx} 99 L{bx - 8} 99", stroke="var(--amber)", sw=1.4)
    s.path(f"M{bx - 8} 151 L{bx} 151", stroke="var(--amber)", sw=1.4)
    s.line(bx, 99, bx, 151, stroke="var(--amber)", sw=1.4, dash="3 3")
    s.sans(bx + 8, 125, t(f"{_n(t, direct)} counted twice", f"{_n(t, direct)} contados duas vezes"),
           size=10.5, fill="var(--amber)")
    s.sans(40, 210, t(f"the real total is {_n(t, total)}", f"o total real é {_n(t, total)}"),
           size=10.5, fill="var(--paper-dim)")
    x0 = 480
    s.sans(x0, 18, t("a group: Online and Shop under Direct", "um grupo: Online e Shop sob Direct"),
           size=12, weight="600")
    right = [head, ["Direct", _n(t, direct)], ["\u00a0\u00a0\u00a0Online", _n(t, by["Online"])],
             ["\u00a0\u00a0\u00a0Shop", _n(t, by["Shop"])], ["Wholesale", _n(t, by["Wholesale"])],
             [t("Grand Total", "Total Geral"), _n(t, total)]]
    s.grid(x0, 34, [130, 120], right, rowh=26, anchors={1: "end"},
           fills={(1, 0): "var(--scan)", (1, 1): "var(--scan)", (4, 0): "var(--scan)", (4, 1): "var(--scan)",
                  (5, 0): "var(--scan)", (5, 1): "var(--scan)"},
           colours={(5, 1): "var(--phosphor)"})
    s.sans(x0, 210, t("each sale is in exactly one row", "cada venda está em exatamente uma linha"),
           size=10.5, fill="var(--phosphor)")
    s.sans(x0, 228, t("so the total is still the total", "então o total continua sendo o total"),
           size=10.5, fill="var(--phosphor)")
    cap = t("A calculated item is a new row in the field, and the grand total adds every row it finds. "
            "A group puts the same sales under a new heading without counting them again.",
            "Um item calculado é uma linha nova no campo, e o total geral soma todas as linhas que "
            "encontra. Um grupo põe as mesmas vendas sob um título novo sem contá-las de novo.")
    return s, cap


def connections(t):
    sales = [x for x in _sales() if x["Channel"] == "Wholesale"]
    by_p, by_y = {}, {}
    for x in sales:
        by_p[x["Product"]] = by_p.get(x["Product"], 0) + x["Price"] * x["Bags"]
        by_y[x["Date"].year] = by_y.get(x["Date"].year, 0) + x["Bags"]
    s = Svg(760, 400, "l11-connections", t(
        "The table Sales feeds one pivot cache, and two pivot tables are built from it: revenue by "
        "product and bags by year. A Channel slicer set to Wholesale is connected to both, so both show "
        "only wholesale sales. A third pivot table built from a copy of the data has its own cache and "
        "does not appear in the slicer's list of connections.",
        "A tabela Sales alimenta um cache de tabela dinâmica, e duas tabelas dinâmicas são montadas a "
        "partir dele: receita por produto e sacos por ano. Uma segmentação de Channel em Wholesale está "
        "conectada às duas, então as duas mostram só as vendas de atacado. Uma terceira tabela dinâmica, "
        "montada a partir de uma cópia dos dados, tem o próprio cache e não aparece na lista de conexões "
        "da segmentação."))
    # Source and cache.
    s.rect(30, 40, 150, 50, fill="var(--scan)", stroke="var(--wire)", rx=4)
    s.sans(105, 58, t("table", "tabela"), size=10.5, anchor="middle", fill="var(--paper-dim)")
    s.mono(105, 76, "Sales", size=12, anchor="middle", weight="600")
    s.arrow(105, 90, 105, 128, stroke="var(--wire)")
    s.rect(30, 130, 150, 50, fill="var(--panel)", stroke="var(--phosphor)", rx=4, sw=1.4)
    s.sans(105, 148, t("pivot cache", "cache da tabela"), size=11, anchor="middle", weight="600",
           fill="var(--phosphor)")
    s.sans(105, 166, t("one copy of the rows", "uma cópia das linhas"), size=10, anchor="middle",
           fill="var(--paper-dim)")
    # Two pivots.
    p1 = [["Product", "Revenue"]] + [[k, _n(t, v)] for k, v in sorted(by_p.items())] + \
        [[t("Grand Total", "Total Geral"), _n(t, sum(by_p.values()))]]
    p1[0] = [t("Row Labels", "Rótulos de Linha"), t("Sum of Revenue", "Soma de Revenue")]
    s.grid(300, 40, [118, 112], p1, rowh=22, anchors={1: "end"},
           fills={(len(p1) - 1, 0): "var(--scan)", (len(p1) - 1, 1): "var(--scan)"})
    p2 = [[t("Row Labels", "Rótulos de Linha"), t("Sum of Bags", "Soma de Bags")]] + \
         [[str(k), str(v)] for k, v in sorted(by_y.items())] + \
         [[t("Grand Total", "Total Geral"), str(sum(by_y.values()))]]
    s.grid(300, 228, [118, 112], p2, rowh=22, anchors={1: "end"},
           fills={(len(p2) - 1, 0): "var(--scan)", (len(p2) - 1, 1): "var(--scan)"})
    s.arrow(180, 150, 296, 90, stroke="var(--phosphor)")
    s.arrow(180, 160, 296, 260, stroke="var(--phosphor)")
    # The slicer.
    sx, sy = 590, 110
    s.rect(sx, sy, 140, 128, fill="var(--panel)", stroke="var(--amber)", rx=4, sw=1.4)
    s.mono(sx + 12, sy + 18, "Channel", size=11, weight="600")
    for i, name in enumerate(["Online", "Shop", "Wholesale"]):
        on = name == "Wholesale"
        s.rect(sx + 12, sy + 32 + i * 30, 116, 24, fill="var(--amber)" if on else "var(--scan)",
               stroke="var(--wire)", rx=3)
        s.mono(sx + 70, sy + 44 + i * 30, name, size=10.5, anchor="middle",
               fill="var(--ink)" if on else "var(--paper-dim)", weight="600" if on else None)
    s.sans(sx, sy - 12, t("slicer", "segmentação"), size=11, weight="600", fill="var(--amber)")
    s.line(sx, sy + 50, 532, 110, stroke="var(--amber)", sw=1.4, dash="5 4")
    s.line(sx, sy + 90, 532, 270, stroke="var(--amber)", sw=1.4, dash="5 4")
    s.sans(sx - 4, sy + 150, t("Report Connections:", "Conexões de Relatório:"), size=10.5,
           fill="var(--paper-dim)")
    s.sans(sx - 4, sy + 166, t("both pivots ticked", "as duas tabelas marcadas"), size=10.5,
           fill="var(--paper-dim)")
    # A pivot from a copy: its own cache, not in the list.
    s.rect(30, 300, 150, 70, fill="var(--ink)", stroke="var(--wire)", rx=4, dash="4 3")
    s.sans(105, 318, t("a pivot built from", "uma tabela montada"), size=10, anchor="middle",
           fill="var(--paper-dim)")
    s.sans(105, 334, t("a pasted copy:", "de uma cópia colada:"), size=10, anchor="middle",
           fill="var(--paper-dim)")
    s.sans(105, 352, t("its own cache, not listed", "cache próprio, fora da lista"), size=10,
           anchor="middle", fill="var(--paper-dim)")
    cap = t("One slicer, two pivot tables. The slicer can reach every pivot table built on the same cache, "
            "and only those; ticking both in Report Connections makes one click filter both.",
            "Uma segmentação, duas tabelas dinâmicas. A segmentação alcança toda tabela montada sobre o "
            "mesmo cache, e só essas; marcar as duas em Conexões de Relatório faz um clique filtrar as duas.")
    return s, cap


FIGS = {"l11-sums": sums, "l11-item": item, "l11-connections": connections}
