from fig import Canvas


def cache(T):
    c = Canvas(720, 240, T(
        "Two parts of a page, the course page and a weekly summary, each watch a query. Both queries point into "
        "Apollo's cache at the same entry, Session:6. A mutation's answer from the server updates that one entry, "
        "and both parts of the page redraw. A second request for data already in the cache is answered without the "
        "server.",
        "Duas partes de uma página, a página do curso e um resumo da semana, observam cada uma uma consulta. As duas "
        "consultas apontam, no cache do Apollo, para a mesma entrada, Session:6. A resposta de uma mutation vinda do "
        "servidor atualiza essa entrada, e as duas partes da página se redesenham. Um segundo pedido de dados que já "
        "estão no cache é respondido sem o servidor."))
    c.text(20, 20, T("the page", "a página"), size=10.5, anchor="start", weight="600")
    c.rect(20, 34, 170, 50, fill="var(--panel)")
    c.text(105, 59, T("course page", "página do curso"), size=10.5)
    c.rect(20, 110, 170, 50, fill="var(--panel)")
    c.text(105, 135, T("weekly summary", "resumo da semana"), size=10.5)
    c.text(290, 20, T("the cache", "o cache"), size=10.5, anchor="start", weight="600")
    c.rect(280, 34, 200, 170, fill="var(--ink)", stroke="var(--phosphor)")
    for i, k in enumerate(["Course:javascript", "Session:4", "Session:6", "ROOT_QUERY"]):
        on = k == "Session:6"
        c.rect(296, 48 + i * 38, 168, 26, fill="var(--panel)", stroke="var(--phosphor)" if on else "var(--wire)")
        c.text(380, 61 + i * 38, k, mono=True, size=10, fill="var(--phosphor)" if on else "var(--paper)")
    c.line(192, 59, 294, 121, stroke="var(--phosphor)", arrow=True)
    c.line(192, 135, 294, 125, stroke="var(--phosphor)", arrow=True)
    c.text(590, 20, T("the server", "o servidor"), size=10.5, weight="600")
    c.rect(530, 60, 120, 50, fill="var(--panel)")
    c.text(590, 85, "/graphql", mono=True, size=10.5)
    c.line(528, 100, 466, 121, stroke="var(--amber)", arrow=True)
    c.text(560, 138, T("markDone's answer", "a resposta do markDone"), size=9.5, fill="var(--amber)")
    c.text(560, 154, T("updates the entry", "atualiza a entrada"), size=9.5, fill="var(--amber)")
    c.text(380, 222, T("asked again: answered here, no request", "pedido de novo: respondido aqui, sem requisição"), size=9.5, fill="var(--paper-dim)")
    c.caption = T("One entry per object: a change to Session:6 reaches every query that shows it, and a repeated question never leaves the browser.",
                  "Uma entrada por objeto: uma mudança em Session:6 chega a toda consulta que a mostra, e uma pergunta repetida não sai do navegador.")
    return c


def rollback(T):
    c = Canvas(720, 200, T(
        "A timeline of an optimistic update that fails. The press of Mark done adds an optimistic layer to the cache "
        "at once, and the row shows done. The mutation reaches the proxy, which answers 502 because the server is "
        "down. Apollo drops the optimistic layer, the cache answers as before, and the row shows its button again.",
        "Uma linha do tempo de uma atualização otimista que falha. Apertar Mark done acrescenta na hora uma camada "
        "otimista ao cache, e a linha mostra done. A mutation chega ao proxy, que responde 502 porque o servidor "
        "caiu. O Apollo descarta a camada otimista, o cache responde como antes, e a linha volta a mostrar o botão."))
    c.line(40, 100, 690, 100, stroke="var(--wire)", arrow=True)
    c.text(690, 86, T("time", "tempo"), size=9.5, anchor="end", fill="var(--paper-dim)")
    steps = [
        (90, T("press", "clique"), "Mark done", "var(--paper)"),
        (250, T("optimistic layer", "camada otimista"), "done: true", "var(--phosphor)"),
        (430, T("the proxy answers", "o proxy responde"), "502", "var(--amber)"),
        (600, T("layer dropped", "camada descartada"), "done: false", "var(--paper)"),
    ]
    for x, label, code, col in steps:
        c.rect(x - 60, 40, 120, 40, fill="var(--panel)", stroke=col if col != "var(--paper)" else "var(--wire)")
        c.text(x, 60, label, size=10)
        c.line(x, 80, x, 100, stroke="var(--wire)")
        c.text(x, 120, code, mono=True, size=10, fill=col)
    c.rect(170, 140, 340, 36, fill="var(--ink)", stroke="var(--phosphor)", dash="4 3")
    c.text(340, 158, T("the row shows done", "a linha mostra done"), size=10, fill="var(--phosphor)")
    c.rect(530, 140, 150, 36, fill="var(--ink)", stroke="var(--wire)")
    c.text(605, 158, T("the button is back", "o botão voltou"), size=10)
    c.caption = T("The optimistic answer lives in a layer of its own, so a refusal removes it and the cache's older truth shows through.",
                  "A resposta otimista fica numa camada própria, então uma recusa a remove e a verdade anterior do cache volta a aparecer.")
    return c


FIGURES = [("what-a-client-adds", cache), ("optimistic-updates", rollback)]
