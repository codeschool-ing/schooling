from fig import Canvas


def delegation(T):
    c = Canvas(720, 250, T(
        "A click on one of three buttons, with delegation. The buttons have no listeners of their own; their handlers are "
        "stored on the elements. The click bubbles up from the button through its list item and the list to the root of "
        "the application, where one listener for click finds the handler stored on the button and calls it. A listener "
        "added by hand on the list that stops propagation would stop the click before it reached the root.",
        "Um clique num de três botões, com delegação. Os botões não têm listeners próprios; os handlers ficam guardados "
        "nos elementos. O clique sobe do botão pelo item da lista e pela lista até a raiz da aplicação, onde um listener de "
        "click acha o handler guardado no botão e o chama. Um listener acrescentado à mão na lista que pare a propagação "
        "pararia o clique antes de ele chegar à raiz."))
    c.rect(20, 20, 680, 50, fill="var(--ink)", stroke="var(--phosphor)")
    c.text(360, 45, T("the root of the application: one listener for click", "a raiz da aplicação: um listener de click"),
           size=11, fill="var(--phosphor)")
    c.rect(60, 100, 600, 120, fill="var(--panel)", stroke="var(--wire)")
    c.text(80, 118, "<ul>", mono=True, size=10, anchor="start", fill="var(--paper-dim)")
    for i, name in enumerate(["Linear algebra", "Spanish", "Guitar"]):
        x = 90 + i * 190
        c.rect(x, 140, 160, 60, fill="var(--ink)", stroke="var(--amber)" if i == 1 else "var(--wire)")
        c.text(x + 80, 160, "<button>", mono=True, size=9.5, fill="var(--paper-dim)")
        c.text(x + 80, 182, name, size=10.5, fill="var(--amber)" if i == 1 else "var(--paper)")
    c.path("M370 140 C 370 110, 390 100, 390 74", stroke="var(--amber)", dash="4 3")
    c.line(390, 80, 390, 72, stroke="var(--amber)", arrow=True)
    c.text(400, 90, T("the click bubbles up", "o clique sobe"), size=10, anchor="start", fill="var(--amber)")
    c.text(360, 238, T("the handler is looked up on the button that was clicked, and called",
                       "o handler é procurado no botão clicado, e chamado"), size=10, fill="var(--paper-dim)")
    c.caption = T("Delegation: one listener at the root instead of one per button. The click has to reach it.",
                  "Delegação: um listener na raiz em vez de um por botão. O clique tem de chegar até ele.")
    return c


FIGURES = [("event-attributes", delegation)]
