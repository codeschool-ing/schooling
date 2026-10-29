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


def fill(T):
    c = Canvas(720, 260, T(
        "The NamedSlots demo. On the left, what the parent writes between the first TitledPanel's tags: a template "
        "named header holding an h2, This week; a paragraph outside any template; and a template named footer "
        "holding 75 of 195 minutes done. On the right, TitledPanel's three slots: the slot named header, the slot "
        "with no name, called default, and the slot named footer. An arrow joins each piece to its slot. Below, the "
        "second panel, which filled nothing: its header drew the fallback, Untitled, and where the footer would be "
        "there is only a v-if comment.",
        "A demo NamedSlots. À esquerda, o que o pai escreve entre as tags do primeiro TitledPanel: um template "
        "chamado header com um h2, This week; um parágrafo fora de qualquer template; e um template chamado footer "
        "com 75 of 195 minutes done. À direita, os três slots do TitledPanel: o slot chamado header, o slot sem nome, "
        "chamado default, e o slot chamado footer. Uma seta liga cada pedaço ao seu slot. Embaixo, o segundo painel, "
        "que não preencheu nada: o header dele desenhou a reserva, Untitled, e onde estaria o footer há só um "
        "comentário v-if."))
    c.text(145, 18, T("the parent writes", "o pai escreve"), size=10.5, fill="var(--paper-dim)")
    c.text(560, 18, "TitledPanel.vue", mono=True, size=10.5, fill="var(--amber)")
    pieces = [("#header", "<h2>This week</h2>", True), (T("outside any template", "fora de qualquer template"),
              "<p>Five sessions planned.</p>", False), ("#footer", "75 of 195 minutes done", True)]
    slots = ['<slot name="header">', "<slot />", '<slot name="footer" />']
    c.rect(420, 30, 280, 160, fill="var(--ink)", stroke="var(--wire)")
    for i, ((top, body, mono), slot) in enumerate(zip(pieces, slots)):
        y = 36 + i * 52
        c.rect(20, y, 250, 42, fill="var(--panel)", stroke="var(--wire)")
        c.text(145, y + 13, top, mono=mono, size=9.5, fill="var(--phosphor)")
        c.text(145, y + 30, body, mono=True, size=9.5)
        c.rect(435, y, 250, 42, fill="var(--panel)", stroke="var(--phosphor)", dash="4 3")
        c.text(560, y + 21, slot, mono=True, size=10, fill="var(--phosphor)")
        c.line(272, y + 21, 431, y + 21, stroke="var(--phosphor)", arrow=True)
    c.text(20, 222, T("second panel, nothing filled:", "segundo painel, nada preenchido:"), size=10, anchor="start",
           fill="var(--paper-dim)")
    c.rect(230, 208, 210, 28, fill="var(--panel)", stroke="var(--wire)")
    c.text(335, 222, "<header>Untitled</header>", mono=True, size=9.5)
    c.rect(460, 208, 130, 28, fill="var(--panel)", stroke="var(--wire)", dash="4 3")
    c.text(525, 222, "<!--v-if-->", mono=True, size=9.5, fill="var(--paper-dim)")
    c.text(600, 222, T("no footer", "sem footer"), size=9.5, anchor="start", fill="var(--paper-dim)")
    c.caption = T("Each template fills the slot it names, the rest goes to default, and an unfilled slot draws its fallback.",
                  "Cada template preenche o slot que nomeia, o resto vai para o default, e um slot não preenchido desenha a sua reserva.")
    return c


FIGURES = [("scoped-slots", scoped), ("named-slots", fill)]
