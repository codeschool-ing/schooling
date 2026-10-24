from fig import Canvas


def flow(T):
    c = Canvas(720, 210, T(
        "Where the planner's types are written and where they are only inferred. planner.ts declares Course and "
        "Session. The store writes ref of Course array and ref of Session array, once. The views and the "
        "components read the store and receive those types with nothing written in them; SessionRow names "
        "Session in its props because it is given one by its parent.",
        "Onde os tipos do planner são escritos e onde só são inferidos. O planner.ts declara Course e Session. A "
        "store escreve ref de array de Course e ref de array de Session, uma vez. As views e os componentes leem "
        "a store e recebem esses tipos sem nada escrito neles; o SessionRow nomeia Session nas props porque o "
        "recebe do pai."))
    boxes = [("planner.ts", "interface Session", 20, "var(--amber)", T("written", "escrito")),
             ("stores/planner.ts", "ref<Session[]>([])", 260, "var(--amber)", T("written once", "escrito uma vez")),
             ("HomeView.vue", "sessions.value", 500, "var(--phosphor)", T("inferred", "inferido"))]
    for name, code, x, col, label in boxes:
        c.rect(x, 40, 200, 70, fill="var(--ink)", stroke=col)
        c.text(x + 100, 60, name, mono=True, size=11, weight="600", fill=col)
        c.text(x + 100, 86, code, mono=True, size=10)
        c.text(x + 100, 128, label, size=10.5, fill=col)
    c.line(222, 75, 258, 75, stroke="var(--wire)", arrow=True)
    c.line(462, 75, 498, 75, stroke="var(--wire)", arrow=True)
    c.rect(500, 150, 200, 44, fill="var(--panel)", stroke="var(--wire)")
    c.text(600, 172, "SessionRow: session: Session", mono=True, size=9.5)
    c.line(600, 112, 600, 148, stroke="var(--wire)", arrow=True)
    c.caption = T("The types are written where the data is born, and every reader after it gets them for free.",
                  "Os tipos são escritos onde os dados nascem, e todo leitor depois disso os recebe de graça.")
    return c


FIGURES = [("typed-refs", flow)]
