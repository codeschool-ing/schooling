from fig import Canvas


def heights(T):
    c = Canvas(720, 230, T(
        "What each kind of test in the planner touches. A test of planner.ts gives a function a value and "
        "reads the answer, and touches nothing else. A test of SessionRow or SessionForm mounts the component "
        "in jsdom with a fresh Pinia store. A test of the store or of the week page also replaces fetch with "
        "an answer the test chooses, and the week page's test replaces the clock too. The further down, the "
        "more each test sets up, and the fewer of them the planner has.",
        "O que cada tipo de teste do planner toca. Um teste do planner.ts dá um valor a uma função e lê a "
        "resposta, e não toca em mais nada. Um teste do SessionRow ou do SessionForm monta o componente no "
        "jsdom com uma store Pinia nova. Um teste da store ou da página da semana também troca o fetch por "
        "uma resposta que o teste escolhe, e o teste da página da semana troca o relógio também. Quanto mais "
        "abaixo, mais cada teste prepara, e menos deles o planner tem."))
    rows = [
        ("planner.test.ts", "7", [("planner.ts", "var(--phosphor)")]),
        ("SessionRow / SessionForm", "7", [(T("component", "componente"), "var(--phosphor)"), ("jsdom", "var(--wire)"),
                                          ("Pinia", "var(--wire)")]),
        ("planner / HomeView", "6", [(T("store, page", "store, página"), "var(--phosphor)"), ("jsdom", "var(--wire)"),
                                     ("Pinia", "var(--wire)"), (T("fake fetch", "fetch falso"), "var(--amber)"),
                                     (T("fake clock", "relógio falso"), "var(--amber)")]),
    ]
    for i, (name, n, parts) in enumerate(rows):
        y = 30 + i * 62
        c.text(20, y + 18, name, mono=True, size=10.5, anchor="start")
        c.text(215, y + 18, n, mono=True, size=13, weight="600", fill="var(--amber)")
        x = 250
        for label, col in parts:
            c.rect(x, y, 86, 36, fill="var(--ink)", stroke=col)
            c.text(x + 43, y + 18, label, size=10)
            x += 92
    c.text(215, 216, T("tests", "testes"), size=10)
    c.caption = T("The cheapest tests touch the least, and the planner has the most of them.",
                  "Os testes mais baratos tocam o mínimo, e o planner tem mais deles.")
    return c


FIGURES = [("what-to-test", heights)]
