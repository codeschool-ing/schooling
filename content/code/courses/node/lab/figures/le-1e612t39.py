from fig import Canvas


def request(T):
    c = Canvas(720, 270, T(
        "The bytes of one request on the socket, in time order: the request line, the headers, then two pieces of body. "
        "As soon as the headers are complete, Node calls your handler with req and res. The body pieces arrive afterwards "
        "and are read from req as a stream. The handler writes the reply to res, which goes back over the same socket.",
        "Os bytes de uma requisição no socket, em ordem de tempo: a linha da requisição, os cabeçalhos, depois dois pedaços "
        "de corpo. Assim que os cabeçalhos estão completos, o Node chama o seu handler com req e res. Os pedaços do corpo "
        "chegam depois e são lidos do req como um stream. O handler escreve a resposta no res, que volta pelo mesmo socket."))
    c.text(20, 22, T("bytes arriving on the socket", "bytes chegando no socket"), anchor="start", size=10.5, fill="var(--paper-dim)")
    segs = [(20, 150, "POST /links HTTP/1.1", True), (174, 150, T("headers", "cabeçalhos"), False),
            (330, 120, T("body, piece 1", "corpo, pedaço 1"), False), (460, 120, T("body, piece 2", "corpo, pedaço 2"), False)]
    for x, w, t, mono in segs:
        c.rect(x, 36, w - 6, 30, fill="var(--panel)", stroke="var(--wire)")
        c.text(x + (w - 6) / 2, 51, t, mono=mono, size=10, fill="var(--paper)")
    c.line(20, 80, 700, 80, stroke="var(--paper-dim)", arrow=True)
    c.text(700, 94, T("time", "tempo"), anchor="end", size=9.5, fill="var(--paper-dim)")
    c.line(322, 66, 322, 118, stroke="var(--amber)", dash="3 3")
    c.rect(150, 120, 280, 54, fill="var(--ink)", stroke="var(--amber)")
    c.text(290, 138, T("the 'request' event", "o evento 'request'"), size=11, weight="600", fill="var(--amber)")
    c.text(290, 158, "handler(req, res)", mono=True, size=10.5, fill="var(--paper)")
    c.text(330, 104, T("headers complete", "cabeçalhos completos"), anchor="start", size=9.5, fill="var(--amber)")
    for x in (391, 521):
        c.path(f"M{x} 66 C {x} 100, {x+60} 110, {x+90} 140", stroke="var(--phosphor)")
        c.line(x + 88, 137, x + 90, 140, stroke="var(--phosphor)", arrow=True)
    c.rect(500, 140, 200, 34, fill="var(--ink)", stroke="var(--phosphor)")
    c.text(600, 157, T("for await (chunk of req)", "for await (chunk of req)"), mono=True, size=10, fill="var(--phosphor)")
    c.rect(150, 210, 280, 40, fill="var(--panel)", stroke="var(--wire)")
    c.text(290, 230, "res.writeHead(…)   res.end(…)", mono=True, size=10.5, fill="var(--paper)")
    c.line(290, 174, 290, 208, stroke="var(--paper-dim)", arrow=True)
    c.text(440, 230, T("back over the same socket", "volta pelo mesmo socket"), anchor="start", size=9.5, fill="var(--paper-dim)")
    c.caption = T("Your handler runs when the headers are in, before the body. The body is read from req as it arrives.",
                  "O seu handler roda quando os cabeçalhos chegam, antes do corpo. O corpo é lido do req à medida que chega.")
    return c


FIGURES = [("the-http-module", request)]
