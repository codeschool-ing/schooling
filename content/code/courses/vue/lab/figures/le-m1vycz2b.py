from fig import Canvas


def graph(T):
    c = Canvas(720, 230, T(
        "The planner's dependency graph. Three refs on the left: courses, sessions and monday. Two computed values in the "
        "middle: total reads sessions and monday, and perCourse reads all three refs. The template on the right "
        "reads total, perCourse and monday. A click on Previous week writes monday; the arrows from monday mark "
        "total, perCourse and the template stale, and the redraw recomputes each once.",
        "O grafo de dependências do planner. Três refs à esquerda: courses, sessions e monday. Dois valores computed no "
        "meio: total lê sessions e monday, e perCourse lê os três refs. O template, à direita, lê total, "
        "perCourse e monday. Um clique em Previous week escreve em monday; as setas que saem de monday marcam "
        "total, perCourse e o template como desatualizados, e a renderização recalcula cada um uma vez."))
    col = [(30, T("owned: ref", "próprio: ref")), (300, T("derived: computed", "derivado: computed")), (560, T("drawn", "desenhado"))]
    for x, t in col:
        c.text(x + 65, 20, t, size=10.5, fill="var(--paper-dim)")
    refs = [("courses", 60), ("sessions", 115), ("monday", 170)]
    for name, y in refs:
        hot = name == "monday"
        c.rect(30, y - 18, 130, 36, fill="var(--ink)", stroke="var(--amber)" if hot else "var(--wire)")
        c.text(95, y, name, mono=True, size=11, fill="var(--amber)" if hot else "var(--paper)")
    comps = [("total", 85), ("perCourse", 150)]
    for name, y in comps:
        c.rect(300, y - 18, 130, 36, fill="var(--ink)", stroke="var(--phosphor)")
        c.text(365, y, name, mono=True, size=11, fill="var(--phosphor)")
    c.rect(560, 60, 130, 120, fill="var(--panel)", stroke="var(--wire)")
    c.text(625, 120, "<template>", mono=True, size=11)
    edges = [(115, 85), (170, 85), (60, 150), (115, 150), (170, 150)]
    for y1, y2 in edges:
        hot = y1 == 170
        c.line(162, y1, 298, y2, stroke="var(--amber)" if hot else "var(--wire)", arrow=True)
    for _, y in comps:
        c.line(432, y, 558, y if y < 150 else 140, stroke="var(--phosphor-dim)", arrow=True)
    c.path("M162,180 C300,215 500,215 600,182", stroke="var(--amber)")
    c.line(598, 186, 602, 181, stroke="var(--amber)", arrow=True)
    c.text(365, 220, T("the template reads monday too", "o template também lê monday"), size=10, fill="var(--amber)")
    c.caption = T("Nobody wrote these arrows. Each one was recorded when a computed or the template read a value.",
                  "Ninguém escreveu estas setas. Cada uma foi registrada quando um computed ou o template leu um valor.")
    return c


def lazy(T):
    c = Canvas(720, 215, T(
        "Four moments of the LazyComputed demo, in columns. When the page opens, minutes is 90, showHours is false, "
        "and hours is not computed. After the first click on change, minutes is 150, after two changes of 30, and "
        "hours is still not computed, because nobody reads it. After the click on show, showHours is true and hours "
        "is computed once, from 150. After the second click on change, minutes is 210 and hours is computed once, "
        "from 210, though there were two writes.",
        "Quatro momentos da demo LazyComputed, em colunas. Quando a página abre, minutes é 90, showHours é false, e "
        "hours não é calculado. Depois do primeiro clique em change, minutes é 150, depois de duas mudanças de 30, e "
        "hours continua sem ser calculado, porque ninguém o lê. Depois do clique em show, showHours é true e hours é "
        "calculado uma vez, a partir de 150. Depois do segundo clique em change, minutes é 210 e hours é calculado "
        "uma vez, a partir de 210, embora tenham sido duas escritas."))
    heads = [T("page opens", "a página abre"), "click #change", "click #show", "click #change"]
    for i, h in enumerate(heads):
        x = 150 + i * 140
        c.text(x + 65, 24, h, size=10.5, mono=i > 0, fill="var(--amber)")
    rows = [("minutes", ["90", "150", "150", "210"]), ("showHours", ["false", "false", "true", "true"])]
    for r, (name, vals) in enumerate(rows):
        y = 44 + r * 50
        c.text(20, y + 16, name, mono=True, size=10.5, anchor="start")
        for i, v in enumerate(vals):
            c.rect(150 + i * 140, y, 130, 32, fill="var(--panel)", stroke="var(--wire)")
            c.text(215 + i * 140, y + 16, v, mono=True, size=10.5)
    y = 144
    c.text(20, y + 16, T("hours ran", "hours rodou"), size=10.5, anchor="start", fill="var(--phosphor)")
    cells = [(T("not run", "não roda"), False), (T("not run", "não roda"), False),
             (T("once, from 150", "uma vez, de 150"), True), (T("once, from 210", "uma vez, de 210"), True)]
    for i, (s, hot) in enumerate(cells):
        c.rect(150 + i * 140, y, 130, 32, fill="var(--phosphor-dim)" if hot else "var(--ink)",
               stroke="var(--phosphor)" if hot else "var(--wire)", dash=None if hot else "4 3")
        c.text(215 + i * 140, y + 16, s, size=10.5, fill="var(--paper)" if hot else "var(--paper-dim)")
    c.text(355, 198, T("two writes, nobody reading", "duas escritas, ninguém lendo"), size=9.5, fill="var(--paper-dim)")
    c.text(635, 198, T("two writes, read once", "duas escritas, lido uma vez"), size=9.5, fill="var(--paper-dim)")
    c.caption = T("A computed runs when it is read, and once however many writes came before.",
                  "Um computed roda quando é lido, e uma vez só, por mais escritas que tenham vindo antes.")
    return c


FIGURES = [("week-total", graph), ("caching", lazy)]
