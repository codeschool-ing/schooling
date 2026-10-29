from fig import Canvas


def negotiate(T):
    c = Canvas(720, 290, T(
        "Four requests arrive at the same address, /courses/guitar. A GET whose Accept header starts with text/html "
        "goes to the page, +page.svelte, which renders HTML. A POST that prefers HTML, a form sent by the browser, or "
        "a POST that use:enhance marks as being for an action, goes to the actions in +page.server.js. A GET that "
        "asks for application/json, or for anything at all, goes to the GET in +server.js, which answers JSON.",
        "Quatro requisições chegam ao mesmo endereço, /courses/guitar. Um GET cujo cabeçalho Accept começa com "
        "text/html vai para a página, +page.svelte, que renderiza HTML. Um POST que prefere HTML, um formulário "
        "enviado pelo navegador, ou um POST que o use:enhance marca como sendo para uma action, vai para as actions "
        "em +page.server.js. Um GET que pede application/json, ou qualquer coisa, vai para o GET em +server.js, que "
        "responde JSON."))
    c.text(360, 20, "/courses/guitar", mono=True, size=11, weight="600", fill="var(--amber)")
    reqs = [
        ("GET  Accept: text/html", "+page.svelte", T("the page, as HTML", "a página, em HTML"), "var(--phosphor)"),
        ("POST  ?week=…&/add", "+page.server.js", T("an action", "uma action"), "var(--phosphor)"),
        ("GET  Accept: application/json", "+server.js", T("the course, as JSON", "o curso, em JSON"), "var(--amber)"),
        ("GET  Accept: */*", "+server.js", T("the course, as JSON", "o curso, em JSON"), "var(--amber)"),
    ]
    for k, (req, file, what, col) in enumerate(reqs):
        y = 44 + k * 56
        c.rect(20, y, 260, 40, fill="var(--panel)", stroke="var(--wire)")
        c.text(34, y + 20, req, mono=True, size=9.5, anchor="start")
        c.line(280, y + 20, 418, y + 20, stroke=col, arrow=True)
        c.rect(420, y, 280, 40, fill="var(--ink)", stroke=col)
        c.text(434, y + 20, file, mono=True, size=9.5, anchor="start", fill=col)
        c.text(686, y + 20, what, size=9.5, anchor="end")
    c.text(360, 276, T("the Accept header, and the method, decide which file answers",
                       "o cabeçalho Accept, e o método, decidem qual arquivo responde"), size=10, fill="var(--paper-dim)")
    c.caption = T("One address, two kinds of answer: SvelteKit picks the file from what the request says it wants.",
                  "Um endereço, dois tipos de resposta: o SvelteKit escolhe o arquivo pelo que a requisição diz querer.")
    return c


FIGURES = [("negotiation", negotiate)]
