from fig import Canvas


def contract(T):
    c = Canvas(720, 250, T(
        "App at the top owns the sessions. Arrows labelled props go down to two children, CourseCard, which is "
        "given a title and three numbers, and SessionRow, which is given a session and a title. An arrow "
        "labelled event goes up from SessionRow to App, carrying toggle and an id. App then replaces its "
        "list, and the new values flow down again as props.",
        "App, no topo, é dono das sessões. Setas marcadas props descem para dois filhos: CourseCard, que recebe "
        "um título e três números, e SessionRow, que recebe uma sessão e um título. Uma seta marcada evento "
        "sobe de SessionRow para App, levando toggle e um id. App então substitui a lista, e os valores novos "
        "descem de novo como props."))
    c.rect(250, 15, 220, 60, fill="var(--ink)", stroke="var(--amber)")
    c.text(360, 35, "App.vue", mono=True, size=12, weight="600", fill="var(--amber)")
    c.text(360, 57, T("owns the sessions", "dono das sessões"), size=10.5)
    c.rect(60, 170, 220, 60, fill="var(--ink)", stroke="var(--phosphor)")
    c.text(170, 190, "CourseCard", mono=True, size=12, weight="600", fill="var(--phosphor)")
    c.text(170, 212, T("draws, owns nothing", "desenha, não é dono de nada"), size=10.5)
    c.rect(440, 170, 220, 60, fill="var(--ink)", stroke="var(--phosphor)")
    c.text(550, 190, "SessionRow", mono=True, size=12, weight="600", fill="var(--phosphor)")
    c.text(550, 212, T("draws, and reports a tick", "desenha, e avisa de um clique"), size=10.5)
    c.line(300, 77, 190, 168, stroke="var(--phosphor)", arrow=True)
    c.text(150, 115, "props", mono=True, size=10.5, fill="var(--phosphor)")
    c.text(150, 131, "title, goal, planned, done", mono=True, size=9.5, fill="var(--paper-dim)")
    c.line(395, 77, 500, 168, stroke="var(--phosphor)", arrow=True)
    c.text(436, 128, "props", mono=True, size=10.5, fill="var(--phosphor)", anchor="end")
    c.text(436, 144, "session, title", mono=True, size=9.5, fill="var(--paper-dim)", anchor="end")
    c.line(600, 168, 470, 60, stroke="var(--amber)", arrow=True, dash="5 3")
    c.text(612, 105, T("event", "evento"), size=10.5, fill="var(--amber)", anchor="start")
    c.text(612, 121, "toggle('s5')", mono=True, size=9.5, fill="var(--amber)", anchor="start")
    c.caption = T("Data goes down as props; news comes up as events, to whoever owns the data.",
                  "Os dados descem como props; as notícias sobem como eventos, para quem é dono dos dados.")
    return c


FIGURES = [("the-contract", contract)]
