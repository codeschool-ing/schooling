from fig import Canvas


def proxy(T):
    c = Canvas(720, 250, T(
        "Inside one machine, a proxy listens on the public address and passes each request to Node on 127.0.0.1, "
        "adding X-Forwarded-For with the address the request really came from. Outside the machine, a client at "
        "203.0.113.9. Node trusts the header only because the proxy, on loopback, is the only thing that can reach it.",
        "Dentro de uma máquina, um proxy escuta no endereço público e repassa cada requisição ao Node em 127.0.0.1, "
        "acrescentando o X-Forwarded-For com o endereço de onde a requisição veio de fato. Fora da máquina, um cliente "
        "em 203.0.113.9. O Node confia no cabeçalho só porque o proxy, no loopback, é a única coisa que o alcança."))
    c.rect(20, 80, 150, 70, fill="var(--panel)", stroke="var(--wire)")
    c.text(95, 104, T("a client", "um cliente"), size=11, fill="var(--paper)")
    c.text(95, 126, "203.0.113.9", mono=True, size=10.5, fill="var(--paper-dim)")
    c.rect(230, 20, 470, 210, fill="none", stroke="var(--wire)", dash="5 4")
    c.text(246, 36, T("one machine", "uma máquina"), anchor="start", size=10.5, fill="var(--paper-dim)")
    c.rect(260, 80, 160, 70, fill="var(--panel)", stroke="var(--wire)")
    c.text(340, 104, T("the proxy", "o proxy"), size=11, fill="var(--paper)")
    c.text(340, 126, T("public address, :443", "endereço público, :443"), size=9.5, fill="var(--paper-dim)")
    c.rect(500, 80, 180, 70, fill="var(--ink)", stroke="var(--phosphor)")
    c.text(590, 102, "Node, 127.0.0.1:3000", mono=True, size=10, fill="var(--phosphor)")
    c.text(590, 124, 'trust proxy: "loopback"', mono=True, size=9.5, fill="var(--paper)")
    c.line(170, 115, 258, 115, stroke="var(--paper-dim)", arrow=True)
    c.line(420, 115, 498, 115, stroke="var(--paper-dim)", arrow=True)
    c.text(459, 170, "X-Forwarded-For:", mono=True, size=9.5, fill="var(--amber)")
    c.text(459, 186, "203.0.113.9", mono=True, size=9.5, fill="var(--amber)")
    c.text(590, 186, "req.ip = 203.0.113.9", mono=True, size=10, fill="var(--phosphor)")
    c.text(214, 100, T("internet", "internet"), size=9.5, fill="var(--paper-dim)")
    c.caption = T("The header is believed because only the proxy can reach the loopback address. Trust that reaches further lets any client write its own.",
                  "O cabeçalho é aceito porque só o proxy alcança o endereço de loopback. Uma confiança que vá além deixa qualquer cliente escrever o seu.")
    return c


def url_parts(T):
    c = Canvas(720, 200, T(
        "A request split into the parts Express hands a route. The method GET and the path /links/7ctxqn are matched "
        "against the route links.get('/:code'), mounted at /links; the part that matched :code becomes req.params.code. "
        "What follows the question mark, limit=2, becomes req.query.limit. Both arrive as strings.",
        "Um pedido dividido nas partes que o Express entrega a uma rota. O método GET e o caminho /links/7ctxqn são "
        "comparados com a rota links.get('/:code'), pendurada em /links; a parte que casou com :code vira req.params.code. "
        "O que vem depois do ponto de interrogação, limit=2, vira req.query.limit. Os dois chegam como strings."))
    c.text(360, 40, "GET /links/7ctxqn?limit=2", mono=True, size=14)
    c.line(218, 54, 300, 54, stroke="var(--wire)")
    c.line(305, 54, 360, 54, stroke="var(--phosphor)", sw=2)
    c.line(372, 54, 448, 54, stroke="var(--amber)", sw=2)
    c.rect(150, 90, 200, 50, fill="var(--panel)", stroke="var(--wire)")
    c.text(250, 108, "links.get(\"/:code\")", mono=True, size=10)
    c.text(250, 126, T("mounted at /links", "pendurada em /links"), size=9.5, fill="var(--paper-dim)")
    c.line(258, 58, 250, 88, stroke="var(--wire)")
    c.rect(380, 90, 160, 50, fill="var(--ink)", stroke="var(--phosphor)")
    c.text(460, 108, "req.params.code", mono=True, size=10, fill="var(--phosphor)")
    c.text(460, 126, '"7ctxqn"', mono=True, size=10)
    c.line(332, 58, 440, 88, stroke="var(--phosphor)")
    c.rect(560, 90, 140, 50, fill="var(--ink)", stroke="var(--amber)")
    c.text(630, 108, "req.query.limit", mono=True, size=10, fill="var(--amber)")
    c.text(630, 126, '"2"', mono=True, size=10)
    c.line(410, 58, 610, 88, stroke="var(--amber)")
    c.text(360, 175, T("both are strings, and both were typed by the client", "os dois são strings, e os dois foram digitados pelo cliente"), size=10.5, fill="var(--paper-dim)")
    c.caption = T("The path picks the route and fills params; the query string is a separate object beside it.",
                  "O caminho escolhe a rota e preenche os params; a query string é um objeto à parte, ao lado.")
    return c


FIGURES = [("proxies-and-headers", proxy), ("params", url_parts)]
