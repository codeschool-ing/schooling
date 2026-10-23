from fig import Canvas


def classes(T):
    c = Canvas(720, 200, T(
        "A timeline of an element entering with a transition named fade, lasting 600 milliseconds. fade-enter-active "
        "is on for the whole duration. fade-enter-from is on only for the first frame. fade-enter-to is on from the "
        "second frame to the end. When the browser reports transitionend, all three are removed and after-enter runs.",
        "Uma linha do tempo de um elemento entrando com uma transição chamada fade, de 600 milissegundos. "
        "fade-enter-active fica ligada o tempo todo. fade-enter-from fica só no primeiro quadro. fade-enter-to fica "
        "do segundo quadro até o fim. Quando o navegador avisa transitionend, as três saem e o after-enter roda."))
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


FIGURES = [("transition", classes)]
