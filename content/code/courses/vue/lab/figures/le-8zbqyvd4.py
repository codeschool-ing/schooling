from fig import Canvas


def grouping(T):
    c = Canvas(720, 250, T(
        "The same component in two columns. On the left, the Options API groups code by kind: data, computed, "
        "watch, mounted and beforeUnmount, and the pieces of two concerns, the week and the timer, are "
        "scattered across all five. On the right, the Composition API groups code by concern: everything about "
        "the week sits together, and everything about the timer sits together.",
        "O mesmo componente em duas colunas. À esquerda, a Options API agrupa o código por tipo: data, "
        "computed, watch, mounted e beforeUnmount, e as partes de dois assuntos, a semana e o timer, ficam "
        "espalhadas pelos cinco. À direita, a Composition API agrupa o código por assunto: tudo sobre a semana "
        "fica junto, e tudo sobre o timer fica junto."))
    c.text(180, 18, T("Options API: by kind", "Options API: por tipo"), size=11.5, weight="600")
    c.text(540, 18, T("Composition API: by concern", "Composition API: por assunto"), size=11.5, weight="600")
    kinds = [("data", ["week", "timer"]), ("computed", ["week"]), ("watch", ["week"]), ("mounted", ["timer"]),
             ("beforeUnmount", ["timer"])]
    y = 32
    for k, items in kinds:
        c.rect(30, y, 300, 36, fill="var(--panel)", stroke="var(--wire)")
        c.text(42, y + 18, k, mono=True, size=10.5, anchor="start")
        x = 160
        for it in items:
            col = "var(--phosphor)" if it == "week" else "var(--amber)"
            c.rect(x, y + 7, 70, 22, fill="var(--ink)", stroke=col)
            c.text(x + 35, y + 18, T(it, "semana" if it == "week" else "timer"), size=10, fill=col)
            x += 80
        y += 42
    c.rect(390, 32, 300, 98, fill="var(--ink)", stroke="var(--phosphor)")
    c.text(540, 50, T("the week", "a semana"), size=11, fill="var(--phosphor)", weight="600")
    for i, s in enumerate(["ref", "computed", "watch"]):
        c.text(540, 74 + i * 18, s, mono=True, size=10.5)
    c.rect(390, 140, 300, 80, fill="var(--ink)", stroke="var(--amber)")
    c.text(540, 158, T("the timer", "o timer"), size=11, fill="var(--amber)", weight="600")
    for i, s in enumerate(["ref", "onMounted", "onBeforeUnmount"]):
        c.text(540, 178 + i * 16, s, mono=True, size=10.5)
    c.caption = T("Changing the timer means visiting three options on the left, and one block on the right.",
                  "Mudar o timer exige visitar três opções à esquerda, e um bloco à direita.")
    return c


FIGURES = [("same-component", grouping)]
