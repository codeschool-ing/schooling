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


def reach(T):
    c = Canvas(720, 255, T(
        "The OneWay demo. The parent, OneWay.vue, has minutes, 30, and session, which points at its own reactive "
        "object with course spanish and minutes 30. Both are passed down as props to Counter.vue, whose props are "
        "read-only. Its session prop points at the same object, not a copy. Writing props.minutes plus 5 is refused "
        "with a warning, and the parent keeps 30. Writing props.session.minutes plus 5 is allowed: it changes the "
        "parent's object, and the minutes go from 30 to 35 in the child and in the parent.",
        "A demo OneWay. O pai, OneWay.vue, tem minutes, 30, e session, que aponta para o próprio objeto reativo "
        "dele, com course spanish e minutes 30. Os dois descem como props para o Counter.vue, cujas props são "
        "somente leitura. A prop session dele aponta para o mesmo objeto, não para uma cópia. Escrever props.minutes "
        "mais 5 é recusado com um aviso, e o pai continua com 30. Escrever props.session.minutes mais 5 é permitido: "
        "muda o objeto do pai, e os minutos vão de 30 a 35 no filho e no pai."))
    for x, name, sub in ((20, "OneWay.vue", T("the parent", "o pai")), (520, "Counter.vue", T("read-only props", "props somente leitura"))):
        c.rect(x, 30, 180, 110, fill="var(--ink)", stroke="var(--wire)")
        c.text(x + 90, 48, name, mono=True, size=11, fill="var(--amber)")
        c.text(x + 90, 64, sub, size=9.5, fill="var(--paper-dim)")
        c.text(x + 90, 88, "minutes: 30", mono=True, size=10.5)
        c.text(x + 90, 118, "session", mono=True, size=10.5)
    c.line(202, 88, 516, 88, stroke="var(--wire)", arrow=True)
    c.text(360, 76, T("passed down as props", "passados como props"), size=10, fill="var(--paper-dim)")
    c.rect(240, 168, 230, 50, fill="var(--panel)", stroke="var(--phosphor)")
    c.text(355, 184, "{ course: 'spanish',", mono=True, size=10.5)
    c.text(355, 202, "  minutes: 30 → 35 }", mono=True, size=10.5, fill="var(--phosphor)")
    c.text(355, 236, T("the parent's reactive object, one copy", "o objeto reativo do pai, uma cópia só"), size=9.5,
           fill="var(--paper-dim)")
    c.line(110, 142, 270, 166, stroke="var(--phosphor)", arrow=True)
    c.line(560, 142, 445, 166, stroke="var(--phosphor)", arrow=True)
    c.text(525, 166, "props.minutes += 5", mono=True, size=9.5, anchor="start", fill="var(--amber)")
    c.text(525, 182, T("refused; the parent keeps 30", "recusado; o pai continua com 30"), size=9.5, anchor="start",
           fill="var(--amber)")
    c.text(525, 206, "props.session.minutes += 5", mono=True, size=9.5, anchor="start", fill="var(--phosphor)")
    c.text(525, 222, T("allowed: 35 in both", "permitido: 35 nos dois"), size=9.5, anchor="start",
           fill="var(--phosphor)")
    c.caption = T("The props object is read-only one level deep; the object a prop points at is still the parent's.",
                  "O objeto das props é somente leitura num nível só; o objeto para onde uma prop aponta continua sendo do pai.")
    return c


FIGURES = [("the-contract", contract), ("one-way", reach)]
