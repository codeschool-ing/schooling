"""Lesson 17's figures. Every value drawn is computed here from the sales of
lesson 1 section `your-data`, the same way lab/l17.py computes the ones the
prose quotes."""
from engine import rows
from fig import Svg

SALES = rows("Sales")[1:]


def rev(year, months, channel=None, product=None):
    return sum(s[4] * s[5] for s in SALES
               if s[1].year == year and s[1].month in months
               and (channel is None or s[6] == channel) and (product is None or s[3] == product))


def money(n, t):
    en = f"R$ {n:,}"
    return t(en, en.replace(",", "."))


def pct(x, t):
    en = f"{x:+.1f}%".replace("-", "−")
    return t(en, en.replace(".", ","))


H1 = range(1, 7)


def layout(t):
    s = Svg(760, 540, "l17-layout", t(
        "A sketch of Café Serra's dashboard on one screen. At the top, a title with the date the data "
        "runs to, a Channel slicer and a timeline set to January to June 2026. Below, four KPI cards: "
        "revenue, bags, sales and average sale, each with last year's figure and the change. In the "
        "middle, a column chart of revenue per month, 2025 beside 2026, in which the first three "
        "months of 2026 are higher and the last three much lower. At the bottom, two bar charts: "
        "revenue by channel and by product, January to June 2026.",
        "Um esboço do painel da Café Serra numa tela. No topo, um título com a data até onde vão os "
        "dados, uma segmentação Channel e uma linha do tempo de janeiro a junho de 2026. Abaixo, "
        "quatro cartões de KPI: receita, sacos, vendas e venda média, cada um com o número do ano "
        "anterior e a variação. No meio, um gráfico de colunas da receita por mês, 2025 ao lado de "
        "2026, em que os três primeiros meses de 2026 são maiores e os três últimos bem menores. "
        "Embaixo, dois gráficos de barras: receita por canal e por produto, de janeiro a junho de 2026."))
    # The frame of the sheet.
    s.rect(10, 8, 740, 524, fill="var(--ink)", stroke="var(--wire)")
    s.sans(24, 26, t("Café Serra · sales · data to 23 June 2026",
                     "Café Serra · vendas · dados até 23 de junho de 2026"), size=13, weight="600")
    # Controls.
    s.rect(24, 42, 300, 44, fill="var(--panel)")
    s.mono(32, 54, "Channel", size=10, fill="var(--paper-dim)")
    for i, ch in enumerate(["Online", "Shop", "Wholesale"]):
        s.rect(32 + i * 96, 62, 90, 18, fill="var(--scan)", stroke="var(--phosphor-dim)", rx=3)
        s.mono(77 + i * 96, 71.5, ch, size=10, anchor="middle")
    s.rect(340, 42, 396, 44, fill="var(--panel)")
    s.mono(348, 54, "Calendar[Date]", size=10, fill="var(--paper-dim)")
    months = [t(m, p) for m, p in zip(["J", "F", "M", "A", "M", "J", "J", "A", "S", "O", "N", "D"],
                                      ["J", "F", "M", "A", "M", "J", "J", "A", "S", "O", "N", "D"])]
    for i, m in enumerate(months):
        x = 350 + i * 31
        s.rect(x, 62, 29, 18, fill="var(--phosphor-dim)" if i < 6 else "var(--scan)", rx=2)
        s.mono(x + 14.5, 71.5, m, size=9.5, anchor="middle",
               fill="var(--ink)" if i < 6 else "var(--paper-dim)")
    s.mono(728, 54, "2026", size=10, fill="var(--paper-dim)", anchor="end")
    # KPI cards.
    rv, rv_ly = rev(2026, H1), rev(2025, H1)
    n = sum(1 for x in SALES if x[1].year == 2026 and x[1].month <= 6)
    n_ly = sum(1 for x in SALES if x[1].year == 2025 and x[1].month <= 6)
    bags = sum(x[4] for x in SALES if x[1].year == 2026 and x[1].month <= 6)
    bags_ly = sum(x[4] for x in SALES if x[1].year == 2025 and x[1].month <= 6)
    avg, avg_ly = round(rv / n), round(rv_ly / n_ly)
    cards = [
        (t("Revenue", "Receita"), money(rv, t), money(rv_ly, t), 100 * (rv - rv_ly) / rv_ly),
        (t("Bags", "Sacos"), str(bags), str(bags_ly), 100 * (bags - bags_ly) / bags_ly),
        (t("Sales", "Vendas"), str(n), str(n_ly), 100 * (n - n_ly) / n_ly),
        (t("Average sale", "Venda média"), money(avg, t), money(avg_ly, t),
         100 * ((rv / n) / (rv_ly / n_ly) - 1)),
    ]
    for i, (label, now, ly, ch) in enumerate(cards):
        x = 24 + i * 180
        s.rect(x, 98, 170, 76, fill="var(--panel)")
        s.sans(x + 10, 112, label, size=10.5, fill="var(--paper-dim)")
        s.mono(x + 10, 136, now, size=17, weight="600")
        worse = ch < -0.05
        s.mono(x + 10, 160, pct(ch, t), size=11, weight="600",
               fill="var(--amber)" if worse else "var(--paper)")
        s.sans(x + 72, 160, t("vs ", "vs ") + ly, size=10, fill="var(--paper-dim)")
    # Months chart.
    s.rect(24, 186, 712, 180, fill="var(--panel)")
    s.sans(34, 200, t("Revenue per month, R$", "Receita por mês, R$"), size=11, weight="600")
    s.rect(560, 194, 10, 10, fill="var(--wire)", stroke="none")
    s.sans(574, 199.5, "2025", size=10, fill="var(--paper-dim)")
    s.rect(620, 194, 10, 10, fill="var(--phosphor)", stroke="none")
    s.sans(634, 199.5, "2026", size=10, fill="var(--paper-dim)")
    base, top = 344, 220
    vals = [(rev(2025, [m]), rev(2026, [m])) for m in H1]
    peak = max(max(v) for v in vals)
    names = [t(m, p) for m, p in zip(["Jan", "Feb", "Mar", "Apr", "May", "Jun"],
                                      ["jan", "fev", "mar", "abr", "mai", "jun"])]
    s.line(44, base, 716, base, stroke="var(--paper-dim)")
    for i, ((a, b), nm) in enumerate(zip(vals, names)):
        cx = 70 + i * 110
        for j, (v, colour) in enumerate(((a, "var(--wire)"), (b, "var(--phosphor)"))):
            h = (base - top) * v / peak
            s.rect(cx + j * 34, base - h, 30, h, fill=colour, stroke="none")
            s.mono(cx + j * 34 + 15, base - h - 7, t(f"{v:,}", f"{v:,}".replace(",", ".")),
                   size=9, anchor="middle", fill="var(--paper-dim)")
        s.sans(cx + 32, base + 12, nm, size=10, anchor="middle", fill="var(--paper-dim)")
    # Breakdowns.
    def bars(x0, title, items):
        s.rect(x0, 378, 352, 146, fill="var(--panel)")
        s.sans(x0 + 10, 392, title, size=11, weight="600")
        mx = max(v for _, v in items)
        for i, (k, v) in enumerate(items):
            y = 406 + i * (108 / len(items))
            hh = 108 / len(items) - 4
            s.mono(x0 + 70, y + hh / 2 + 0.5, k, size=9.5, anchor="end")
            s.rect(x0 + 76, y, 200 * v / mx, hh, fill="var(--phosphor)", stroke="none")
            s.mono(x0 + 80 + 200 * v / mx, y + hh / 2 + 0.5, t(f"{v:,}", f"{v:,}".replace(",", ".")),
                   size=9, fill="var(--paper-dim)")
    chans = sorted(((c, rev(2026, H1, channel=c)) for c in ("Wholesale", "Online", "Shop")),
                   key=lambda kv: -kv[1])
    prods = sorted(((p, rev(2026, H1, product=p)) for p in
                    ("SUL250", "SUL1K", "CER250", "CER1K", "MOG250", "DEC250")), key=lambda kv: -kv[1])
    bars(24, t("Revenue by channel, R$", "Receita por canal, R$"), chans)
    bars(384, t("Revenue by product, R$", "Receita por produto, R$"), prods)
    cap = t("The dashboard with the timeline on January to June 2026 and every channel selected. The "
            "cards answer whether the half-year is behind; the months say when it fell behind; the "
            "two charts at the bottom say where.",
            "O painel com a linha do tempo de janeiro a junho de 2026 e todos os canais selecionados. Os "
            "cartões respondem se o semestre está atrás; os meses dizem quando ficou atrás; os dois "
            "gráficos de baixo dizem onde.")
    return s, cap


def wiring(t):
    s = Svg(760, 390, "l17-wiring", t(
        "How the dashboard is wired. On the left, the data model with the tables Sales, Products, "
        "Customers and Calendar and the measures of lesson 16. In the middle, a sheet called Calc "
        "holding four pivot tables built from the model: KPI, Month, Channel and Product. On the "
        "right, the Dashboard sheet: KPI cells that read the KPI pivot with GETPIVOTDATA, and three "
        "PivotCharts drawn from the other three pivots. Below, a Channel slicer and a Calendar Date "
        "timeline whose report connections run to all four pivot tables.",
        "Como o painel é ligado. À esquerda, o modelo de dados com as tabelas Sales, Products, "
        "Customers e Calendar e as medidas da aula 16. No meio, uma planilha chamada Calc com quatro "
        "tabelas dinâmicas montadas a partir do modelo: KPI, Month, Channel e Product. À direita, a "
        "planilha Dashboard: células de KPI que leem a tabela KPI com INFODADOSTABELADINÂMICA, e três "
        "gráficos dinâmicos desenhados a partir das outras três. Embaixo, uma segmentação Channel e "
        "uma linha do tempo Calendar[Date] cujas conexões de relatório vão às quatro tabelas."))
    # The data model.
    s.rect(20, 30, 180, 270, fill="var(--panel)")
    s.sans(30, 46, t("data model", "modelo de dados"), size=11.5, weight="600")
    for i, name in enumerate(["Sales", "Products", "Customers", "Calendar"]):
        s.rect(30, 58 + i * 26, 160, 22, fill="var(--scan)")
        s.mono(38, 69.5 + i * 26, name, size=10.5)
    s.sans(30, 176, t("measures, lesson 16", "medidas, aula 16"), size=10.5, fill="var(--paper-dim)")
    for i, m in enumerate(["Total Revenue", "Revenue LY", "Revenue YoY %", "Bags Sold", "Sales Count", "Average Sale"]):
        s.mono(38, 194 + i * 17, m, size=10, fill="var(--phosphor)")
    # Calc.
    s.rect(250, 30, 196, 270, fill="var(--ink)", stroke="var(--paper-dim)", dash="4 3")
    s.mono(260, 46, "Calc", size=11.5, weight="600")
    s.sans(438, 46, t("hidden sheet", "planilha oculta"), size=10, fill="var(--paper-dim)", anchor="end")
    s.arrow(200, 46, 248, 46, stroke="var(--paper-dim)", sw=1.3)
    pivots = ["KPI", "Month", "Channel", "Product"]
    parts = [t("KPI cells", "células de KPI"), t("chart of months", "gráfico dos meses"),
             t("chart of channels", "gráfico dos canais"), t("chart of products", "gráfico dos produtos")]
    chart = t("PivotChart", "Gráfico Dinâmico")
    via = [t("GETPIVOTDATA", "INFODADOSTABELADINÂMICA"), chart, chart, chart]
    s.rect(560, 30, 180, 270, fill="var(--ink)", stroke="var(--paper-dim)")
    s.mono(570, 46, "Dashboard", size=11.5, weight="600")
    for i, (p, part, v) in enumerate(zip(pivots, parts, via)):
        y = 64 + i * 58
        s.rect(290, y, 140, 40, fill="var(--panel)")
        s.mono(300, y + 14, p, size=10.5, weight="600")
        s.sans(300, y + 29, t("pivot table", "tabela dinâmica"), size=9.5, fill="var(--paper-dim)")
        s.rect(575, y, 150, 40, fill="var(--scan)")
        s.sans(585, y + 20.5, part, size=10.5)
        s.arrow(430, y + 20, 573, y + 20, stroke="var(--paper-dim)", sw=1.3)
        s.mono(502, y + 11, v, size=8.5, anchor="middle", fill="var(--paper-dim)")
    # Slicer and timeline, and their report connections.
    s.rect(575, 318, 70, 30, fill="var(--scan)", stroke="var(--amber)", rx=3)
    s.mono(610, 333.5, "Channel", size=10, anchor="middle")
    s.rect(652, 318, 88, 30, fill="var(--scan)", stroke="var(--amber)", rx=3)
    s.mono(696, 333.5, "Calendar[Date]", size=9, anchor="middle")
    s.line(575, 333, 270, 333, stroke="var(--amber)", sw=1.6, dash="5 3")
    s.line(270, 333, 270, 84, stroke="var(--amber)", sw=1.6, dash="5 3")
    for i in range(4):
        s.arrow(270, 84 + i * 58, 288, 84 + i * 58, stroke="var(--amber)", sw=1.6)
    s.sans(280, 350, t("Report Connections: all four pivot tables ticked",
                       "Conexões de Relatório: as quatro tabelas marcadas"), size=10.5, fill="var(--amber)")
    s.sans(740, 366, t("slicer and timeline, on Dashboard", "segmentação e linha do tempo, no Dashboard"),
           size=10, fill="var(--paper-dim)", anchor="end")
    cap = t("Three layers: the model holds the data and the measures, the hidden Calc sheet holds the "
            "pivot tables, and the Dashboard shows what they answer. The slicer and the timeline reach "
            "every pivot table through their report connections, so the whole screen moves together.",
            "Três camadas: o modelo guarda os dados e as medidas, a planilha oculta Calc guarda as "
            "tabelas dinâmicas, e o Dashboard mostra o que elas respondem. A segmentação e a linha do "
            "tempo alcançam todas as tabelas pelas conexões de relatório, e a tela inteira se move junto.")
    return s, cap


FIGS = {"l17-layout": layout, "l17-wiring": wiring}
