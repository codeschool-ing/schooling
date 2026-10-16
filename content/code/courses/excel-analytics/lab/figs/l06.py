"""Lesson 6's figures."""
import datetime

from fig import Svg
from ptformula import to_pt


def _f(t, formula):
    """A formula as the reader's Excel spells it."""
    return t(formula, to_pt(formula))


def _chars(s, x, y, text, cw, hi):
    """One box per character, numbered from 1 above; `hi` maps a position to
    a (fill, text colour) pair."""
    for i, ch in enumerate(text):
        fill, col = hi.get(i + 1, ("var(--panel)", "var(--paper)"))
        s.rect(x + i * cw, y, cw, 24, fill=fill)
        s.mono(x + i * cw + cw / 2, y + 12.5, "·" if ch == " " else ch, size=11, fill=col, anchor="middle")
        s.mono(x + i * cw + cw / 2, y - 8, str(i + 1), size=8.5, fill="var(--paper-dim)", anchor="middle")


def split(t):
    s = Svg(760, 300, "l06-split", t(
        "Two texts drawn one character per box, with positions numbered from 1. In SUL1K - Sul de Minas "
        "1 kg, FIND finds the separator at position 6, LEFT takes the 5 characters before it and MID "
        "takes the rest from position 9. In 20241202, LEFT takes 2024, MID takes 12 from position 5 and "
        "RIGHT takes 02, and DATE joins them into 2 December 2024.",
        "Dois textos desenhados com um caractere por caixa e as posições numeradas a partir de 1. Em "
        "SUL1K - Sul de Minas 1 kg, PROCURAR acha o separador na posição 6, ESQUERDA pega os 5 caracteres "
        "antes dele e EXT.TEXTO pega o resto a partir da posição 9. Em 20241202, ESQUERDA pega 2024, "
        "EXT.TEXTO pega 12 a partir da posição 5 e DIREITA pega 02, e DATA os junta em 2 de dezembro de "
        "2024."))
    item = "SUL1K - Sul de Minas 1 kg"
    pos = item.find(" - ") + 1
    cw, x0 = 24, 40
    hi = {i: ("var(--scan)", "var(--amber)") for i in range(1, pos)}
    for i in range(pos, pos + 3):
        hi[i] = ("var(--panel)", "var(--phosphor)")
    s.mono(x0, 20, "D2", size=11, fill="var(--paper-dim)")
    _chars(s, x0, 46, item, cw, hi)
    s.rect(x0 + (pos - 1) * cw, 46, 3 * cw, 24, fill="none", stroke="var(--phosphor)", sw=2)
    s.mono(x0, 96, _f(t, '=FIND(" - ", D2)'), size=11)
    s.mono(x0 + 300, 96, f"→ {pos}", size=11, fill="var(--phosphor)")
    s.mono(x0, 116, _f(t, '=LEFT(D2, FIND(" - ", D2)-1)'), size=11)
    s.mono(x0 + 300, 116, f"→ {item[:pos - 1]}", size=11, fill="var(--amber)")
    s.mono(x0, 136, _f(t, '=MID(D2, FIND(" - ", D2)+3, 100)'), size=11)
    s.mono(x0 + 300, 136, f"→ {item[pos + 2:]}", size=11)
    s.sans(x0 + 450, 96, t("the separator starts at 6", "o separador começa em 6"), size=10.5, fill="var(--phosphor)")
    s.sans(x0 + 450, 116, t("the code is the 5 before it", "o código são os 5 antes dele"), size=10.5,
           fill="var(--amber)")
    s.sans(x0 + 450, 136, t("the name starts 3 after it", "o nome começa 3 depois dele"), size=10.5,
           fill="var(--paper-dim)")
    d = "20241202"
    y2 = 206
    s.mono(x0, y2 - 26, "B2", size=11, fill="var(--paper-dim)")
    hi2 = {1: ("var(--scan)", "var(--amber)"), 2: ("var(--scan)", "var(--amber)"),
           3: ("var(--scan)", "var(--amber)"), 4: ("var(--scan)", "var(--amber)"),
           5: ("var(--panel)", "var(--phosphor)"), 6: ("var(--panel)", "var(--phosphor)"),
           7: ("var(--scan)", "var(--paper)"), 8: ("var(--scan)", "var(--paper)")}
    _chars(s, x0, y2, d, cw, hi2)
    s.mono(x0 + 9 * cw, y2 + 12.5, _f(t, "=DATE(LEFT(B2,4), MID(B2,5,2), RIGHT(B2,2))"), size=11)
    s.mono(x0 + 9 * cw, y2 + 40, "→ 45628", size=11, fill="var(--amber)")
    s.sans(x0 + 9 * cw + 76, y2 + 40, t("2 December 2024, a real date", "2 de dezembro de 2024, uma data de verdade"),
           size=10.5, fill="var(--paper-dim)")
    s.sans(x0, y2 + 74, t("year: LEFT, 4", "ano: ESQUERDA, 4"), size=10.5, fill="var(--amber)")
    s.sans(x0 + 150, y2 + 74, t("month: MID from 5, 2", "mês: EXT.TEXTO a partir de 5, 2"), size=10.5,
           fill="var(--phosphor)")
    s.sans(x0 + 380, y2 + 74, t("day: RIGHT, 2", "dia: DIREITA, 2"), size=10.5)
    cap = t("Cutting by position. FIND measures where the separator is, so one formula serves codes of five "
            "and six characters; a date written as eight digits has fixed positions and needs no FIND.",
            "Cortando por posição. PROCURAR mede onde está o separador, então uma fórmula serve para códigos "
            "de cinco e de seis caracteres; uma data escrita em oito dígitos tem posições fixas e dispensa "
            "o PROCURAR.")
    return s, cap


def dates(t):
    texts = ["03/12/2024", "05/12/2024", "10/12/2024", "16/12/2024", "23/12/2024"]
    s = Svg(760, 250, "l06-dates", t(
        "Five dates written day first, as text, read by two Excels. Day first, every one becomes the "
        "right December date. Month first, 03, 05 and 10 become dates in March, May and October, "
        "and 16 and 23 stay text, because there is no sixteenth or twenty-third month.",
        "Cinco datas escritas com o dia primeiro, como texto, lidas por dois Excels. Com o dia primeiro, "
        "todas viram a data certa de dezembro. Com o mês primeiro, 03, 05 e 10 viram datas de março, "
        "maio e outubro, e 16 e 23 continuam texto, porque não existe mês dezesseis nem vinte e "
        "três."))
    x0, y0, rh = 40, 58, 30
    s.sans(x0, 22, t("pasted", "colado"), size=11.5, weight="600")
    s.sans(x0 + 190, 22, t("an Excel that reads day first", "um Excel que lê o dia primeiro"), size=11.5,
           weight="600")
    s.sans(x0 + 450, 22, t("an Excel that reads month first", "um Excel que lê o mês primeiro"), size=11.5,
           weight="600")
    for i, tx in enumerate(texts):
        y = y0 + i * rh
        d, m, yy = int(tx[:2]), int(tx[3:5]), int(tx[6:])
        s.rect(x0, y, 120, 24, fill="var(--panel)")
        s.mono(x0 + 6, y + 12.5, tx, size=11)
        s.arrow(x0 + 128, y + 12, x0 + 182, y + 12, stroke="var(--wire)", sw=1.2)
        s.rect(x0 + 190, y, 120, 24, fill="var(--panel)")
        s.mono(x0 + 304, y + 12.5, datetime.date(yy, m, d).isoformat(), size=11, anchor="end")
        s.rect(x0 + 450, y, 120, 24, fill="var(--panel)", stroke="var(--amber)" if d <= 12 else "var(--wire)")
        if d <= 12:
            s.mono(x0 + 564, y + 12.5, datetime.date(yy, d, m).isoformat(), size=11, anchor="end",
                   fill="var(--amber)")
            s.sans(x0 + 580, y + 12.5, t("wrong date", "data errada"), size=10.5, fill="var(--amber)")
        else:
            s.mono(x0 + 456, y + 12.5, tx, size=11, fill="var(--paper-dim)")
            s.sans(x0 + 580, y + 12.5, t("still text", "continua texto"), size=10.5, fill="var(--paper-dim)")
    s.sans(x0 + 190, y0 + 5 * rh + 14, t("every value a date, on the right", "todo valor uma data, à direita"),
           size=10.5, fill="var(--phosphor)")
    s.sans(x0 + 450, y0 + 5 * rh + 14, t("two kinds of value in one column", "dois tipos de valor numa coluna"),
           size=10.5, fill="var(--amber)")
    cap = t("The same five texts pasted into two Excels. Where the day is 12 or less, a month-first Excel makes "
            "a valid date in the wrong month; above 12 it gives up and leaves text. Nothing in the cells "
            "says which rows went wrong.",
            "Os mesmos cinco textos colados em dois Excels. Onde o dia é 12 ou menos, um Excel que lê o mês "
            "primeiro cria uma data válida no mês errado; acima de 12 ele desiste e deixa texto. Nada nas "
            "células diz quais linhas deram errado.")
    return s, cap


FIGS = {"l06-split": split, "l06-dates": dates}
