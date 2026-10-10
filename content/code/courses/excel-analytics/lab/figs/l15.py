"""Lesson 15's figure: the Café Serra model as a star."""
from fig import Svg

ROW, HEAD = 20, 24


def box(s, x, y, w, name, rows, cols, keys=()):
    """A table of the model: its name, its row count and its columns, the
    keys drawn in amber. Returns the y of each column's centre."""
    s.rect(x, y, w, HEAD, fill="var(--scan)")
    s.mono(x + 8, y + HEAD / 2 + 0.5, name, size=11, weight="600")
    s.sans(x + w - 8, y + HEAD / 2, rows, size=10, fill="var(--paper-dim)", anchor="end")
    ys = {}
    for i, c in enumerate(cols):
        cy = y + HEAD + i * ROW
        s.rect(x, cy, w, ROW)
        s.mono(x + 10, cy + ROW / 2 + 0.5, c, size=10.5,
               fill="var(--amber)" if c in keys else "var(--paper)")
        ys[c] = cy + ROW / 2
    return ys


def star(t):
    s = Svg(760, 480, "l15-star", t(
        "The Café Serra data model as a star schema. In the middle, the fact table Sales, 108 rows, with "
        "the columns Sale, Date, Customer, Product, Bags, Price, Channel and Revenue. Around it three "
        "dimensions: Calendar, 730 rows, joined from Sales Date to Calendar Date; Products, 6 rows, "
        "joined from Sales Product to Products Code; Customers, 11 rows, joined from Sales Customer to "
        "Customers Customer. Each line has a 1 at the dimension and an asterisk at Sales, and an arrow "
        "pointing into Sales: the way a filter flows.",
        "O modelo de dados da Café Serra como um esquema em estrela. No meio, a tabela de fatos Sales, "
        "108 linhas, com as colunas Sale, Date, Customer, Product, Bags, Price, Channel e Revenue. Em "
        "volta, três dimensões: Calendar, 730 linhas, ligada de Date em Sales a Date em Calendar; "
        "Products, 6 linhas, ligada de Product em Sales a Code em Products; Customers, 11 linhas, "
        "ligada de Customer em Sales a Customer em Customers. Cada linha tem um 1 na dimensão e um "
        "asterisco em Sales, e uma seta apontando para Sales: o sentido em que o filtro corre."))
    # The fact table in the middle.
    fx, fy, fw = 290, 150, 180
    s.sans(fx, fy - 14, t("fact: one row per sale", "fato: uma linha por venda"), size=11,
           fill="var(--phosphor)", weight="600")
    f = box(s, fx, fy, fw, "Sales", t("108 rows", "108 linhas"),
            ["Sale", "Date", "Customer", "Product", "Bags", "Price", "Channel", "Revenue"],
            keys=("Date", "Customer", "Product"))
    # Dimensions.
    cx, cy, cw = 20, 196, 180
    s.sans(cx, cy - 14, t("dimension: one row per day", "dimensão: uma linha por dia"), size=11,
           fill="var(--phosphor)", weight="600")
    c = box(s, cx, cy, cw, "Calendar", t("730 rows", "730 linhas"),
            ["Date", "Year", "Month", "Month name", "Quarter"], keys=("Date",))
    px, py, pw = 560, 262, 180
    s.sans(px, py - 14, t("dimension: one row per product", "dimensão: uma linha por produto"), size=11,
           fill="var(--phosphor)", weight="600")
    p = box(s, px, py, pw, "Products", t("6 rows", "6 linhas"),
            ["Code", "Product", "Origin", "Roast", "Grams", "List price", "Unit cost"], keys=("Code",))
    ux, uy, uw = 560, 40, 180
    s.sans(ux, uy - 14, t("dimension: one row per customer", "dimensão: uma linha por cliente"), size=11,
           fill="var(--phosphor)", weight="600")
    u = box(s, ux, uy, uw, "Customers", t("11 rows", "11 linhas"),
            ["Customer", "Name", "Type", "City", "State", "Since"], keys=("Customer",))

    def link(points, one_at, many_at):
        d = "M" + " L".join(f"{x:.1f} {y:.1f}" for x, y in points[:-1])
        s.path(d, stroke="var(--amber)", sw=1.6)
        (x1, y1), (x2, y2) = points[-2], points[-1]
        s.arrow(x1, y1, x2, y2)
        s.mono(one_at[0], one_at[1], "1", size=11, fill="var(--amber)", anchor="middle", weight="600")
        s.mono(many_at[0], many_at[1], "*", size=13, fill="var(--amber)", anchor="middle", weight="600")

    # Calendar[Date] -> Sales[Date]
    link([(cx + cw, c["Date"]), (245, c["Date"]), (245, f["Date"]), (fx - 2, f["Date"])],
         (cx + cw + 9, c["Date"] - 9), (fx - 10, f["Date"] - 9))
    # Products[Code] -> Sales[Product]
    link([(px, p["Code"]), (520, p["Code"]), (520, f["Product"]), (fx + fw + 2, f["Product"])],
         (px - 9, p["Code"] - 9), (fx + fw + 10, f["Product"] + 11))
    # Customers[Customer] -> Sales[Customer]
    link([(ux, u["Customer"]), (505, u["Customer"]), (505, f["Customer"]), (fx + fw + 2, f["Customer"])],
         (ux - 9, u["Customer"] - 9), (fx + fw + 10, f["Customer"] - 9))

    ly = 458
    s.mono(30, ly, "1", size=11, fill="var(--amber)", anchor="middle", weight="600")
    s.sans(42, ly, t("one row per key: the one side", "uma linha por chave: o lado um"), size=10.5,
           fill="var(--paper-dim)")
    s.mono(270, ly + 1, "*", size=13, fill="var(--amber)", anchor="middle", weight="600")
    s.sans(282, ly, t("many sales point at it: the many side", "muitas vendas apontam para ela: o lado muitos"),
           size=10.5, fill="var(--paper-dim)")
    s.arrow(540, ly, 566, ly)
    s.sans(574, ly, t("the way a filter flows", "o sentido em que o filtro corre"), size=10.5,
           fill="var(--paper-dim)")
    cap = t("The model as a star: one fact table, three dimensions, three relationships. A filter on a "
            "dimension flows along its line into Sales, and never back.",
            "O modelo como estrela: uma tabela de fatos, três dimensões, três relações. Um filtro numa "
            "dimensão corre pela linha até Sales, e nunca volta.")
    return s, cap


FIGS = {"l15-star": star}
