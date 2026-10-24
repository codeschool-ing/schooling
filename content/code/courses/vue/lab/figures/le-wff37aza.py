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


FIGURES = [("the-payload", crossing)]
