"""Lesson 8's figures."""
from fig import Svg


def chain(t):
    s = Svg(760, 300, "l08-list", t(
        "A chain of three steps. On the left, the Code column of the Products table, with six codes and a "
        "dashed seventh row for a product added later. In the middle, a name, ProductCodes, which refers to "
        "Products[Code]. On the right, the Product cell of the NewSales table with its drop-down open, "
        "listing the same six codes and, dashed, the seventh.",
        "Uma cadeia de três passos. À esquerda, a coluna Code da tabela Products, com seis códigos e uma "
        "sétima linha tracejada para um produto incluído depois. No meio, um nome, ProductCodes, que se "
        "refere a Products[Code]. À direita, a célula Product da tabela NewSales com a lista suspensa "
        "aberta, mostrando os mesmos seis códigos e, tracejado, o sétimo."))
    codes = ["SUL250", "SUL1K", "CER250", "CER1K", "MOG250", "DEC250"]
    # The table column.
    s.sans(40, 22, t("table Products, column Code", "tabela Products, coluna Code"), size=11.5, weight="600")
    x, y, w, h = 40, 40, 96, 22
    s.grid(x, y, [w], [["Code"]] + [[c] for c in codes], rowh=h, numbers=[str(i) for i in range(1, 8)])
    s.rect(x, y + 7 * h, w, h, fill="none", stroke="var(--phosphor)", dash="4 3")
    s.mono(x - 8, y + 7 * h + h / 2, "8", size=9.5, fill="var(--paper-dim)", anchor="end")
    s.sans(x, y + 8 * h + 16, t("a new product: the table", "um produto novo: a tabela"), size=10.5,
           fill="var(--phosphor)")
    s.sans(x, y + 8 * h + 31, t("grows by one row", "cresce uma linha"), size=10.5, fill="var(--phosphor)")
    # The name.
    nx, ny = 270, 100
    s.sans(nx, 22, t("a name", "um nome"), size=11.5, weight="600")
    s.rect(nx, ny, 170, 58, fill="var(--panel)", stroke="var(--amber)", rx=4)
    s.mono(nx + 85, ny + 19, "ProductCodes", size=12, anchor="middle", weight="600", fill="var(--amber)")
    s.mono(nx + 85, ny + 40, "=Products[Code]", size=11, anchor="middle")
    s.sans(nx, ny + 80, t("points at the column,", "aponta para a coluna,"), size=10.5, fill="var(--paper-dim)")
    s.sans(nx, ny + 95, t("however long it is", "do tamanho que ela for"), size=10.5, fill="var(--paper-dim)")
    s.arrow(x + w + 10, ny + 29, nx - 6, ny + 29)
    # The drop-down.
    dx, dy = 540, 40
    s.sans(dx, 22, t("the rule on NewSales[Product]", "a regra em NewSales[Product]"), size=11.5, weight="600")
    s.mono(dx, dy + 8, "Source: =ProductCodes", size=10.5, fill="var(--paper-dim)")
    s.rect(dx, dy + 24, 150, h, fill="var(--scan)")
    s.mono(dx + 6, dy + 24 + h / 2 + 0.5, "CER1K", size=10.5)
    s.rect(dx + 150, dy + 24, 22, h, fill="var(--panel)")
    s.path(f"M{dx + 155} {dy + 32} L{dx + 167} {dy + 32} L{dx + 161} {dy + 39} Z", stroke="none",
           fill="var(--paper)")
    ly = dy + 24 + h + 4
    for i, c in enumerate(codes):
        s.rect(dx, ly + i * 20, 172, 20, fill="var(--panel)", stroke="var(--wire)")
        s.mono(dx + 6, ly + i * 20 + 10.5, c, size=10.5)
    s.rect(dx, ly + 6 * 20, 172, 20, fill="none", stroke="var(--phosphor)", dash="4 3")
    s.sans(dx, ly + 7 * 20 + 16, t("and the list follows", "e a lista acompanha"), size=10.5,
           fill="var(--phosphor)")
    s.arrow(nx + 176, ny + 29, dx - 6, ny + 29)
    cap = t("The list rule reads a name, and the name reads the table's column. A product added to the "
            "Products table appears in every drop-down built on the name, and nobody edits a rule.",
            "A regra de lista lê um nome, e o nome lê a coluna da tabela. Um produto incluído na tabela "
            "Products aparece em toda lista suspensa feita sobre o nome, sem ninguém editar uma regra.")
    return s, cap


def paths(t):
    s = Svg(760, 330, "l08-paths", t(
        "Four ways a value reaches a validated cell. Only the first, typing and pressing Enter, passes "
        "through the rule, which refuses it, warns or informs. Pasting replaces the value and the rule "
        "together. A formula's new answer and a value already there when the rule was made reach the cell "
        "unchecked. Circle Invalid Data, at the bottom, checks every cell against its rule when asked.",
        "Quatro caminhos pelos quais um valor chega a uma célula validada. Só o primeiro, digitar e "
        "apertar Enter, passa pela regra, que recusa, avisa ou informa. Colar troca o valor e a regra "
        "juntos. A nova resposta de uma fórmula e um valor que já estava lá quando a regra foi criada "
        "chegam sem conferência. Circular Dados Inválidos, embaixo, confere cada célula contra a regra "
        "quando você pede."))
    rows = [
        (t("typed, then Enter", "digitado, e Enter"), True),
        (t("pasted with Ctrl+V", "colado com Ctrl+V"), False),
        (t("a formula's answer changes", "a resposta de uma fórmula muda"), False),
        (t("there before the rule existed", "já estava lá antes da regra"), False),
    ]
    gx, cx = 330, 590
    s.rect(gx, 32, 90, 66, fill="var(--scan)", stroke="var(--amber)", rx=4)
    s.sans(gx + 45, 22, t("the rule", "a regra"), size=11.5, anchor="middle", weight="600", fill="var(--amber)")
    s.rect(cx, 30, 140, 200, fill="var(--panel)", stroke="var(--wire)", rx=4)
    s.sans(cx + 70, 22, t("the cell", "a célula"), size=11.5, anchor="middle", weight="600")
    for i, (label, checked) in enumerate(rows):
        y = 55 + i * 50
        s.sans(30, y, label, size=11)
        if checked:
            s.arrow(250, y, gx - 4, y)
            s.arrow(gx + 90, y, cx - 4, y)
            s.sans(gx + 45, y + 17, t("Stop · Warning", "Parar · Aviso"), size=9.5, anchor="middle",
                   fill="var(--paper)")
            s.sans(gx + 45, y + 30, t("· Information", "· Informações"), size=9.5, anchor="middle",
                   fill="var(--paper)")
        else:
            s.line(250, y, cx - 6, y, stroke="var(--paper-dim)", sw=1.4, dash="5 4")
            s.arrow(cx - 9, y, cx - 4, y, stroke="var(--paper-dim)", sw=1.4)
            s.sans(cx + 8, y, t("unchecked", "sem conferência") if i != 1 else
                   t("rule replaced", "regra trocada"), size=10.5, fill="var(--paper-dim)")
    s.sans(cx + 8, 55, t("checked", "conferido"), size=10.5, fill="var(--phosphor)")
    s.line(30, 262, 730, 262, stroke="var(--wire)")
    s.sans(30, 285, t("Circle Invalid Data checks every cell against its rule, but only when you ask,",
                      "Circular Dados Inválidos confere cada célula contra a regra, mas só quando você pede,"),
           size=11, fill="var(--phosphor)")
    s.sans(30, 303, t("and changes nothing: it draws a circle round each value that breaks it.",
                      "e não muda nada: desenha um círculo em volta de cada valor que a desrespeita."),
           size=11, fill="var(--phosphor)")
    cap = t("Validation guards one door, typing. A paste, a recalculated formula and the data already in "
            "the sheet come in by the others, and Circle Invalid Data is how you find them.",
            "A validação vigia uma porta, a digitação. Uma colagem, uma fórmula recalculada e os dados que "
            "já estavam na planilha entram pelas outras, e Circular Dados Inválidos é como achá-los.")
    return s, cap


FIGS = {"l08-list": chain, "l08-paths": paths}
