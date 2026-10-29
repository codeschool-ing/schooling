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


def inference(T):
    c = Canvas(720, 220, T(
        "How T is decided in the TypedPicker demo. On the left, the parent passes :items equal to courses, a Course "
        "array. In the middle, T becomes Course. On the right, the three places TypedList wrote T: items, a T array, "
        "is a Course array; the event pick, with an item of type T, hands the listener a Course, so course.goal is "
        "a number; and the slot's item is a Course, so item.title is a string. Each is checked against Course.",
        "Como T é decidido na demo TypedPicker. À esquerda, o pai passa :items igual a courses, um array de Course. "
        "No meio, T vira Course. À direita, os três lugares onde o TypedList escreveu T: items, um array de T, é um "
        "array de Course; o evento pick, com um item do tipo T, entrega ao listener um Course, então course.goal é "
        "um number; e o item do slot é um Course, então item.title é uma string. Cada um é verificado contra "
        "Course."))
    c.text(110, 60, T("the parent passes", "o pai passa"), size=10.5, fill="var(--paper-dim)")
    c.rect(20, 76, 180, 60, fill="var(--panel)", stroke="var(--wire)")
    c.text(110, 96, ':items="courses"', mono=True, size=10.5)
    c.text(110, 118, "Course[]", mono=True, size=10.5, fill="var(--amber)")
    c.line(202, 106, 256, 106, stroke="var(--amber)", arrow=True)
    c.rect(260, 82, 140, 48, fill="var(--ink)", stroke="var(--amber)")
    c.text(330, 106, "T = Course", mono=True, size=12, weight="600", fill="var(--amber)")
    c.text(585, 16, T("where TypedList wrote T", "onde o TypedList escreveu T"), size=10.5, fill="var(--paper-dim)")
    rows = [(30, "items: T[]", "Course[]"), (95, "pick: [item: T]", "course.goal: number"),
            (160, '<slot :item="item">', "item.title: string")]
    for y, decl, got in rows:
        c.rect(470, y, 230, 46, fill="var(--ink)", stroke="var(--phosphor)")
        c.text(585, y + 15, decl, mono=True, size=10)
        c.text(585, y + 33, got, mono=True, size=10, fill="var(--phosphor)")
        c.line(402, 106, 466, y + 23, stroke="var(--phosphor)", arrow=True)
    c.caption = T("Nothing in the picker names a type; T is read off the items it was given.",
                  "Nada no picker nomeia um tipo; T é lido dos itens que ele recebeu.")
    return c


FIGURES = [("typed-refs", flow), ("generic-components", inference)]
