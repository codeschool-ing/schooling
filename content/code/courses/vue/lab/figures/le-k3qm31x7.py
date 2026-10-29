from fig import Canvas


def what_reruns(T):
    c = Canvas(720, 250, T(
        "What runs again when a session is ticked, in the four cards. In Vue, Angular and Svelte, the state "
        "is connected to the two totals that read it, and the totals to the text that shows them; the tick "
        "reruns those two totals and that text, and the setup, the constructor or the script does not run "
        "again. In React, the tick calls the whole component function again, which recomputes both totals "
        "and returns the whole card, and React compares it with the card it returned before.",
        "O que roda de novo quando uma sessão é marcada, nos quatro cards. Em Vue, Angular e Svelte, o estado "
        "está ligado aos dois totais que o leem, e os totais ao texto que os mostra; a marcação roda de novo "
        "esses dois totais e esse texto, e o setup, o construtor ou o script não rodam de novo. Em React, a "
        "marcação chama de novo a função inteira do componente, que recalcula os dois totais e devolve o "
        "card inteiro, e o React o compara com o card que devolveu antes."))
    c.text(180, 20, T("Vue, Angular, Svelte: tracked", "Vue, Angular, Svelte: rastreado"), size=11, fill="var(--phosphor)")
    c.rect(30, 40, 120, 34, fill="var(--ink)", stroke="var(--phosphor)")
    c.text(90, 57, "sessions", mono=True, size=10)
    for i, name in enumerate(["planned", "done"]):
        y = 100 + i * 50
        c.rect(200, y, 110, 32, fill="var(--ink)", stroke="var(--amber)")
        c.text(255, y + 16, name, mono=True, size=10, fill="var(--amber)")
        c.line(150, 60, 198, y + 16, stroke="var(--wire)", arrow=True)
    c.rect(30, 190, 120, 34, fill="var(--panel)", stroke="var(--wire)", dash="4 3")
    c.text(90, 207, T("setup: once", "setup: uma vez"), size=10)
    c.rect(200, 200, 110, 32, fill="var(--ink)", stroke="var(--amber)")
    c.text(255, 216, T("the total's text", "o texto do total"), size=10, fill="var(--amber)")
    c.line(312, 116, 330, 116, stroke="var(--wire)")
    c.line(312, 166, 330, 166, stroke="var(--wire)")
    c.line(330, 116, 330, 216, stroke="var(--wire)")
    c.line(330, 216, 312, 216, stroke="var(--wire)", arrow=True)
    c.line(360, 15, 360, 240, stroke="var(--scan)", dash="4 4")
    c.text(540, 20, T("React: the function runs again", "React: a função roda de novo"), size=11, fill="var(--amber)")
    c.rect(400, 40, 280, 150, fill="var(--panel)", stroke="var(--amber)")
    c.text(540, 58, "WeekCard()", mono=True, size=11, weight="600", fill="var(--amber)")
    for i, line in enumerate(["useState(start)", "planned = ...", "done = ...", "return <section>...</section>"]):
        c.text(540, 88 + i * 24, line, mono=True, size=10)
    c.rect(400, 200, 280, 32, fill="var(--ink)", stroke="var(--wire)")
    c.text(540, 216, T("compared with the last card", "comparado com o último card"), size=10)
    c.line(540, 192, 540, 198, stroke="var(--wire)")
    c.caption = T("Three of the four rerun what read the state; React reruns the component.",
                  "Três dos quatro rodam de novo o que leu o estado; o React roda de novo o componente.")
    return c


FIGURES = [("reactivity-compared", what_reruns)]
