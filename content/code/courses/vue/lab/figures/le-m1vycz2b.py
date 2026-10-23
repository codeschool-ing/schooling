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


FIGURES = [("week-total", graph)]
