from fig import Canvas


def scoped(T):
    c = Canvas(720, 250, T(
        "Two boxes. On the left, the child SessionTable owns the list element, the loop and each list item; "
        "inside each item is a slot. On the right, the parent's template for the row slot. An arrow from the "
        "slot to the parent carries the slot props, session and position. An arrow back carries the markup "
        "the parent's template made, which is drawn inside the item.",
        "Duas caixas. À esquerda, o filho SessionTable é dono do elemento da lista, do laço e de cada item; "
        "dentro de cada item há um slot. À direita, o template do pai para o slot row. Uma seta do slot para "
        "o pai leva as props do slot, session e position. Uma seta de volta leva a marcação que o template do "
        "pai produziu, desenhada dentro do item."))
    c.rect(20, 20, 300, 210, fill="var(--panel)", stroke="var(--wire)")
    c.text(170, 40, T("the child: SessionTable", "o filho: SessionTable"), size=11, weight="600")
    c.text(40, 70, "<ol>", mono=True, size=10.5, anchor="start")
    c.text(55, 92, '<li v-for="session in sessions">', mono=True, size=10, anchor="start")
    c.rect(70, 108, 230, 60, fill="var(--ink)", stroke="var(--amber)", dash="4 3")
    c.text(185, 126, '<slot name="row"', mono=True, size=10, fill="var(--amber)")
    c.text(185, 146, ':session :position>', mono=True, size=10, fill="var(--amber)")
    c.text(55, 190, "</li>", mono=True, size=10.5, anchor="start")
    c.text(40, 212, "</ol>", mono=True, size=10.5, anchor="start")
    c.rect(420, 60, 280, 130, fill="var(--panel)", stroke="var(--phosphor)")
    c.text(560, 80, T("the parent's template", "o template do pai"), size=11, weight="600")
    c.text(560, 112, '#row="{ session, position }"', mono=True, size=10, fill="var(--phosphor)")
    c.text(560, 142, "{{ position }}. {{ session.course }}", mono=True, size=10)
    c.line(302, 122, 418, 112, stroke="var(--amber)", arrow=True)
    c.text(360, 104, T("slot props", "props do slot"), size=10, fill="var(--amber)")
    c.line(418, 160, 302, 156, stroke="var(--phosphor)", arrow=True)
    c.text(360, 176, T("markup", "marcação"), size=10, fill="var(--phosphor)")
    c.caption = T("The child keeps the structure and lends the item; the parent draws the item and returns it.",
                  "O filho fica com a estrutura e empresta o item; o pai desenha o item e o devolve.")
    return c


FIGURES = [("scoped-slots", scoped)]
