"""Lesson 14's figures, drawn from the lesson's own files through pqfiles."""
from fig import Svg
from pqfiles import freight, split


def joins(t):
    left = ["W2012", "W2013", "W2014", "W2015"]
    right = [r["Order"] for r in freight() if r["Order"] in left]
    s = Svg(760, 330, "l14-joins", t(
        "Four orders from WebOrders on the left, W2012 to W2015, and their rows in Freight on the right. "
        "W2012 and W2015 match one row each. W2013 matches nothing. W2014 matches two rows, because it "
        "was shipped twice. A Left Outer merge of these four orders returns five rows: W2013 once with "
        "an empty freight, and W2014 twice.",
        "Quatro pedidos de WebOrders à esquerda, de W2012 a W2015, e as linhas deles em Freight à "
        "direita. W2012 e W2015 casam com uma linha cada. W2013 não casa com nada. W2014 casa com duas "
        "linhas, porque foi enviado duas vezes. Uma mesclagem Externa Esquerda desses quatro pedidos "
        "devolve cinco linhas: W2013 uma vez com frete vazio, e W2014 duas vezes."))
    s.sans(40, 20, t("WebOrders (first)", "WebOrders (primeira)"), size=12, weight="600")
    s.sans(250, 20, t("Freight (second)", "Freight (segunda)"), size=12, weight="600")
    s.sans(500, 20, t("Left Outer result", "resultado Externa Esquerda"), size=12, weight="600")
    ly = {}
    for i, k in enumerate(left):
        y = 46 + i * 62
        ly[k] = y + 14
        s.rect(40, y, 100, 28, fill="var(--panel)")
        s.mono(90, y + 14.5, k, size=12, anchor="middle")
    ry = []
    for i, k in enumerate(right):
        y = 46 + i * 62
        ry.append(y + 14)
        s.rect(250, y, 100, 28, fill="var(--panel)")
        s.mono(300, y + 14.5, k, size=12, anchor="middle")
    for i, k in enumerate(right):
        col = "var(--amber)" if right.count(k) > 1 else "var(--phosphor)"
        s.line(140, ly[k], 250, ry[i], stroke=col, sw=1.6)
    s.sans(40, 46 + 4 * 62 + 4, t("W2013: no freight row", "W2013: sem linha de frete"), size=10.5,
           fill="var(--paper-dim)")
    s.sans(40, 46 + 4 * 62 + 22, t("W2014: two freight rows, so two result rows",
                                   "W2014: duas linhas de frete, então duas linhas no resultado"),
           size=10.5, fill="var(--amber)")
    res = [["Order", "Freight"]]
    fr = {}
    for r in freight():
        fr.setdefault(r["Order"], []).append(r["Freight"])
    for k in left:
        for v in fr.get(k, [None]):
            res.append([k, "" if v is None else f"{v:.2f}"])
    colours = {(i, 0): "var(--amber)" for i, r in enumerate(res) if i and r[0] == "W2014"}
    s.grid(500, 40, [100, 90], res, rowh=26, colours=colours, anchors={1: "end"})
    s.mono(690 - 6, 40 + 2 * 26 + 13.5, "null", size=11, fill="var(--paper-dim)", anchor="end")
    s.sans(500, 40 + len(res) * 26 + 18, t(f"{len(left)} orders in, {len(res) - 1} rows out",
                                          f"{len(left)} pedidos entram, {len(res) - 1} linhas saem"),
           size=11, fill="var(--phosphor)")
    cap = t("A merge brings every matching row. An order with no match keeps its row with an empty value "
            "under Left Outer, and an order whose key repeats on the other side is repeated with it.",
            "Uma mesclagem traz toda linha que casa. Um pedido sem par mantém a linha com valor vazio na "
            "Externa Esquerda, e um pedido cuja chave se repete do outro lado se repete junto.")
    return s, cap


def unpivot(t):
    b = split("budget-2026.csv", ",")
    months = [k for k in b[0] if k != "Channel"]
    s = Svg(760, 352, "l14-unpivot", t(
        "The budget as it arrives: three rows, one per channel, and a column for each of the twelve "
        "months. After Unpivot Other Columns: thirty-six rows, each holding a channel, the old column "
        "name in Attribute and the value in Value. Online's budget for 2026-03, 600, is one cell in the "
        "first shape and one row in the second.",
        "O orçamento como chega: três linhas, uma por canal, e uma coluna para cada um dos doze meses. "
        "Depois de Desfazer Dinamização de Outras Colunas: trinta e seis linhas, cada uma com um canal, o "
        "nome da antiga coluna em Attribute e o valor em Value. O orçamento do Online para 2026-03, 600, é "
        "uma célula na primeira forma e uma linha na segunda."))
    s.sans(30, 20, t("months across: 3 rows", "meses nas colunas: 3 linhas"), size=12, weight="600")
    show = months[:3]
    wide = [["Channel"] + show + ["…"]]
    for r in b:
        wide.append([r["Channel"]] + [r[m] for m in show] + ["…"])
    hi = (2, 3)  # Online, 2026-03
    s.grid(30, 40, [82, 66, 66, 66, 26], wide, rowh=26, colours={hi: "var(--amber)"},
           fills={hi: "var(--scan)"}, anchors={1: "end", 2: "end", 3: "end"}, size=10.5)
    s.sans(30, 40 + 4 * 26 + 18, t(f"and {len(months) - 3} more month columns",
                                  f"e mais {len(months) - 3} colunas de mês"), size=10.5, fill="var(--paper-dim)")
    s.arrow(350, 92, 420, 92)
    s.sans(385, 74, t("Unpivot", "Desfazer"), size=11, anchor="middle", fill="var(--amber)", weight="600")
    s.sans(385, 112, t("Other Columns", "Outras Colunas"), size=10.5, anchor="middle", fill="var(--amber)")
    s.sans(440, 20, t(f"one row per channel per month: {len(b) * len(months)} rows",
                      f"uma linha por canal por mês: {len(b) * len(months)} linhas"), size=12, weight="600")
    long = [["Channel", "Attribute", "Value"]]
    for r in b:
        for m in months[:3]:
            long.append([r["Channel"], m, r[m]])
        long.append(["…", "…", "…"])
    hrow = [i for i, x in enumerate(long) if x[0] == "Online" and x[1] == "2026-03"][0]
    s.grid(440, 40, [92, 92, 70], long, rowh=24, anchors={2: "end"}, size=10.5,
           colours={(hrow, c): "var(--amber)" for c in range(3)}, fills={(hrow, c): "var(--scan)" for c in range(3)})
    cap = t("Unpivot keeps the column you selected and turns every other column into rows: each value of "
            "the budget now sits beside the two things that identify it, a channel and a month.",
            "Desfazer a dinamização mantém a coluna selecionada e transforma todas as outras em linhas: cada "
            "valor do orçamento agora fica ao lado das duas coisas que o identificam, um canal e um mês.")
    return s, cap


FIGS = {"l14-joins": joins, "l14-unpivot": unpivot}
