from fig import Canvas


def shape(T):
    c = Canvas(720, 260, T(
        "A query against its schema. On the left, the schema's Course type has the fields id, title, sessions and "
        "minutesPlanned, and Session has id, course, date, minutes and done. In the middle, a query asks for course "
        "git with its title and its sessions' date and minutes; those fields are marked in the schema. On the right, "
        "the answer has exactly those fields, nested the same way.",
        "Uma consulta contra o seu schema. À esquerda, o tipo Course do schema tem os campos id, title, sessions e "
        "minutesPlanned, e Session tem id, course, date, minutes e done. No meio, uma consulta pede o curso git com o "
        "título e a data e os minutos das sessões; esses campos estão marcados no schema. À direita, a resposta tem "
        "exatamente esses campos, aninhados do mesmo jeito."))
    heads = [(20, T("the schema", "o schema")), (260, T("the query", "a consulta")), (490, T("the answer", "a resposta"))]
    for x, h in heads:
        c.text(x, 20, h, size=10.5, anchor="start", weight="600")
    c.rect(20, 34, 210, 210, fill="var(--panel)")
    lines = [("type Course {", None), ("  id: ID!", False), ("  title: String!", True), ("  sessions: [Session!]!", True),
             ("  minutesPlanned: Int!", False), ("}", None), ("type Session {", None), ("  id: Int!", False),
             ("  course: Course!", False), ("  date: String!", True), ("  minutes: Int!", True), ("  done: Boolean!", False), ("}", None)]
    for i, (s, on) in enumerate(lines):
        n = len(s) - len(s.lstrip())
        c.text(30 + n * 6, 50 + i * 15, s.strip(), mono=True, size=9.5, anchor="start",
               fill="var(--phosphor)" if on else ("var(--paper)" if on is None else "var(--paper-dim)"))
    c.rect(250, 34, 210, 210, fill="var(--ink)", stroke="var(--phosphor)")
    q = ["{", '  course(id: "git") {', "    title", "    sessions {", "      date", "      minutes", "    }", "  }", "}"]
    for i, s in enumerate(q):
        c.text(260 + (len(s) - len(s.lstrip())) * 6, 54 + i * 18, s.strip(), mono=True, size=10, anchor="start", fill="var(--phosphor)" if s.strip() in ("title", "sessions {", "date", "minutes") else "var(--paper)")
    c.rect(480, 34, 220, 210, fill="var(--panel)")
    a = ['{"data": {', '  "course": {', '    "title": "Git",', '    "sessions": [', '      {"date": "2026-10-08",', '       "minutes": 30}', "    ]", "  }", "}}"]
    for i, s in enumerate(a):
        c.text(490 + (len(s) - len(s.lstrip())) * 6, 54 + i * 18, s.strip(), mono=True, size=9.5, anchor="start")
    c.line(232, 140, 248, 140, stroke="var(--paper-dim)", arrow=False)
    c.line(462, 140, 478, 140, stroke="var(--paper-dim)", arrow=True)
    c.text(355, 236, T("checked against the schema", "conferida contra o schema"), size=9.5, fill="var(--paper-dim)")
    c.caption = T("The client names the fields; the server checks them against the schema and answers in the same shape, with nothing more.",
                  "O cliente nomeia os campos; o servidor os confere contra o schema e responde no mesmo formato, sem nada a mais.")
    return c


def nulls(T):
    c = Canvas(720, 230, T(
        "Where a failure's null goes. On the left, addSession returns Session with an exclamation mark, so when it "
        "throws the null cannot stop there and travels up to data, which becomes null. On the right, markDone returns "
        "Session without one, so an unknown id makes markDone null and data keeps everything else.",
        "Para onde vai o null de uma falha. À esquerda, addSession devolve Session com ponto de exclamação, então, "
        "quando ela lança um erro, o null não pode parar ali e sobe até data, que vira null. À direita, markDone "
        "devolve Session sem ele, então um id desconhecido deixa markDone null e data fica com todo o resto."))
    def tree(x, top, field, typ, nullable):
        c.rect(x, 40, 280, 160, fill="var(--panel)")
        c.text(x + 140, 24, top, size=10.5, weight="600")
        c.rect(x + 90, 56, 100, 30, fill="var(--ink)", stroke="var(--amber)" if not nullable else "var(--phosphor)")
        c.text(x + 140, 71, "data: null" if not nullable else "data", mono=True, size=10,
               fill="var(--amber)" if not nullable else "var(--paper)")
        c.rect(x + 50, 126, 180, 30, fill="var(--ink)", stroke="var(--amber)")
        c.text(x + 140, 141, f"{field}: {typ}", mono=True, size=10, fill="var(--amber)")
        c.line(x + 140, 124, x + 140, 90, stroke="var(--amber)" if not nullable else "var(--wire)", arrow=not nullable, dash=None if not nullable else "4 3")
        c.text(x + 140, 176, T("throws, or finds nothing", "lança um erro, ou não acha nada"), size=9.5, fill="var(--paper-dim)")
    tree(20, T("may never be null", "nunca pode ser null"), "addSession", "Session!", False)
    tree(420, T("may be null", "pode ser null"), "markDone", "Session", True)
    c.text(168, 108, T("the null travels up", "o null sobe"), size=9.5, anchor="start", fill="var(--amber)")
    c.text(568, 108, T("the null stops here", "o null para aqui"), size=9.5, anchor="start", fill="var(--paper-dim)")
    c.caption = T("A failed field becomes null at the nearest place the schema allows a null; with a ! everywhere above it, the whole answer goes.",
                  "Um campo que falha vira null no lugar mais próximo em que o schema aceita null; com ! em tudo acima dele, a resposta inteira vai embora.")
    return c


FIGURES = [("why-graphql", shape), ("errors", nulls)]
