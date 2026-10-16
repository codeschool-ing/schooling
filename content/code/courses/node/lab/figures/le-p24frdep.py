from fig import Canvas


def chain(T):
    c = Canvas(720, 250, T(
        "The links application as a chain. A request enters on the left and passes through a logger, the JSON parser, "
        "the router for /links, the short-link route and the 404 handler, each calling next() to pass it on. Any of the last "
        "four can answer instead. An error anywhere jumps along a dashed path to the error handler at the end.",
        "A aplicação links como uma corrente. Uma requisição entra pela esquerda e passa por um logger, o parser de JSON, "
        "o roteador de /links, a rota do link curto e o handler de 404, cada um chamando next() para passá-la adiante. "
        "Qualquer um dos quatro últimos pode responder em vez disso. Um erro em qualquer ponto pula por um caminho tracejado "
        "até o handler de erros no fim."))
    boxes = [("logger", T("logs at finish", "registra no finish"), None),
             ("express.json", T("fills req.body", "preenche req.body"), None),
             ("/links", T("router", "roteador"), "res.json(…)"),
             ("/:code", T("short link", "link curto"), "res.redirect(…)"),
             ("404", T("matched nothing", "nada casou"), "res.status(404)")]
    x = 20
    c.text(20, 16, T("request", "requisição"), anchor="start", size=10.5, fill="var(--paper-dim)")
    for i, (name, sub, answers) in enumerate(boxes):
        c.rect(x, 40, 100, 56, fill="var(--panel)", stroke="var(--wire)")
        c.text(x + 50, 60, name, mono=True, size=11, fill="var(--paper)")
        c.text(x + 50, 80, sub, size=9.5, fill="var(--paper-dim)")
        if i < len(boxes) - 1:
            c.line(x + 100, 68, x + 136, 68, stroke="var(--phosphor)", arrow=True)
            c.text(x + 118, 32, "next()", mono=True, size=8.5, fill="var(--phosphor)")
        if answers:
            c.line(x + 50, 96, x + 50, 140, stroke="var(--paper-dim)", arrow=True)
            c.text(x + 50, 152, answers, mono=True, size=9, fill="var(--paper-dim)")
        x += 136
    c.rect(560, 190, 140, 44, fill="var(--ink)", stroke="var(--amber)")
    c.text(630, 206, T("error handler", "handler de erros"), size=11, weight="600", fill="var(--amber)")
    c.text(630, 223, "(err, req, res, next)", mono=True, size=9, fill="var(--paper)")
    c.path("M70 96 L70 212 L556 212", stroke="var(--amber)", dash="4 3")
    c.line(548, 212, 557, 212, stroke="var(--amber)", arrow=True)
    c.text(300, 226, T("a throw, a rejected promise or next(err), from anywhere", "um throw, uma promise rejeitada ou next(err), de qualquer ponto"), size=9.5, fill="var(--amber)")
    c.caption = T("Each function answers or calls next(). Order is the order of app.use, and errors skip to the end.",
                  "Cada função responde ou chama next(). A ordem é a dos app.use, e os erros pulam para o fim.")
    return c


FIGURES = [("middleware", chain)]
