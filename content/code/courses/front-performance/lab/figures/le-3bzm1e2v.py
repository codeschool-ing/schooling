from fig import Canvas

# Numbers read off this lesson's captures, and checked against them by hand.
PAINT, CLICK, TAKEN = 40, 300, 2036       # the-dead-window: hydrate.ts --script-delay 2000 --click-at 300
FIRST, SECOND = 52, 1049                  # streaming-html: chunks.ts on stream.ts


def stages(T):
    c = Canvas(720, 230, T(
        "Three stages of the same course page. First, the HTML from the server: the heading, two sessions and their "
        "Mark done buttons, drawn and not yet working. Second, the script arrives with the data the server put in the "
        "page. Third, hydrated: the same elements, now with a listener on the container that handles every click.",
        "Três estágios da mesma página de curso. Primeiro, o HTML do servidor: o título, duas sessões e os seus botões "
        "Mark done, desenhados e ainda sem funcionar. Segundo, o script chega com os dados que o servidor pôs na página. "
        "Terceiro, hidratada: os mesmos elementos, agora com um listener no contêiner que trata todo clique."))
    cols = [(20, T("server HTML", "HTML do servidor"), "var(--wire)", T("drawn, not working", "desenhada, sem funcionar")),
            (260, T("script + data arrive", "script + dados chegam"), "var(--amber)", T("the plan from the page", "o plano da página")),
            (500, T("hydrated", "hidratada"), "var(--phosphor)", T("same elements, listening", "mesmos elementos, ouvindo"))]
    for x, title, colour, note in cols:
        c.text(x + 100, 22, title, size=11, weight="600", fill=colour if colour != "var(--wire)" else "var(--paper)")
        c.rect(x, 36, 200, 150, fill="var(--panel)", stroke=colour, sw=1.6)
        c.text(x + 14, 58, "Git", anchor="start", size=12, weight="600")
        for i, d in enumerate(("Sat 2026-10-24", "Tue 2026-10-27")):
            y = 88 + i * 36
            c.text(x + 14, y, d, anchor="start", size=10, mono=True)
            c.rect(x + 124, y - 11, 66, 22, fill="var(--ink)", stroke=colour, dash=None if colour == "var(--phosphor)" else "3 3")
            c.text(x + 157, y, "Mark done", size=8.5, mono=True)
        c.text(x + 100, 172, note, size=9.5, fill="var(--paper-dim)")
    c.line(222, 110, 256, 110, stroke="var(--paper-dim)", arrow=True)
    c.line(462, 110, 496, 110, stroke="var(--paper-dim)", arrow=True)
    c.text(360, 212, T("Nothing on the screen changes between the first and the third; only what a click does.",
                       "Nada na tela muda entre o primeiro e o terceiro; só o que um clique faz."), size=10, fill="var(--paper-dim)")
    c.caption = T("Hydration adds behaviour to elements that are already there.",
                  "A hidratação acrescenta comportamento a elementos que já estão lá.")
    return c


def window(T):
    c = Canvas(720, 200, T(
        f"A timeline in milliseconds. The page painted at {PAINT}, the click on Mark done happened at {CLICK}, and the "
        f"script took the page over at {TAKEN}. The click fell inside the window between paint and takeover, and was lost.",
        f"Uma linha do tempo em milissegundos. A página pintou aos {PAINT}, o clique em Mark done aconteceu aos {CLICK}, e "
        f"o script assumiu a página aos {TAKEN}. O clique caiu dentro da janela entre a pintura e a tomada, e se perdeu."))
    x0, scale = 40, 620 / 2200
    X = lambda ms: x0 + ms * scale
    c.line(x0, 120, x0 + 640, 120, stroke="var(--paper-dim)", arrow=True)
    c.text(x0 + 640, 138, "ms", anchor="end", size=9.5, mono=True, fill="var(--paper-dim)")
    c.rect(X(PAINT), 92, X(TAKEN) - X(PAINT), 24, fill="var(--ink)", stroke="var(--amber)", dash="4 3")
    c.text((X(PAINT) + X(TAKEN)) / 2 + 60, 104, T("visible, not working", "visível, sem funcionar"), size=10, fill="var(--amber)")
    for ms, label, colour, y in ((PAINT, T("painted", "pintou"), "var(--paper)", 60),
                                 (CLICK, T("click: lost", "clique: perdido"), "var(--amber)", 36),
                                 (TAKEN, T("taken over", "assumida"), "var(--phosphor)", 60)):
        c.line(X(ms), y + 8, X(ms), 118, stroke=colour)
        c.text(X(ms), y, f"{label} · {ms}", size=10, fill=colour)
    c.text(x0, 170, T("The script was held back two seconds on purpose, as on a slow connection.",
                      "O script foi segurado dois segundos de propósito, como numa conexão lenta."), anchor="start",
           size=10, fill="var(--paper-dim)")
    c.caption = T("Everything that happens to the page between its paint and its takeover happens to a picture.",
                  "Tudo o que acontece com a página entre a pintura e a tomada acontece com uma foto.")
    return c


def pieces(T):
    c = Canvas(720, 210, T(
        f"The response of stream.ts over time. At {FIRST} milliseconds the first piece arrives: the head, the heading and "
        f"a Loading sessions placeholder, which the browser draws. At {SECOND} milliseconds the second piece arrives: the "
        "sessions in a template and a script that moves them into the list.",
        f"A resposta do stream.ts ao longo do tempo. Aos {FIRST} milissegundos chega o primeiro pedaço: o head, o título "
        f"e um marcador Loading sessions, que o navegador desenha. Aos {SECOND} milissegundos chega o segundo pedaço: as "
        "sessões num template e um script que as move para a lista."))
    x0, scale = 40, 620 / 1200
    X = lambda ms: x0 + ms * scale
    c.line(x0, 150, x0 + 640, 150, stroke="var(--paper-dim)", arrow=True)
    c.text(x0 + 640, 168, "ms", anchor="end", size=9.5, mono=True, fill="var(--paper-dim)")
    c.rect(X(FIRST), 40, 200, 90, fill="var(--panel)", stroke="var(--phosphor)", sw=1.6)
    c.text(X(FIRST) + 100, 58, T(f"piece 1 · {FIRST} ms", f"pedaço 1 · {FIRST} ms"), size=10.5, fill="var(--phosphor)")
    c.text(X(FIRST) + 14, 84, "<h1>Git</h1>", anchor="start", size=10, mono=True)
    c.text(X(FIRST) + 14, 106, "<li>Loading sessions…", anchor="start", size=10, mono=True)
    c.rect(X(SECOND) - 150, 40, 200, 90, fill="var(--panel)", stroke="var(--amber)", sw=1.6)
    c.text(X(SECOND) - 50, 58, T(f"piece 2 · {SECOND} ms", f"pedaço 2 · {SECOND} ms"), size=10.5, fill="var(--amber)")
    c.text(X(SECOND) - 136, 84, "<template>…</template>", anchor="start", size=10, mono=True)
    c.text(X(SECOND) - 136, 106, "<script>…replaceChildren", anchor="start", size=10, mono=True)
    c.line(X(FIRST), 132, X(FIRST), 148, stroke="var(--phosphor)")
    c.line(X(SECOND), 132, X(SECOND), 148, stroke="var(--amber)")
    c.text(x0, 190, T("One response, one connection; the browser draws piece 1 a second before piece 2 exists.",
                      "Uma resposta, uma conexão; o navegador desenha o pedaço 1 um segundo antes de o pedaço 2 existir."),
           anchor="start", size=10, fill="var(--paper-dim)")
    c.caption = T("The quick part is not held hostage by the slow one.",
                  "A parte rápida não fica refém da lenta.")
    return c


FIGURES = [
    ("what-hydration-is", stages),
    ("the-dead-window", window),
    ("streaming-html", pieces),
]
