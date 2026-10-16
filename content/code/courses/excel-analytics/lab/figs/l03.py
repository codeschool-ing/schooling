"""Lesson 3's figures. The counts are the ones lab/l03.py printed; the rows of
the flags figure are read out of lesson 1's data."""
from engine import rows
from fig import Svg


def bands(t):
    s = Svg(720, 330, "l03-bands", t(
        "A line of bag counts from 1 to 20, cut at 4 and at 10 into three bands: Small from 1 to 3 bags, "
        "45 sales; Medium from 4 to 9, 41 sales; Large from 10 to 20, 22 sales. Below it, the nested IF "
        "as a path: the test E2>=10 first, which leads to Large if true; otherwise the test E2>=4, which "
        "leads to Medium if true and to Small if false.",
        "Uma reta de quantidades de sacos de 1 a 20, cortada em 4 e em 10 em três faixas: Small de 1 a 3 "
        "sacos, 45 vendas; Medium de 4 a 9, 41 vendas; Large de 10 a 20, 22 vendas. Abaixo, o SE "
        "aninhado como um caminho: primeiro o teste E2>=10, que leva a Large se for verdadeiro; senão o "
        "teste E2>=4, que leva a Medium se for verdadeiro e a Small se for falso."))
    x0, x1, y = 60, 660, 70
    unit = (x1 - x0) / 20

    def X(n):
        return x0 + (n - 1) * unit

    spans = [(1, 3, "Small", "45", "var(--paper-dim)"), (4, 9, "Medium", "41", "var(--phosphor)"),
             (10, 20, "Large", "22", "var(--amber)")]
    for a, b_, name, n, col in spans:
        s.rect(X(a), y - 14, X(b_ + 1) - X(a) - 2, 28, fill="var(--scan)", stroke=col)
        s.mono(X(a) + 8, y, name, size=11.5, fill=col, weight="600")
        s.sans((X(a) + X(b_ + 1)) / 2, y - 30, t(f"{n} sales", f"{n} vendas"), size=11, fill=col,
               anchor="middle")
    for n in range(1, 21):
        s.line(X(n), y + 14, X(n), y + 20, stroke="var(--wire)")
        if n in (1, 4, 10, 20):
            s.mono(X(n), y + 30, str(n), size=10.5, fill="var(--paper)", anchor="middle")
    s.sans(x1 + 4, y + 30, t("bags", "sacos"), size=10.5, fill="var(--paper-dim)")
    # The path the formula takes.
    by = 150
    s.rect(60, by, 120, 30, fill="var(--panel)", rx=4)
    s.mono(120, by + 15, "E2>=10", size=11.5, anchor="middle")
    s.arrow(180, by + 15, 268, by + 15, stroke="var(--amber)")
    s.sans(224, by + 6, t("true", "verdadeiro"), size=10, fill="var(--amber)", anchor="middle")
    s.rect(270, by, 100, 30, fill="var(--scan)", stroke="var(--amber)", rx=4)
    s.mono(320, by + 15, '"Large"', size=11.5, fill="var(--amber)", anchor="middle")
    s.arrow(120, by + 30, 120, by + 68, stroke="var(--wire)")
    s.sans(128, by + 50, t("false", "falso"), size=10, fill="var(--paper-dim)")
    s.rect(60, by + 70, 120, 30, fill="var(--panel)", rx=4)
    s.mono(120, by + 85, "E2>=4", size=11.5, anchor="middle")
    s.arrow(180, by + 85, 268, by + 85, stroke="var(--phosphor)")
    s.sans(224, by + 76, t("true", "verdadeiro"), size=10, fill="var(--phosphor)", anchor="middle")
    s.rect(270, by + 70, 100, 30, fill="var(--scan)", stroke="var(--phosphor)", rx=4)
    s.mono(320, by + 85, '"Medium"', size=11.5, fill="var(--phosphor)", anchor="middle")
    s.arrow(120, by + 100, 120, by + 138, stroke="var(--wire)")
    s.sans(128, by + 120, t("false", "falso"), size=10, fill="var(--paper-dim)")
    s.rect(60, by + 140, 120, 30, fill="var(--scan)", rx=4)
    s.mono(120, by + 155, '"Small"', size=11.5, fill="var(--paper-dim)", anchor="middle")
    s.sans(420, by + 10, t("the first test that passes decides,", "o primeiro teste que passa decide,"),
           size=11, fill="var(--paper)")
    s.sans(420, by + 28, t("and the tests after it are never read", "e os testes depois dele nem são lidos"),
           size=11, fill="var(--paper)")
    s.sans(420, by + 70, t("tested in the other order, E2>=4 first,", "testado na outra ordem, E2>=4 antes,"),
           size=11, fill="var(--paper-dim)")
    s.sans(420, by + 88, t("catches 14 bags as Medium: 0 Large", "pega 14 sacos como Medium: 0 Large"),
           size=11, fill="var(--paper-dim)")
    cap = t("Three sizes from two tests. The nested IF asks the highest threshold first; 45, 41 and 22 "
            "sales add up to the 108.",
            "Três tamanhos a partir de dois testes. O SE aninhado pergunta primeiro pelo limite mais alto; "
            "45, 41 e 22 vendas somam as 108.")
    return s, cap


def flags(t):
    s = Svg(720, 290, "l03-flags", t(
        "Five rows of the Sales sheet with the bags in E, the year of the date, and three flag columns: "
        "Big is 1 where the sale is 10 bags or more, In 2026 is 1 where the date is in 2026, and Both "
        "is their product, 1 only where both are 1. Below the rows, the sums of the three columns over "
        "all 108 sales: 22, 36 and 5.",
        "Cinco linhas da planilha Sales com os sacos em E, o ano da data e três colunas de marcação: Big "
        "é 1 onde a venda tem 10 sacos ou mais, In 2026 é 1 onde a data é de 2026, e Both é o produto "
        "das duas, 1 só onde as duas são 1. Abaixo das linhas, as somas das três colunas nas 108 vendas: "
        "22, 36 e 5."))
    data = rows("Sales")
    pick = [2, 3, 4, 74, 76, 77]
    w = [64, 96, 52, 56, 74, 60]
    cells = [["Sale", "Date", "Bags", "Big", "In 2026", "Both"]]
    fills, colours = {}, {}
    for i, r in enumerate(pick, start=1):
        sale, date, _, _, bags = data[r - 1][:5]
        big = 1 if bags >= 10 else 0
        new = 1 if date.year >= 2026 else 0
        cells.append([sale, date.isoformat(), str(bags), str(big), str(new), str(big * new)])
        for c, v in ((3, big), (4, new), (5, big * new)):
            if v:
                colours[(i, c)] = "var(--phosphor)" if c < 5 else "var(--amber)"
        if big * new:
            fills[(i, 5)] = "var(--scan)"
    cells.insert(4, ["…", "…", "…", "…", "…", "…"])
    shifted = {}
    for (r, c), v in colours.items():
        shifted[(r + 1 if r >= 4 else r, c)] = v
    colours = shifted
    fills = {(r + 1 if r >= 4 else r, c): v for (r, c), v in fills.items()}
    nums = ["1"] + [str(r) for r in pick[:3]] + [""] + [str(r) for r in pick[3:]]
    x0, y0, rh = 60, 40, 26
    s.grid(x0, y0, w, cells, rowh=rh, letters=["A", "B", "E", "J", "K", "L"], numbers=nums,
           fills=fills, colours=colours, anchors={2: "end", 3: "end", 4: "end", 5: "end"})
    ty = y0 + len(cells) * rh + 22
    sx = x0 + sum(w[:3])
    s.sans(sx - 8, ty, t("summed over 108 rows", "somadas nas 108 linhas"), size=10.5,
           fill="var(--paper-dim)", anchor="end")
    for c, v in ((3, "22"), (4, "36"), (5, "5")):
        cx = x0 + sum(w[:c + 1]) - 6
        s.mono(cx, ty, v, size=12, fill="var(--amber)" if c == 5 else "var(--phosphor)", anchor="end",
               weight="600")
    nx = x0 + sum(w) + 30
    s.mono(nx, 66, "J: =IF(E2>=10,1,0)" if t(1, 0) else "J: =SE(E2>=10;1;0)", size=11)
    s.mono(nx, 88, "K: =IF(B2>=DATE(2026,1,1),1,0)" if t(1, 0) else "K: =SE(B2>=DATA(2026;1;1);1;0)",
           size=10.5)
    s.mono(nx, 110, "L: =J2*K2", size=11)
    s.sans(nx, 146, t("multiplying two flags is AND:", "multiplicar duas marcações é E:"), size=11,
           fill="var(--amber)")
    s.sans(nx, 164, t("1 only where both are 1", "1 só onde as duas são 1"), size=11, fill="var(--amber)")
    cap = t("Two questions as columns of ones and zeros, and their product as a third. Adding a flag "
            "column counts the rows where the answer is yes.",
            "Duas perguntas como colunas de uns e zeros, e o produto delas como uma terceira. Somar uma "
            "coluna de marcação conta as linhas em que a resposta é sim.")
    return s, cap


FIGS = {"l03-bands": bands, "l03-flags": flags}
