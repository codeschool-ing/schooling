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


def fake_clock(T):
    c = Canvas(720, 222, T(
        "The second test of the week page, on the clock the test sets, from left to right. useFakeTimers sets the "
        "clock to 21 October 2026 at ten in the morning. flushPromises waits for the store's load and the redraw "
        "after it, and li.today contains 21 October 2026. setSystemTime moves the clock to 00:00:30 on 22 October. "
        "advanceTimersByTimeAsync lets a minute pass at once, the page's minute timer runs, and li.today contains "
        "22 October 2026. The whole file ran in about a tenth of a second.",
        "O segundo teste da página da semana, no relógio que o teste define, da esquerda para a direita. "
        "useFakeTimers põe o relógio em 21 de outubro de 2026, às dez da manhã. flushPromises espera o load da store "
        "e o redesenho depois dele, e li.today contém 21 October 2026. setSystemTime move o relógio para 00:00:30 de "
        "22 de outubro. advanceTimersByTimeAsync deixa passar um minuto de uma vez, o timer de minuto da página roda, "
        "e li.today contém 22 October 2026. O arquivo inteiro rodou em cerca de um décimo de segundo."))
    c.line(20, 120, 705, 120, stroke="var(--wire)", arrow=True)
    steps = [(25, 30, "useFakeTimers", T("21 Oct 2026, 10:00", "21 out 2026, 10:00"), "var(--amber)"),
             (195, 150, "flushPromises()", T("load done, page drawn", "load pronto, página desenhada"), "var(--wire)"),
             (365, 30, "setSystemTime", T("22 Oct, 00:00:30", "22 out, 00:00:30"), "var(--amber)"),
             (535, 150, "advanceTimersByTimeAsync", T("a minute passes at once", "um minuto passa de uma vez"),
              "var(--wire)")]
    for x, y, code, note, col in steps:
        c.rect(x, y, 165, 48, fill="var(--ink)", stroke=col)
        c.text(x + 82, y + 16, code, mono=True, size=9.5, fill="var(--amber)" if col == "var(--amber)" else "var(--paper)")
        c.text(x + 82, y + 34, note, size=9.5)
        c.line(x + 12, y + 48 if y < 120 else y, x + 12, 122 if y < 120 else 118, stroke=col)
    c.text(355, 104, "li.today: 21 October 2026", mono=True, size=9.5, anchor="end", fill="var(--phosphor)")
    c.text(702, 104, "li.today: 22 October 2026", mono=True, size=9.5, anchor="end", fill="var(--phosphor)")
    c.text(20, 210, T("the test's clock: midnight in about a tenth of a second", "o relógio do teste: meia-noite em cerca de um décimo de segundo"),
           size=9.5, anchor="start", fill="var(--paper-dim)")
    c.caption = T("The test sets the clock and lets time pass; every wait names what it waits for.",
                  "O teste define o relógio e deixa o tempo passar; cada espera diz pelo que espera.")
    return c


FIGURES = [("what-to-test", heights), ("async", fake_clock)]
