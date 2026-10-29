from fig import Canvas


def crossing(T):
    c = Canvas(720, 240, T(
        "What one visit to the week page does with useFetch. On the server, rendering the page runs "
        "useFetch, which calls GET /api/courses inside the server, and the answer is used twice: to draw the "
        "HTML, and written into the page as the payload, the __NUXT_DATA__ script. The browser receives the "
        "HTML and the payload together, shows the HTML, and when it hydrates, useFetch in the browser finds "
        "its answer in the payload under the same key and makes no request. A plain $fetch in setup has no "
        "key and no payload, so the browser asks the API a second time.",
        "O que uma visita à página da semana faz com o useFetch. No servidor, renderizar a página roda o "
        "useFetch, que chama GET /api/courses dentro do servidor, e a resposta é usada duas vezes: para "
        "desenhar o HTML, e escrita na página como o payload, o script __NUXT_DATA__. O navegador recebe o HTML "
        "e o payload juntos, mostra o HTML, e quando hidrata, o useFetch no navegador acha a resposta no payload "
        "sob a mesma chave e não faz requisição. Um $fetch simples no setup não tem chave nem payload, então o "
        "navegador pergunta à API uma segunda vez."))
    c.rect(20, 30, 300, 180, fill="var(--panel)", stroke="var(--amber)", dash="5 4")
    c.text(170, 46, T("the server", "o servidor"), size=11, fill="var(--amber)")
    c.rect(40, 62, 120, 34, fill="var(--ink)", stroke="var(--wire)")
    c.text(100, 79, "useFetch(...)", mono=True, size=10)
    c.rect(190, 62, 110, 34, fill="var(--ink)", stroke="var(--wire)")
    c.text(245, 79, "/api/courses", mono=True, size=10)
    c.line(162, 79, 188, 79, stroke="var(--wire)", arrow=True)
    c.rect(40, 130, 120, 34, fill="var(--ink)", stroke="var(--phosphor)")
    c.text(100, 147, "HTML", mono=True, size=10, fill="var(--phosphor)")
    c.rect(180, 130, 120, 34, fill="var(--ink)", stroke="var(--amber)")
    c.text(240, 147, "__NUXT_DATA__", mono=True, size=10, fill="var(--amber)")
    c.line(100, 98, 100, 128, stroke="var(--wire)", arrow=True)
    c.line(245, 98, 240, 128, stroke="var(--wire)", arrow=True)
    c.text(170, 190, T("the answer, used twice", "a resposta, usada duas vezes"), size=10)
    c.rect(400, 30, 300, 180, fill="var(--panel)", stroke="var(--phosphor)", dash="5 4")
    c.text(550, 46, T("the browser", "o navegador"), size=11, fill="var(--phosphor)")
    c.rect(420, 62, 260, 34, fill="var(--ink)", stroke="var(--phosphor)")
    c.text(550, 79, T("shows the HTML at once", "mostra o HTML na hora"), size=10)
    c.rect(420, 120, 260, 44, fill="var(--ink)", stroke="var(--amber)")
    c.text(550, 136, "useFetch(...)", mono=True, size=10)
    c.text(550, 152, T("finds its key in the payload", "acha a chave no payload"), size=10)
    c.line(322, 147, 418, 142, stroke="var(--amber)", arrow=True)
    c.line(322, 100, 418, 79, stroke="var(--phosphor)", arrow=True)
    c.text(550, 190, T("no request: nothing to ask", "nenhuma requisição: nada a perguntar"), size=10)
    c.caption = T("The payload is the server's answer carried inside the page, so the browser does not ask again.",
                  "O payload é a resposta do servidor levada dentro da página, para o navegador não perguntar de novo.")
    return c


def twice(T):
    c = Canvas(720, 235, T(
        "One visit to /demo/twice, in time order from left to right, on two rows. On the server: first the layout's "
        "session-count fetches GET /api/courses; then the page's $fetch fetches GET /api/courses; then the server "
        "draws 6 sessions and sends the HTML. In the browser: the same setup runs again to hydrate, and the same "
        "$fetch, knowing nothing about payloads, fetches GET /api/courses a third time. The server's terminal "
        "prints one line for each of the three.",
        "Uma visita a /demo/twice, em ordem de tempo da esquerda para a direita, em duas linhas. No servidor: "
        "primeiro o session-count do layout busca GET /api/courses; depois o $fetch da página busca GET "
        "/api/courses; depois o servidor desenha 6 sessions e envia o HTML. No navegador: o mesmo setup roda de novo "
        "para hidratar, e o mesmo $fetch, que não sabe nada de payloads, busca GET /api/courses uma terceira vez. O "
        "terminal do servidor imprime uma linha para cada uma das três."))
    c.text(20, 63, T("server", "servidor"), size=11, anchor="start", fill="var(--amber)")
    c.text(20, 163, T("browser", "navegador"), size=11, anchor="start", fill="var(--phosphor)")
    boxes = [(90, 40, "1", "GET /api/courses", T("the layout's session-count", "o session-count do layout"), True),
             (240, 40, "2", "GET /api/courses", T("the page's $fetch", "o $fetch da página"), True),
             (390, 40, None, T("draws 6 sessions", "desenha 6 sessions"), T("sends the HTML", "envia o HTML"), False),
             (410, 140, None, T("runs the same setup", "roda o mesmo setup"), T("to hydrate", "para hidratar"), False),
             (565, 140, "3", "GET /api/courses", T("the same $fetch, again", "o mesmo $fetch, de novo"), True)]
    for x, y, n, top, bottom, req in boxes:
        col = "var(--amber)" if req else "var(--wire)"
        c.rect(x, y, 145, 46, fill="var(--ink)" if req else "var(--panel)", stroke=col)
        c.text(x + 72, y + 15, top, mono=req, size=9.5, fill="var(--amber)" if req else "var(--paper)")
        c.text(x + 72, y + 32, bottom, size=9.5)
        if n:
            c.text(x + 72, y - 10, n, mono=True, size=11, weight="600", fill="var(--amber)")
    c.line(462, 88, 462, 136, stroke="var(--wire)", arrow=True)
    c.text(472, 112, "HTML", mono=True, size=9.5, anchor="start", fill="var(--paper-dim)")
    c.line(557, 163, 561, 163, stroke="var(--wire)", arrow=True)
    c.line(90, 212, 710, 212, stroke="var(--wire)", arrow=True)
    c.text(400, 226, T("one visit, three lines of api: GET /api/courses in the server's terminal",
                       "uma visita, três linhas de api: GET /api/courses no terminal do servidor"),
           size=9.5, fill="var(--paper-dim)")
    c.caption = T("Plain $fetch in setup runs on both sides, so the browser asks again for what the server already drew.",
                  "Um $fetch simples no setup roda nos dois lados, então o navegador pede de novo o que o servidor já desenhou.")
    return c


FIGURES = [("the-payload", crossing), ("double-fetch", twice)]
