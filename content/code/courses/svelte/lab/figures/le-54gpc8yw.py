from fig import Canvas


def modes(T):
    c = Canvas(720, 300, T(
        "Four columns, one per way of rendering, each showing what happens on the server, what the first response "
        "carries, and what runs in the browser. Default: the server renders on each request, the response is the "
        "full page, and the browser hydrates it and handles clicks. csr false: the server renders on each request, "
        "the response is the full page, and nothing runs in the browser. ssr false: the server sends an empty page "
        "with a script, and the browser renders everything. prerender: the page was rendered once at build time, "
        "the server sends that file, and the browser does what csr says.",
        "Quatro colunas, uma por jeito de renderizar, cada uma mostrando o que acontece no servidor, o que a primeira "
        "resposta leva e o que roda no navegador. Padrão: o servidor renderiza a cada requisição, a resposta é a "
        "página inteira, e o navegador a hidrata e cuida dos cliques. csr false: o servidor renderiza a cada "
        "requisição, a resposta é a página inteira, e nada roda no navegador. ssr false: o servidor manda uma página "
        "vazia com um script, e o navegador renderiza tudo. prerender: a página foi renderizada uma vez no build, o "
        "servidor manda esse arquivo, e o navegador faz o que o csr disser."))
    rows = [T("on the server", "no servidor"), T("first response", "primeira resposta"), T("in the browser", "no navegador")]
    for k, r in enumerate(rows):
        c.text(16, 78 + k * 70, r, size=10, weight="600", anchor="start", fill="var(--paper-dim)")
    cols = [
        (T("default", "padrão"), False, [T("renders, per request", "renderiza, por requisição"), T("the whole page", "a página inteira"), T("hydrates, handles clicks", "hidrata, cuida dos cliques")]),
        ("csr = false", True, [T("renders, per request", "renderiza, por requisição"), T("the whole page", "a página inteira"), T("nothing runs", "nada roda")]),
        ("ssr = false", True, [T("sends a script", "manda um script"), T("an empty page", "uma página vazia"), T("renders everything", "renderiza tudo")]),
        ("prerender", True, [T("sends a file made at build", "manda um arquivo do build"), T("the whole page", "a página inteira"), T("as csr says", "o que o csr disser")]),
    ]
    for i, (title, mono, cells) in enumerate(cols):
        x = 120 + i * 150
        c.text(x + 67, 30, title, size=10.5, weight="600", mono=mono, fill="var(--amber)")
        for k, cell in enumerate(cells):
            y = 56 + k * 70
            weak = (i == 2 and k == 1) or (i == 1 and k == 2)
            c.rect(x, y, 135, 44, fill="var(--ink)" if weak else "var(--panel)",
                   stroke="var(--wire)" if weak else ("var(--phosphor)" if k == 2 else "var(--amber)"),
                   dash="4 3" if weak else None)
            c.text(x + 67, y + 22, cell, size=9.5, fill="var(--paper-dim)" if weak else "var(--paper)")
    c.text(360, 280, T("dashed: what that mode goes without", "tracejado: o que esse modo deixa de ter"),
           size=10, fill="var(--paper-dim)")
    c.caption = T("Two options switch the server's and the browser's halves on and off, and prerender moves the "
                  "server's half to build time.",
                  "Duas opções ligam e desligam a metade do servidor e a do navegador, e o prerender leva a metade do "
                  "servidor para o momento do build.")
    return c


def forgery(T):
    c = Canvas(720, 250, T(
        "A page on another site, elsewhere.example, holds a hidden form that posts to the planner at localhost 3000. "
        "The browser sends the POST with an Origin header saying https://elsewhere.example. The planner's server "
        "compares it with its own origin, http://localhost:3000, finds they differ, and answers 403 without running "
        "the action. A form on the planner's own page sends the planner's origin and is let through.",
        "Uma página em outro site, elsewhere.example, tem um formulário escondido que envia para o planner em "
        "localhost 3000. O navegador manda o POST com um cabeçalho Origin dizendo https://elsewhere.example. O "
        "servidor do planner compara com a sua própria origem, http://localhost:3000, vê que são diferentes e "
        "responde 403 sem rodar a action. Um formulário na própria página do planner manda a origem do planner e "
        "passa."))
    c.rect(20, 30, 220, 70, fill="var(--panel)", stroke="var(--amber)", dash="4 3")
    c.text(130, 52, "elsewhere.example", mono=True, size=10, fill="var(--amber)")
    c.text(130, 76, T("a hidden form, sent on load", "um formulário escondido, enviado ao carregar"), size=9.5)
    c.rect(20, 140, 220, 70, fill="var(--panel)", stroke="var(--phosphor)")
    c.text(130, 162, "localhost:3000", mono=True, size=10, fill="var(--phosphor)")
    c.text(130, 186, T("the planner's own form", "o formulário do próprio planner"), size=9.5)
    c.rect(480, 85, 220, 70, fill="var(--ink)", stroke="var(--wire)")
    c.text(590, 106, T("the planner's server", "o servidor do planner"), size=10, weight="600")
    c.text(590, 130, "Origin === http://localhost:3000 ?", mono=True, size=9)
    c.line(240, 65, 478, 108, stroke="var(--amber)", arrow=True)
    c.text(360, 62, "Origin: https://elsewhere.example", mono=True, size=9, fill="var(--amber)")
    c.line(240, 175, 478, 132, stroke="var(--phosphor)", arrow=True)
    c.text(360, 182, "Origin: http://localhost:3000", mono=True, size=9, fill="var(--phosphor)")
    c.text(590, 178, T("no: 403, the action never runs", "não: 403, a action nem roda"), size=9.5, fill="var(--amber)")
    c.text(590, 196, T("yes: the action runs", "sim: a action roda"), size=9.5, fill="var(--phosphor)")
    c.text(360, 236, T("the browser writes the Origin header itself; a page cannot set it",
                       "o próprio navegador escreve o cabeçalho Origin; uma página não consegue mudá-lo"),
           size=10, fill="var(--paper-dim)")
    c.caption = T("A form from another site carries that site's origin, and a built SvelteKit server refuses it.",
                  "Um formulário de outro site leva a origem desse site, e um servidor SvelteKit de build o recusa.")
    return c


FIGURES = [("rendering-modes", modes), ("csrf", forgery)]
