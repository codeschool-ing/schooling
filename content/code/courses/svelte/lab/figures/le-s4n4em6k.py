from fig import Canvas


def edges(T):
    c = Canvas(720, 280, T(
        "Two rows. At check time, svelte-check reads the TypeScript files and their types and reports mistakes in the "
        "code, before anything runs. At run time, the build has removed the types, and the JavaScript that runs "
        "receives values from outside, from a form or a JSON request. Those values have never been seen by the "
        "checker, so problemWith, a function that runs, checks them as they arrive.",
        "Duas linhas. Na hora da verificação, o svelte-check lê os arquivos TypeScript e os seus tipos e aponta erros "
        "no código, antes de qualquer coisa rodar. Na hora da execução, o build já tirou os tipos, e o JavaScript que "
        "roda recebe valores de fora, de um formulário ou de uma requisição JSON. O verificador nunca viu esses "
        "valores, então o problemWith, uma função que roda, os confere quando chegam."))
    c.text(20, 30, T("when svelte-check runs", "quando o svelte-check roda"), size=10.5, weight="600", anchor="start", fill="var(--amber)")
    c.rect(20, 44, 200, 50, fill="var(--panel)", stroke="var(--amber)")
    c.text(120, 62, "week.ts, +page.server.ts …", mono=True, size=9.5)
    c.text(120, 80, T("code with its types", "código com os seus tipos"), size=9.5, fill="var(--paper-dim)")
    c.line(220, 69, 278, 69, stroke="var(--paper-dim)", arrow=True)
    c.rect(280, 44, 200, 50, fill="var(--ink)", stroke="var(--amber)")
    c.text(380, 62, "svelte-check", mono=True, size=10, fill="var(--amber)")
    c.text(380, 80, T("mistakes in the code", "erros no código"), size=9.5)
    c.text(20, 140, T("when the planner runs", "quando o planner roda"), size=10.5, weight="600", anchor="start", fill="var(--phosphor)")
    c.rect(20, 154, 200, 50, fill="var(--panel)", stroke="var(--phosphor)")
    c.text(120, 172, T("the build: no types left", "o build: sem tipos"), size=9.5)
    c.text(120, 190, "build/", mono=True, size=9.5, fill="var(--paper-dim)")
    for k, (src, mono) in enumerate([(T("a form", "um formulário"), False), (T("a JSON request", "uma requisição JSON"), False)]):
        y = 150 + k * 40
        c.rect(520, y, 180, 28, fill="var(--ink)", stroke="var(--wire)", dash="4 3")
        c.text(610, y + 14, src, mono=mono, size=9.5)
        c.line(518, y + 14, 452, 182, stroke="var(--paper-dim)", arrow=True)
    c.rect(280, 154, 170, 50, fill="var(--ink)", stroke="var(--phosphor)")
    c.text(365, 172, "problemWith()", mono=True, size=10, fill="var(--phosphor)")
    c.text(365, 190, T("bad values, as they arrive", "valores ruins, ao chegar"), size=9.5)
    c.line(220, 179, 278, 179, stroke="var(--paper-dim)", arrow=True)
    c.text(360, 262, T("the checker never sees what comes from outside; a check that runs does",
                       "o verificador nunca vê o que vem de fora; uma checagem que roda vê"), size=10, fill="var(--paper-dim)")
    c.caption = T("Types find mistakes in the code before it runs. Values from outside arrive after the types are gone.",
                  "Os tipos acham erros no código antes de ele rodar. Os valores de fora chegam quando os tipos já não existem.")
    return c


FIGURES = [("runtime", edges)]
