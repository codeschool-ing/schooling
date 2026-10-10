"""Lesson 16's figures: a cell's filter context, and what SAMEPERIODLASTYEAR
compares when the year is only half over."""
from fig import Svg


def n(t, v):
    s = f"{v:,}"
    return t(s, s.replace(",", "."))


def context(t):
    s = Svg(760, 330, "l16-context", t(
        "How one pivot cell is computed. A pivot table has Origin in its rows and Year in its columns; the "
        "cell for Cerrado in 2025 is highlighted. Its row label filters Products to Origin Cerrado, which "
        "keeps the codes CER250 and CER1K. Its column label filters Calendar to Year 2025, 365 days. Both "
        "filters flow into Sales, which keeps 24 sales, and SUM of Sales Revenue over them gives 14,110.",
        "Como uma célula da tabela dinâmica é calculada. A tabela dinâmica tem Origin nas linhas e Year "
        "nas colunas; a célula de Cerrado em 2025 está destacada. O rótulo da linha filtra Products para "
        "Origin Cerrado, o que deixa os códigos CER250 e CER1K. O rótulo da coluna filtra Calendar para "
        "Year 2025, 365 dias. Os dois filtros correm até Sales, que fica com 24 vendas, e a SOMA de "
        "Revenue de Sales sobre elas dá 14.110."))
    # The pivot table.
    s.sans(20, 22, t("1  the cell", "1  a célula"), size=12, weight="600", fill="var(--phosphor)")
    w = [104, 62, 62]
    rows = [["Origin", "2025", "2026"],
            ["Cerrado", n(t, 14110), n(t, 8083)],
            ["Mogiana", n(t, 2969), n(t, 385)],
            ["Sul de Minas", n(t, 18472), n(t, 7475)],
            [t("Grand Total", "Total Geral"), n(t, 35551), n(t, 15943)]]
    x0, y0, rh = 20, 42, 24
    for r, row in enumerate(rows):
        cx = x0
        for c, cw in enumerate(w):
            head = r == 0 or r == 4
            s.rect(cx, y0 + r * rh, cw, rh, fill="var(--scan)" if head else "var(--panel)")
            v = row[c]
            if r == 4 and c == 0:
                s.sans(cx + 6, y0 + r * rh + rh / 2, v, size=10.5, weight="600")
            else:
                s.mono(cx + (6 if c == 0 else cw - 6), y0 + r * rh + rh / 2 + 0.5, v, size=10.5,
                       anchor="start" if c == 0 else "end", weight="600" if head else None)
            cx += cw
    hx, hy = x0 + w[0], y0 + rh
    s.rect(hx, hy, w[1], rh, fill="none", stroke="var(--amber)", sw=2.2)
    # The two filters.
    s.sans(268, 22, t("2  its filters", "2  os filtros dela"), size=12, weight="600", fill="var(--phosphor)")
    fx, fw = 268, 200

    def filt(y, table, cond, kept, why):
        s.rect(fx, y, fw, 24, fill="var(--scan)")
        s.mono(fx + 8, y + 12.5, table, size=11, weight="600")
        s.rect(fx, y + 24, fw, 50)
        s.mono(fx + 8, y + 37, cond, size=10.5, fill="var(--amber)")
        s.mono(fx + 8, y + 59, kept, size=10.5)
        s.sans(fx, y + 88, why, size=10, fill="var(--paper-dim)")
    filt(42, "Products", 'Origin = "Cerrado"', "CER250, CER1K",
         t("from the row label", "do rótulo da linha"))
    filt(168, "Calendar", "Year = 2025", t("365 days", "365 dias"),
         t("from the column label", "do rótulo da coluna"))
    tx = x0 + sum(w) + 3
    s.arrow(tx, hy + 8, fx - 4, 72)
    s.arrow(tx, hy + rh - 6, fx - 4, 196)
    # Sales, filtered.
    s.sans(520, 22, t("3  the sales left", "3  as vendas que sobram"), size=12, weight="600", fill="var(--phosphor)")
    sw_ = [64, 70, 86]
    sales = [["Sale", "Product", "Revenue"],
             ["S1001", "CER1K", n(t, 1456)], ["S1003", "CER1K", "115"], ["S1005", "CER1K", "460"],
             ["S1011", "CER1K", "520"], ["…", "…", "…"]]
    s.grid(520, 42, sw_, sales, rowh=24, anchors={2: "end"})
    s.sans(520, 202, t("24 sales of 2025 with a Cerrado product", "24 vendas de 2025 de um produto do Cerrado"),
           size=10, fill="var(--paper-dim)")
    s.arrow(fx + fw + 4, 100, 516, 100)
    s.arrow(fx + fw + 4, 222, 516, 150)
    # The measure.
    s.sans(268, 290, t("4  the measure, over those rows", "4  a medida, sobre essas linhas"), size=12,
           weight="600", fill="var(--phosphor)")
    s.rect(520, 274, 220, 32, fill="var(--scan)", stroke="var(--amber)", sw=1.6)
    s.mono(530, 290.5, "SUM(Sales[Revenue])", size=11)
    s.mono(730, 290.5, n(t, 14110), size=12, anchor="end", weight="600", fill="var(--amber)")
    s.arrow(630, 212, 630, 270)
    cap = t("One cell, four steps: the cell's labels filter the dimensions, the relationships carry the "
            "filters into Sales, and the measure runs over the rows that are left. One cell down, the same "
            "measure meets other filters.",
            "Uma célula, quatro passos: os rótulos da célula filtram as dimensões, as relações levam os "
            "filtros até Sales, e a medida roda sobre as linhas que sobram. Uma célula abaixo, a mesma "
            "medida encontra outros filtros.")
    return s, cap


def sameperiod(t):
    s = Svg(760, 340, "l16-sameperiod", t(
        "Two rows of 24 months, January 2025 to December 2026; the months with sales are 2025 and January to "
        "June 2026. In the first row the cell is the whole year 2026, and SAMEPERIODLASTYEAR moves it to the "
        "whole of 2025: 15,943 against 35,551, minus 55.2 percent. In the second row a slicer keeps months 1 "
        "to 6, so the cell is January to June 2026 and last year is January to June 2025: 15,943 against "
        "17,789, minus 10.4 percent.",
        "Duas linhas de 24 meses, de janeiro de 2025 a dezembro de 2026; os meses com venda são 2025 e "
        "janeiro a junho de 2026. Na primeira linha a célula é o ano inteiro de 2026, e SAMEPERIODLASTYEAR "
        "a leva para o ano inteiro de 2025: 15.943 contra 35.551, menos 55,2 por cento. Na segunda linha "
        "uma segmentação deixa os meses 1 a 6, então a célula é janeiro a junho de 2026 e o ano anterior é "
        "janeiro a junho de 2025: 15.943 contra 17.789, menos 10,4 por cento."))
    letters = "JFMAMJJASOND"
    cw, x0 = 28, 44

    def mx(i):
        return x0 + i * cw + (10 if i >= 12 else 0)

    def strip(y):
        s.mono(mx(0), y - 10, "2025", size=10.5, fill="var(--paper-dim)")
        s.mono(mx(12), y - 10, "2026", size=10.5, fill="var(--paper-dim)")
        for i in range(24):
            sold = i < 18
            s.rect(mx(i), y, cw, 26, fill="var(--scan)" if sold else "var(--panel)",
                   dash=None if sold else "3 3")
            s.mono(mx(i) + cw / 2, y + 13.5, letters[i % 12], size=10.5, anchor="middle",
                   fill="var(--paper)" if sold else "var(--paper-dim)")

    def bracket(a, b, y, colour, label):
        x1, x2 = mx(a) + 2, mx(b) + cw - 2
        s.path(f"M{x1:.1f} {y:.1f} L{x1:.1f} {y + 7:.1f} L{x2:.1f} {y + 7:.1f} L{x2:.1f} {y:.1f}",
               stroke=colour, sw=1.8)
        s.sans((x1 + x2) / 2, y + 21, label, size=10.5, fill=colour, anchor="middle")
        return (x1 + x2) / 2

    # Scenario 1: the whole year.
    s.sans(20, 20, t("the year's row: the cell is all of 2026", "a linha do ano: a célula é 2026 inteiro"),
           size=12, weight="600", fill="var(--phosphor)")
    strip(48)
    bracket(12, 23, 80, "var(--amber)", t("the cell: Jan to Dec 2026", "a célula: jan a dez de 2026"))
    bracket(0, 11, 80, "var(--paper-dim)", t("last year: Jan to Dec 2025", "ano anterior: jan a dez de 2025"))
    s.sans(20, 134, t("15,943 against 35,551: −55.2%, six months against twelve",
                      "15.943 contra 35.551: −55,2%, seis meses contra doze"), size=11.5, weight="600")
    # Scenario 2: a slicer on months 1 to 6.
    s.sans(20, 184, t("a slicer on Calendar[Month], 1 to 6", "uma segmentação em Calendar[Month], de 1 a 6"),
           size=12, weight="600", fill="var(--phosphor)")
    strip(212)
    bracket(12, 17, 244, "var(--amber)", t("the cell: Jan to Jun 2026", "a célula: jan a jun de 2026"))
    bracket(0, 5, 244, "var(--paper-dim)", t("last year: Jan to Jun 2025", "ano anterior: jan a jun de 2025"))
    s.sans(20, 298, t("15,943 against 17,789: −10.4%, six months against six",
                      "15.943 contra 17.789: −10,4%, seis meses contra seis"), size=11.5, weight="600")
    s.rect(560, 296, 12, 12, fill="var(--scan)")
    s.sans(578, 302, t("a month with sales", "mês com vendas"), size=10, fill="var(--paper-dim)")
    s.rect(560, 316, 12, 12, fill="var(--panel)", dash="3 3")
    s.sans(578, 322, t("in the calendar, no sales", "no calendário, sem vendas"), size=10, fill="var(--paper-dim)")
    cap = t("SAMEPERIODLASTYEAR moves whatever dates the cell has. When the cell is a whole year, last year "
            "is a whole year too, and six months of sales are compared with twelve.",
            "SAMEPERIODLASTYEAR move as datas que a célula tiver. Quando a célula é um ano inteiro, o ano "
            "anterior também é, e seis meses de vendas são comparados com doze.")
    return s, cap


FIGS = {"l16-context": context, "l16-sameperiod": sameperiod}
