from fig import Canvas


def onion(T):
    c = Canvas(720, 300, T(
        "A request arrives at adapter-node. A request for a file, a prerendered page such as /about or something in "
        "static, is answered from disk straight away and never reaches the hooks. Every other request goes into "
        "handle, which is sequence(log, headers): log starts its clock and calls resolve, which calls headers, which "
        "calls SvelteKit's own resolve to run the load functions, the action or the endpoint and render the page. "
        "The response comes back out through headers, which adds three headers, and through log, which prints a "
        "line, and leaves.",
        "Uma requisição chega ao adapter-node. Uma requisição de arquivo, uma página pré-renderizada como /about ou "
        "algo em static, é respondida do disco na hora e nunca chega aos hooks. Toda outra requisição entra no "
        "handle, que é sequence(log, headers): o log começa a contar o tempo e chama resolve, que chama headers, que "
        "chama o resolve do próprio SvelteKit para rodar as funções load, a action ou o endpoint e renderizar a "
        "página. A resposta volta passando por headers, que acrescenta três cabeçalhos, e por log, que imprime uma "
        "linha, e sai."))
    c.rect(20, 120, 110, 50, fill="var(--panel)", stroke="var(--wire)")
    c.text(75, 138, T("a request", "uma requisição"), size=10)
    c.text(75, 156, "adapter-node", mono=True, size=9, fill="var(--paper-dim)")
    c.rect(20, 220, 200, 50, fill="var(--ink)", stroke="var(--wire)", dash="4 3")
    c.text(120, 238, T("a file: /about, static/", "um arquivo: /about, static/"), size=9.5)
    c.text(120, 256, T("sent from disk, no hooks", "enviado do disco, sem hooks"), size=9, fill="var(--paper-dim)")
    c.line(75, 170, 75, 218, stroke="var(--paper-dim)", dash="4 3", arrow=True)
    c.rect(170, 20, 530, 190, fill="var(--panel)", stroke="var(--amber)")
    c.text(182, 38, "log", mono=True, size=10, anchor="start", fill="var(--amber)")
    c.text(688, 38, T("starts a clock · prints a line", "começa um relógio · imprime uma linha"), size=9, anchor="end", fill="var(--paper-dim)")
    c.rect(200, 52, 470, 140, fill="var(--ink)", stroke="var(--amber)")
    c.text(212, 70, "headers", mono=True, size=10, anchor="start", fill="var(--amber)")
    c.text(658, 70, T("adds three headers on the way out", "acrescenta três cabeçalhos na saída"), size=9, anchor="end", fill="var(--paper-dim)")
    c.rect(230, 86, 410, 90, fill="var(--panel)", stroke="var(--phosphor)")
    c.text(435, 110, "resolve(event)", mono=True, size=10, fill="var(--phosphor)")
    c.text(435, 134, T("load functions, the action or the endpoint", "funções load, a action ou o endpoint"), size=9.5)
    c.text(435, 154, T("and the page rendered", "e a página renderizada"), size=9.5)
    c.line(130, 145, 168, 145, stroke="var(--paper-dim)", arrow=True)
    c.text(435, 290, T("sequence(log, headers): each one wraps the ones after it",
                       "sequence(log, headers): cada um envolve os que vêm depois"), size=10, fill="var(--paper-dim)")
    c.caption = T("A request goes in through each handle in order and comes back out the other way. Files the "
                  "adapter serves itself never go in.",
                  "Uma requisição entra por cada handle em ordem e volta pelo caminho contrário. Arquivos que o "
                  "adapter serve sozinho nunca entram.")
    return c


FIGURES = [("headers", onion)]
