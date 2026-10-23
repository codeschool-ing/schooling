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


def files(T):
    c = Canvas(720, 230, T(
        "The five files of the links service and who imports whom. server.js imports app.js and starts it listening. "
        "app.js builds the application and mounts the router from links.js. links.js holds the routes and imports "
        "admin.js, for the key, and store.js, for the links. store.js imports code.js, which makes the codes.",
        "Os cinco arquivos do serviço links e quem importa quem. O server.js importa o app.js e o põe para escutar. O "
        "app.js monta a aplicação e pendura o roteador do links.js. O links.js tem as rotas e importa o admin.js, para a "
        "chave, e o store.js, para os links. O store.js importa o code.js, que faz os códigos."))
    boxes = {"server.js": (20, 90, T("listens", "escuta")), "src/app.js": (180, 90, T("builds the app", "monta o app")),
             "src/links.js": (350, 90, T("the routes", "as rotas")), "src/admin.js": (540, 30, T("the key", "a chave")),
             "src/store.js": (540, 150, T("the links", "os links")), "src/code.js": (540, 210 - 20, "")}
    for name, (x, y, what) in list(boxes.items())[:5]:
        c.rect(x, y, 140, 46, fill="var(--ink)" if name == "src/links.js" else "var(--panel)",
               stroke="var(--phosphor)" if name == "src/links.js" else "var(--wire)")
        c.text(x + 70, y + 16, name, mono=True, size=10)
        c.text(x + 70, y + 33, what, size=9.5, fill="var(--paper-dim)")
    c.line(160, 113, 178, 113, stroke="var(--paper-dim)", arrow=True)
    c.line(320, 113, 348, 113, stroke="var(--paper-dim)", arrow=True)
    c.line(490, 105, 538, 60, stroke="var(--paper-dim)", arrow=True)
    c.line(490, 121, 538, 168, stroke="var(--paper-dim)", arrow=True)
    c.rect(380, 175, 140, 40, fill="var(--panel)", stroke="var(--wire)")
    c.text(450, 189, "src/code.js", mono=True, size=10)
    c.text(450, 205, T("makes the codes", "faz os códigos"), size=9.5, fill="var(--paper-dim)")
    c.line(540, 186, 522, 192, stroke="var(--paper-dim)", arrow=True)
    c.text(20, 30, T("an arrow: imports", "uma seta: importa"), size=10, anchor="start", fill="var(--paper-dim)")
    c.caption = T("One job per file: the rules of the service sit in links.js, and the plumbing around it.",
                  "Um trabalho por arquivo: as regras do serviço ficam no links.js, e o encanamento em volta.")
    return c


def errpath(T):
    c = Canvas(720, 210, T(
        "The path of a request through the Express chain. Normally it passes the logger, the JSON parser and the router, "
        "and a route answers. When a route throws, or its promise rejects, Express skips every ordinary middleware still "
        "ahead and goes straight to the error handler, the one with four parameters, which answers with a status and a "
        "JSON body.",
        "O caminho de um pedido pela cadeia do Express. Normalmente ele passa pelo log, pelo leitor de JSON e pelo "
        "roteador, e uma rota responde. Quando uma rota lança um erro, ou a promise dela rejeita, o Express pula todo "
        "middleware comum que ainda falta e vai direto ao handler de erro, o de quatro parâmetros, que responde com um "
        "status e um corpo JSON."))
    names = [(T("log", "log"), False), ("express.json", True), (T("router", "roteador"), False),
             (T("route", "rota"), False), ("404", True), ("(err, req, res, next)", True)]
    xs = [20, 130, 260, 370, 480, 560]
    ws = [96, 116, 96, 96, 66, 140]
    for (name, mono), x, w in zip(names, xs, ws):
        last = x == 560
        c.rect(x, 60, w, 44, fill="var(--ink)" if last else "var(--panel)", stroke="var(--amber)" if last else "var(--wire)")
        c.text(x + w / 2, 82, name, mono=mono, size=9.5 if last else 10, fill="var(--amber)" if last else "var(--paper)")
    for a, b in ((116, 128), (246, 258), (356, 368)):
        c.line(a, 82, b, 82, stroke="var(--phosphor)", arrow=True)
    c.text(418, 128, T("answers: 200, 201…", "responde: 200, 201…"), size=9.5, fill="var(--phosphor)")
    c.path("M418 104 C 418 170, 630 170, 630 108", stroke="var(--amber)")
    c.line(630, 116, 630, 106, stroke="var(--amber)", arrow=True)
    c.text(520, 182, T("throws, or rejects: everything between is skipped", "lança, ou rejeita: tudo no meio é pulado"), size=10, fill="var(--amber)")
    c.text(20, 36, T("one request, left to right", "um pedido, da esquerda para a direita"), size=10, anchor="start", fill="var(--paper-dim)")
    c.caption = T("An error does not travel the chain: it jumps to the one middleware that takes four arguments.",
                  "Um erro não percorre a cadeia: ele pula para o único middleware que recebe quatro argumentos.")
    return c


FIGURES = [("middleware", chain), ("the-links-app", files), ("error-handlers", errpath)]
