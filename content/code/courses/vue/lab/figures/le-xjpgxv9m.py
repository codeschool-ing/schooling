from fig import Canvas


def classes(T):
    c = Canvas(720, 200, T(
        "A timeline of an element entering with a transition named fade, lasting 600 milliseconds. fade-enter-active "
        "is on for the whole duration. fade-enter-from is on only for the first frame. fade-enter-to is on from the "
        "second frame to the end. When the browser reports transitionend, fade-enter-active and fade-enter-to are removed and after-enter runs.",
        "Uma linha do tempo de um elemento entrando com uma transição chamada fade, de 600 milissegundos. "
        "fade-enter-active fica ligada o tempo todo. fade-enter-from fica só no primeiro quadro. fade-enter-to fica "
        "do segundo quadro até o fim. Quando o navegador avisa transitionend, fade-enter-active e fade-enter-to saem e o after-enter roda."))
    x0, x1 = 170, 650
    rows = [("fade-enter-from", x0, x0 + 24, "var(--amber)"), ("fade-enter-active", x0, x1, "var(--phosphor)"),
            ("fade-enter-to", x0 + 24, x1, "var(--phosphor-dim)")]
    for i, (name, a, b, col) in enumerate(rows):
        y = 40 + i * 38
        c.text(20, y, name, mono=True, size=10.5, anchor="start")
        c.rect(a, y - 11, b - a, 22, fill="var(--ink)", stroke=col)
    c.line(x0, 160, x1 + 40, 160, stroke="var(--paper-dim)", arrow=True)
    c.text(x0, 176, "0 ms", mono=True, size=9.5, fill="var(--paper-dim)")
    c.text(x1, 176, "600 ms", mono=True, size=9.5, fill="var(--paper-dim)")
    c.line(x1, 24, x1, 152, stroke="var(--amber)", dash="3 3")
    c.text(x1 - 6, 140, T("transitionend: after-enter", "transitionend: after-enter"), anchor="end", size=10, fill="var(--amber)")
    c.text(x0 + 30, 140, T("one frame", "um quadro"), anchor="start", size=10, fill="var(--paper-dim)")
    c.caption = T("Vue switches classes on and off; the stylesheet decides what each of them looks like and how long it lasts.",
                  "O Vue liga e desliga classes; a folha de estilo decide como cada uma fica e quanto tempo dura.")
    return c


def two_trees(T):
    c = Canvas(720, 262, T(
        "Two trees of the TeleportDemo. On the left, where the markup is written, the card's template: the div with "
        "class card holds a paragraph, the button, the note with id stays, and a Teleport to body holding the note "
        "with id moves. On the right, where it is drawn, the document: body holds the div with id app, which holds "
        "the card, which holds the note stays and two comments, teleport start and teleport end, where the Teleport "
        "was written; after the script, the last element of body is the note moves, outside app altogether. A "
        "dashed arrow joins the Teleport on the left to that note on the right.",
        "Duas árvores da TeleportDemo. À esquerda, onde a marcação está escrita, o template do card: a div com "
        "classe card tem um parágrafo, o botão, a nota com id stays, e um Teleport para o body com a nota de id "
        "moves. À direita, onde é desenhado, o documento: o body tem a div com id app, que tem o card, que tem a nota "
        "stays e dois comentários, teleport start e teleport end, onde o Teleport foi escrito; depois do script, o "
        "último elemento do body é a nota moves, fora do app. Uma seta tracejada liga o Teleport, à esquerda, a "
        "essa nota, à direita."))
    c.text(150, 18, T("where it is written: the template", "onde está escrito: o template"), size=10.5,
           fill="var(--paper-dim)")
    c.text(530, 18, T("where it is drawn: the document", "onde é desenhado: o documento"), size=10.5,
           fill="var(--paper-dim)")
    left = [(0, "div.card"), (1, "p"), (1, "button"), (1, "p#stays"), (1, '<Teleport to="body">'), (2, "p#moves")]
    for i, (d, s) in enumerate(left):
        x, y = 40 + d * 24, 36 + i * 34
        hot = s == "p#moves"
        c.rect(x, y, 190, 26, fill="var(--ink)" if hot else "var(--panel)",
               stroke="var(--amber)" if hot or "Teleport" in s else "var(--wire)")
        c.text(x + 95, y + 13, s, mono=True, size=10, fill="var(--amber)" if hot else "var(--paper)")
    right = [(0, "body"), (1, "div#app"), (2, "div.card"), (3, "p#stays"), (3, "<!--teleport start-->"),
             (3, "<!--teleport end-->"), (1, "script"), (1, "p#moves")]
    for i, (d, s) in enumerate(right):
        x, y = 400 + d * 22, 34 + i * 28
        hot = s == "p#moves"
        c.rect(x, y, 170, 22, fill="var(--ink)" if hot else "var(--panel)",
               stroke="var(--amber)" if hot else "var(--wire)", dash="3 3" if "teleport" in s else None)
        c.text(x + 85, y + 11, s, mono=True, size=9.5,
               fill="var(--amber)" if hot else ("var(--paper-dim)" if "teleport" in s else "var(--paper)"))
    c.path("M 282 219 C 340 219, 360 241, 418 241", stroke="var(--amber)", dash="4 3")
    c.line(410, 241, 420, 241, stroke="var(--amber)", arrow=True)
    c.caption = T("The Teleport's contents stay in the card's component and are drawn at the end of body.",
                  "O conteúdo do Teleport continua no componente do card e é desenhado no fim do body.")
    return c


FIGURES = [("transition", classes), ("teleport", two_trees)]
