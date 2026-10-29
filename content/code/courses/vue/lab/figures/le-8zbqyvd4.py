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


def merge(T):
    c = Canvas(720, 230, T(
        "The Mixins demo. On the left, two mixins in the order of the mixins list: progressMixin, with label "
        "progress and its own describe, and courseMixin, with label course and its own describe. On the right, what "
        "the component's this ends up with: label is course and describe returns course: course. The arrow from "
        "progressMixin is dashed: both its label and its describe were overwritten, silently, because the later "
        "mixin in the list wins.",
        "A demo Mixins. À esquerda, dois mixins na ordem da lista mixins: progressMixin, com label progress e o seu "
        "próprio describe, e courseMixin, com label course e o seu próprio describe. À direita, o que o this do "
        "componente acaba tendo: label é course e describe devolve course: course. A seta que sai do progressMixin "
        "é tracejada: tanto o label quanto o describe dele foram sobrescritos, em silêncio, porque o mixin que vem "
        "depois na lista vence."))
    c.text(360, 18, "mixins: [progressMixin, courseMixin]", mono=True, size=11, fill="var(--amber)")
    boxes = [(40, "progressMixin", "label: 'progress'", "describe() → progress: …", False),
             (135, "courseMixin", "label: 'course'", "describe() → course: …", True)]
    for y, name, label, desc, wins in boxes:
        c.rect(30, y, 230, 76, fill="var(--ink)" if wins else "var(--panel)",
               stroke="var(--phosphor)" if wins else "var(--wire)", dash=None if wins else "4 3")
        c.text(145, y + 18, name, mono=True, size=11, fill="var(--phosphor)" if wins else "var(--paper-dim)")
        c.text(145, y + 40, label, mono=True, size=10, fill="var(--paper)" if wins else "var(--paper-dim)")
        c.text(145, y + 60, desc, mono=True, size=10, fill="var(--paper)" if wins else "var(--paper-dim)")
    c.line(262, 78, 446, 112, stroke="var(--wire)", dash="4 3", arrow=True)
    c.text(345, 70, T("overwritten", "sobrescrito"), size=10, fill="var(--paper-dim)")
    c.line(262, 173, 446, 142, stroke="var(--phosphor)", arrow=True)
    c.text(345, 178, T("later in the list: wins", "depois na lista: vence"), size=10, fill="var(--phosphor)")
    c.rect(450, 78, 250, 96, fill="var(--ink)", stroke="var(--phosphor)")
    c.text(575, 98, T("the component's this", "o this do componente"), size=10.5, fill="var(--phosphor)")
    c.text(575, 126, "label = course", mono=True, size=10.5)
    c.text(575, 150, "describe() = course: course", mono=True, size=10)
    c.text(575, 200, T("nothing warned", "nada avisou"), size=10, fill="var(--amber)")
    c.caption = T("Merging mixins keeps one of each name, the later one, and says nothing about the other.",
                  "Juntar mixins guarda um de cada nome, o que vem depois, e não diz nada sobre o outro.")
    return c


FIGURES = [("same-component", grouping), ("mixins", merge)]
