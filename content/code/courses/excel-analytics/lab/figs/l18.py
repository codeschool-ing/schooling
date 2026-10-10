"""Lesson 18's figures. The counts drawn on the edge of a sheet are the ones
lab/l18.py computes: 1,048,576 rows, and a file of 1,200,000 lines."""
from fig import Svg

ROWS = 1_048_576
LINES = 1_200_000


def n(x, t):
    en = f"{x:,}"
    return t(en, en.replace(",", "."))


def edge(t):
    s = Svg(760, 330, "l18-edge", t(
        "A CSV file of 1,200,000 lines opened in Excel. Its lines from 1 to 1,048,576 arrive in the rows "
        "of a sheet, which ends at row 1,048,576. The remaining 151,424 lines have no row to go to and "
        "are not loaded. The sheet that opens shows no gap and no error.",
        "Um arquivo CSV de 1.200.000 linhas aberto no Excel. As linhas de 1 a 1.048.576 chegam às linhas "
        "de uma planilha, que termina na linha 1.048.576. As 151.424 linhas restantes não têm para onde ir "
        "e não são carregadas. A planilha que abre não mostra buraco nem erro."))
    s.sans(40, 22, t("the file", "o arquivo"), size=12, weight="600")
    s.mono(40, 40, "orders.csv", size=10.5, fill="var(--paper-dim)")
    s.sans(470, 22, t("the sheet", "a planilha"), size=12, weight="600")
    s.mono(470, 40, "orders", size=10.5, fill="var(--paper-dim)")
    file_lines = [("1", "Order,Date,…"), ("2", "…"), ("3", "…"), ("…", ""), (n(ROWS, t), "…"),
                  (n(ROWS + 1, t), "…"), ("…", ""), (n(LINES, t), "…")]
    y0, h = 56, 26
    for i, (num, txt) in enumerate(file_lines):
        y = y0 + i * h
        lost = i >= 5
        s.rect(40, y, 230, h, fill="var(--panel)", stroke="var(--amber)" if lost else "var(--wire)",
               dash="4 3" if lost else None)
        s.mono(110, y + h / 2 + 0.5, num, size=10, anchor="end",
               fill="var(--amber)" if lost else "var(--paper-dim)")
        s.mono(122, y + h / 2 + 0.5, txt, size=10, fill="var(--amber)" if lost else "var(--paper)")
    sheet_rows = ["1", "2", "3", "…", n(ROWS, t)]
    for i, num in enumerate(sheet_rows):
        y = y0 + i * h
        s.rect(470, y, 250, h, fill="var(--panel)")
        s.mono(462, y + h / 2 + 0.5, num, size=10, anchor="end", fill="var(--paper-dim)")
        if num != "…":
            s.mono(478, y + h / 2 + 0.5, "Order,Date,…" if num == "1" else "…", size=10)
        if i != 3:
            s.arrow(272, y + h / 2, 400, y + h / 2, stroke="var(--phosphor)", sw=1.3)
    yb = y0 + 5 * h
    s.line(470, yb, 720, yb, stroke="var(--paper)", sw=2.5)
    s.sans(470, yb + 16, t("the last row a sheet has", "a última linha que uma planilha tem"),
           size=10.5, fill="var(--paper-dim)")
    # The lines that do not arrive.
    top, bot = yb, y0 + 8 * h
    s.path(f"M280 {top + 2} L292 {top + 2} L292 {bot - 2} L280 {bot - 2}", stroke="var(--amber)", sw=1.6)
    s.sans(302, top + 26, n(LINES - ROWS, t) + t(" lines", " linhas"), size=12, weight="600", fill="var(--amber)")
    s.sans(302, top + 44, t("not loaded", "não carregadas"), size=11, fill="var(--amber)")
    s.sans(470, yb + 46, t("what opens: no gap, no error,", "o que abre: sem buraco, sem erro,"),
           size=10.5, fill="var(--paper)")
    s.sans(470, yb + 62, t("a last row that is not the file's", "uma última linha que não é a do arquivo"),
           size=10.5, fill="var(--paper)")
    s.sans(40, 296, t("a warning appears once, when the file is opened", "um aviso aparece uma vez, quando o arquivo é aberto"),
           size=10.5, fill="var(--paper-dim)")
    cap = t("Opening a file longer than a sheet. The lines that fit arrive; the rest are left behind, and "
            "after the one warning the sheet looks exactly like a complete one.",
            "Abrindo um arquivo mais longo que uma planilha. As linhas que cabem chegam; o resto fica para "
            "trás, e depois do único aviso a planilha parece exatamente uma planilha completa.")
    return s, cap


def copies(t):
    s = Svg(760, 300, "l18-copies", t(
        "Two copies of one workbook over a week. On Monday the owner e-mails cafe-serra.xlsx to an "
        "employee. On Tuesday the owner's copy gains two wholesale sales. On Wednesday the employee's "
        "copy changes the price of sale S1105 from 106 to 96. On Friday there are two files with the "
        "same name, each holding a change the other lacks.",
        "Duas cópias de uma pasta de trabalho ao longo de uma semana. Na segunda, a dona manda "
        "cafe-serra.xlsx por e-mail a um funcionário. Na terça, a cópia da dona ganha duas vendas de "
        "atacado. Na quarta, a cópia do funcionário muda o preço da venda S1105 de 106 para 96. Na "
        "sexta, há dois arquivos com o mesmo nome, cada um com uma mudança que falta no outro."))
    days = [t("Monday", "segunda"), t("Tuesday", "terça"), t("Wednesday", "quarta"), t("Friday", "sexta")]
    xs = [40, 220, 400, 580]
    for x, d in zip(xs, days):
        s.sans(x + 70, 18, d, size=11.5, weight="600", anchor="middle")
    s.sans(36, 44, t("owner", "dona"), size=10.5, fill="var(--paper-dim)")
    s.sans(36, 164, t("employee", "funcionário"), size=10.5, fill="var(--paper-dim)")

    def doc(x, y, lines, colour="var(--wire)"):
        s.rect(x, y, 140, 58, fill="var(--panel)", stroke=colour)
        s.mono(x + 8, y + 14, "cafe-serra.xlsx", size=9.5, fill="var(--paper)")
        for i, (txt, c) in enumerate(lines):
            s.sans(x + 8, y + 32 + i * 15, txt, size=9.5, fill=c)

    base = (t("108 sales", "108 vendas"), "var(--paper-dim)")
    plus = (t("+ 2 wholesale sales", "+ 2 vendas de atacado"), "var(--phosphor)")
    fix = (t("S1105: price 106 → 96", "S1105: preço 106 → 96"), "var(--amber)")
    doc(xs[0], 52, [base])
    s.arrow(110, 112, 110, 170, stroke="var(--paper-dim)", sw=1.3)
    s.sans(118, 141, t("e-mail", "e-mail"), size=9.5, fill="var(--paper-dim)")
    doc(xs[0], 172, [base])
    doc(xs[1], 52, [base, plus])
    doc(xs[1], 172, [base])
    doc(xs[2], 52, [base, plus])
    doc(xs[2], 172, [base, fix])
    doc(xs[3], 52, [plus, (t("S1105 still 106", "S1105 ainda 106"), "var(--paper-dim)")], colour="var(--amber)")
    doc(xs[3], 172, [fix, (t("no new sales", "sem as vendas novas"), "var(--paper-dim)")], colour="var(--amber)")
    for x in xs[:3]:
        s.arrow(x + 142, 81, x + 178, 81, stroke="var(--paper-dim)", sw=1.2)
        if x != xs[0]:
            s.arrow(x + 142, 201, x + 178, 201, stroke="var(--paper-dim)", sw=1.2)
    s.sans(580, 256, t("two files, one name,", "dois arquivos, um nome,"), size=11, weight="600", fill="var(--amber)")
    s.sans(580, 274, t("neither is the truth", "nenhum é a verdade"), size=11, weight="600", fill="var(--amber)")
    cap = t("The week of a workbook sent by e-mail. Each copy gains a correct change the other never "
            "sees, and on Friday somebody has to merge them by eye.",
            "A semana de uma pasta de trabalho mandada por e-mail. Cada cópia ganha uma mudança correta que "
            "a outra nunca vê, e na sexta alguém precisa juntar as duas no olho.")
    return s, cap


def path(t):
    s = Svg(760, 330, "l18-path", t(
        "The first eight courses of the BI track as a column: computing-essentials, bi-business, "
        "excel-analytics, statistics, sql-databases, data-cleaning, visualization and analytics-bi. "
        "From excel-analytics, at position 3, one arrow leads to sql-databases at position 5, for records "
        "that many people write, and another to analytics-bi at position 8, for answers that many people "
        "read. Beside each, what this course hands on.",
        "Os oito primeiros cursos da trilha de BI em coluna: computing-essentials, bi-business, "
        "excel-analytics, statistics, sql-databases, data-cleaning, visualization e analytics-bi. De "
        "excel-analytics, na posição 3, uma seta leva a sql-databases, na posição 5, para registros que "
        "muita gente escreve, e outra a analytics-bi, na posição 8, para respostas que muita gente lê. Ao "
        "lado de cada um, o que este curso passa adiante."))
    courses = ["computing-essentials", "bi-business", "excel-analytics", "statistics", "sql-databases",
               "data-cleaning", "visualization", "analytics-bi"]
    y0, h = 20, 36
    for i, c in enumerate(courses):
        y = y0 + i * h
        here, target = i == 2, i in (4, 7)
        s.rect(60, y, 200, 28, fill="var(--scan)" if (here or target) else "var(--panel)",
               stroke="var(--phosphor)" if here else ("var(--amber)" if target else "var(--wire)"),
               sw=1.6 if (here or target) else 1)
        s.mono(48, y + 14.5, str(i + 1), size=10.5, anchor="end", fill="var(--paper-dim)")
        s.mono(72, y + 14.5, c, size=10.5, weight="600" if (here or target) else None,
               fill="var(--paper)" if (here or target) else "var(--paper-dim)")
    s.sans(268, y0 + 2 * h + 14, t("this course", "este curso"), size=10, fill="var(--phosphor)")
    # Arrows from position 3 to 5 and to 8, on the right.
    y3, y5, y8 = y0 + 2 * h + 14, y0 + 4 * h + 14, y0 + 7 * h + 14
    s.path(f"M260 {y3 + 6} C 320 {y3 + 6}, 320 {y5}, 262 {y5}", stroke="var(--amber)", sw=1.6)
    s.arrow(275, y5, 262, y5, stroke="var(--amber)", sw=1.6)
    s.path(f"M260 {y3 + 10} C 360 {y3 + 10}, 360 {y8}, 262 {y8}", stroke="var(--amber)", sw=1.6)
    s.arrow(275, y8, 262, y8, stroke="var(--amber)", sw=1.6)
    notes5 = [t("records that many people write", "registros que muita gente escreve"),
              t("keys, lesson 1 · constraints, lesson 8", "chaves, aula 1 · restrições, aula 8"),
              t("GROUP BY for lessons 5 and 10", "GROUP BY no lugar das aulas 5 e 10")]
    notes8 = [t("answers that many people read", "respostas que muita gente lê"),
              t("Power Query and the model, lessons 13 to 15", "Power Query e o modelo, aulas 13 a 15"),
              t("DAX, lesson 16 · the dashboard, lesson 17", "DAX, aula 16 · o painel, aula 17")]
    for i, line in enumerate(notes5):
        s.sans(390, y5 - 16 + i * 16, line, size=10.5 if i else 11,
               weight="600" if i == 0 else None, fill="var(--paper)" if i == 0 else "var(--paper-dim)")
    for i, line in enumerate(notes8):
        s.sans(390, y8 - 16 + i * 16, line, size=10.5 if i else 11,
               weight="600" if i == 0 else None, fill="var(--paper)" if i == 0 else "var(--paper-dim)")
    cap = t("Two ways out of a workbook, two courses of this track. Writing leads to the database at "
            "position 5; reading leads to the BI platform at position 8.",
            "Duas saídas de uma pasta de trabalho, dois cursos desta trilha. Escrever leva ao banco de dados "
            "na posição 5; ler leva à plataforma de BI na posição 8.")
    return s, cap


FIGS = {"l18-edge": edge, "l18-copies": copies, "l18-path": path}
