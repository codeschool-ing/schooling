from fig import Canvas


def split(T):
    c = Canvas(720, 250, T(
        "Who owns what in the session list. List.svelte owns the structure: the ul, one li per item with its key, and "
        "the choice between the list and the empty state. The page owns the content: the row snippet, with the bound "
        "checkbox and the date, and the empty snippet with its sentence. The page hands both snippets to List, and List "
        "calls row once per session and empty when there are none.",
        "Quem é dono do quê na lista de sessões. O List.svelte é dono da estrutura: o ul, um li por item com a sua "
        "chave, e a escolha entre a lista e o estado vazio. A página é dona do conteúdo: o snippet row, com o checkbox "
        "ligado e a data, e o snippet empty com a sua frase. A página entrega os dois snippets ao List, e o List chama "
        "row uma vez por sessão e empty quando não há nenhuma."))
    c.rect(20, 20, 300, 200, fill="var(--panel)", stroke="var(--amber)")
    c.text(170, 40, T("+page.svelte: the content", "+page.svelte: o conteúdo"), size=11, weight="600", fill="var(--amber)")
    c.rect(40, 60, 260, 80, fill="var(--ink)", stroke="var(--wire)")
    c.text(52, 78, "{#snippet row(session)}", mono=True, size=10, anchor="start")
    c.text(64, 100, "<input bind:checked …>", mono=True, size=9.5, anchor="start", fill="var(--paper-dim)")
    c.text(64, 120, "{format(session.date)} …", mono=True, size=9.5, anchor="start", fill="var(--paper-dim)")
    c.rect(40, 152, 260, 50, fill="var(--ink)", stroke="var(--wire)")
    c.text(52, 170, "{#snippet empty()}", mono=True, size=10, anchor="start")
    c.text(64, 190, "<p>Nothing planned …</p>", mono=True, size=9.5, anchor="start", fill="var(--paper-dim)")
    c.rect(420, 20, 280, 200, fill="var(--panel)", stroke="var(--phosphor)")
    c.text(560, 40, T("List.svelte: the structure", "List.svelte: a estrutura"), size=11, weight="600", fill="var(--phosphor)")
    c.text(440, 70, "{#if items.length}", mono=True, size=10, anchor="start")
    c.text(456, 92, "<ul>", mono=True, size=10, anchor="start")
    c.text(472, 114, "{#each items as item (item.id)}", mono=True, size=9.5, anchor="start")
    c.text(488, 136, "<li>{@render row(item)}</li>", mono=True, size=9.5, anchor="start", fill="var(--amber)")
    c.text(440, 162, "{:else}", mono=True, size=10, anchor="start")
    c.text(456, 184, "{@render empty?.()}", mono=True, size=9.5, anchor="start", fill="var(--amber)")
    c.line(300, 100, 418, 132, stroke="var(--amber)", arrow=True)
    c.line(300, 177, 418, 182, stroke="var(--amber)", arrow=True)
    c.text(360, 238, T("snippets travel as props; the markup in them stays the page's",
                       "snippets viajam como props; a marcação neles continua sendo da página"), size=10, fill="var(--paper-dim)")
    c.caption = T("List decides the shape and when to show each part. The page decides what a row and the empty state say.",
                  "O List decide a forma e quando mostrar cada parte. A página decide o que uma linha e o estado vazio dizem.")
    return c


FIGURES = [("passing-snippets", split)]
