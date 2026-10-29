from fig import Canvas


def planner(T):
    c = Canvas(720, 330, T(
        "The study planner the four framework courses build. On the left, the first screen: the heading Study planner, "
        "the week of 19 October 2026 with buttons for the week before and after, three courses with their minutes this "
        "week (Linear algebra 150, Spanish 30, Guitar 45) and the week's total, 225 minutes. Choosing a course opens the "
        "screen on the right: Linear algebra's sessions, each with a date, a duration and a done box, and a form that adds "
        "a session with a date and a number of minutes. Underneath both, one JSON file holds three courses and six "
        "sessions.",
        "O planner de estudos que os quatro cursos de framework constroem. À esquerda, a primeira tela: o título Study "
        "planner, a semana de 19 de outubro de 2026 com botões para a semana anterior e a seguinte, três cursos com os "
        "seus minutos na semana (Linear algebra 150, Spanish 30, Guitar 45) e o total da semana, 225 minutos. Escolher um "
        "curso abre a tela da direita: as sessões de Linear algebra, cada uma com data, duração e uma caixa de feito, e "
        "um formulário que acrescenta uma sessão com data e número de minutos. Embaixo das duas, um arquivo JSON guarda "
        "três cursos e seis sessões."))
    # the first screen
    c.rect(20, 20, 300, 230, fill="var(--panel)", stroke="var(--wire)")
    c.text(36, 44, "Study planner", size=13, weight="600", anchor="start")
    c.text(170, 72, "‹   Week of 19 Oct 2026   ›", mono=True, size=10, fill="var(--paper-dim)")
    rows = [("Linear algebra", "150 min"), ("Spanish", "30 min"), ("Guitar", "45 min")]
    for i, (n, m) in enumerate(rows):
        y = 92 + i * 34
        c.rect(36, y, 268, 26, fill="var(--ink)", stroke="var(--phosphor)" if i == 0 else "var(--wire)")
        c.text(48, y + 13, n, size=10.5, anchor="start")
        c.text(292, y + 13, m, mono=True, size=10, anchor="end", fill="var(--paper-dim)")
    c.line(36, 202, 304, 202, stroke="var(--wire)")
    c.text(48, 222, T("this week", "esta semana"), size=10.5, anchor="start", fill="var(--paper-dim)")
    c.text(292, 222, "225 min", mono=True, size=11, anchor="end", fill="var(--amber)", weight="600")
    # the arrow
    c.line(304, 105, 398, 105, stroke="var(--phosphor)", arrow=True)
    c.text(351, 92, T("choose a course", "escolher um curso"), size=9.5, fill="var(--phosphor)")
    # the course screen
    c.rect(400, 20, 300, 230, fill="var(--panel)", stroke="var(--wire)")
    c.text(416, 44, "Linear algebra", size=13, weight="600", anchor="start")
    sess = [("2026-10-13", "60", True), ("2026-10-19", "90", True), ("2026-10-24", "60", False)]
    for i, (d, m, done) in enumerate(sess):
        y = 62 + i * 30
        c.rect(416, y, 268, 24, fill="var(--ink)", stroke="var(--wire)")
        c.text(428, y + 12, d, mono=True, size=10, anchor="start")
        c.text(560, y + 12, m + " min", mono=True, size=10, anchor="end", fill="var(--paper-dim)")
        c.rect(650, y + 6, 12, 12, fill="var(--phosphor)" if done else "var(--ink)", stroke="var(--phosphor)", rx=2)
    c.text(416, 168, T("add a session", "acrescentar uma sessão"), size=10, anchor="start", fill="var(--paper-dim)")
    c.rect(416, 180, 110, 24, fill="var(--ink)", stroke="var(--wire)")
    c.text(426, 192, T("date", "data"), size=9.5, anchor="start", fill="var(--paper-dim)")
    c.rect(534, 180, 70, 24, fill="var(--ink)", stroke="var(--wire)")
    c.text(544, 192, T("minutes", "minutos"), size=9.5, anchor="start", fill="var(--paper-dim)")
    c.rect(612, 180, 72, 24, fill="var(--ink)", stroke="var(--amber)")
    c.text(648, 192, T("Add", "Add"), size=10, fill="var(--amber)")
    c.text(684, 228, T("150 min this week", "150 min esta semana"), size=10, anchor="end", fill="var(--amber)")
    # the data
    c.rect(170, 280, 380, 34, fill="var(--ink)", stroke="var(--amber)", dash="4 3")
    c.text(360, 297, T("one JSON file: 3 courses, 6 sessions, October 2026",
                       "um arquivo JSON: 3 cursos, 6 sessões, outubro de 2026"), size=10.5, fill="var(--amber)")
    c.line(170, 280, 120, 252, stroke="var(--wire)", dash="3 3")
    c.line(550, 280, 600, 252, stroke="var(--wire)", dash="3 3")
    c.caption = T("The planner's two screens, and the one file behind both.",
                  "As duas telas do planner, e o único arquivo por trás das duas.")
    return c


def compiler(T):
    c = Canvas(720, 300, T(
        "One file, Counter.svelte, goes into the compiler and comes out as two programs. The client program has the "
        "markup as a template, minutes as a signal read with get and written with set, one effect that sets the text of "
        "the paragraph, and one delegated click listener. The server program has minutes as a plain variable and pushes "
        "one string of HTML with the value escaped. What neither has is a description of the page kept to compare with "
        "the next one.",
        "Um arquivo, Counter.svelte, entra no compilador e sai como dois programas. O programa do cliente tem a marcação "
        "como template, minutes como um signal lido com get e escrito com set, um efeito que define o texto do parágrafo "
        "e um listener de clique delegado. O programa do servidor tem minutes como uma variável comum e empurra uma "
        "string de HTML com o valor escapado. O que nenhum dos dois tem é uma descrição da página guardada para comparar "
        "com a próxima."))
    c.rect(20, 110, 150, 70, fill="var(--panel)", stroke="var(--wire)")
    c.text(95, 135, "Counter.svelte", mono=True, size=10.5)
    c.text(95, 158, T("what you write", "o que você escreve"), size=9.5, fill="var(--paper-dim)")
    c.line(170, 145, 218, 145, stroke="var(--paper-dim)", arrow=True)
    c.rect(220, 115, 110, 60, fill="var(--ink)", stroke="var(--amber)")
    c.text(275, 138, "compile()", mono=True, size=10.5, fill="var(--amber)")
    c.text(275, 158, T("on your computer", "no seu computador"), size=9, fill="var(--paper-dim)")
    c.path("M330 135 C 360 135, 360 70, 390 70", stroke="var(--phosphor)")
    c.line(388, 70, 396, 70, stroke="var(--phosphor)", arrow=True)
    c.path("M330 155 C 360 155, 360 225, 390 225", stroke="var(--phosphor)")
    c.line(388, 225, 396, 225, stroke="var(--phosphor)", arrow=True)
    c.rect(398, 18, 302, 118, fill="var(--panel)", stroke="var(--phosphor)")
    c.text(410, 36, T("client: runs in the browser", "cliente: roda no navegador"), size=10.5, anchor="start", weight="600", fill="var(--phosphor)")
    for i, s in enumerate(["$.from_html(`<button>…`)", "let minutes = $.state(0)", "$.template_effect(() => $.set_text(…))",
                           "$.delegated('click', button, …)"]):
        c.text(410, 60 + i * 20, s, mono=True, size=9.5, anchor="start")
    c.rect(398, 168, 302, 92, fill="var(--panel)", stroke="var(--phosphor)")
    c.text(410, 186, T("server: builds the HTML once", "servidor: monta o HTML uma vez"), size=10.5, anchor="start", weight="600", fill="var(--phosphor)")
    for i, s in enumerate(["let minutes = 0", "$$renderer.push(`<button>…", "  ${$.escape(minutes)}…`)"]):
        c.text(410, 210 + i * 20, s, mono=True, size=9.5, anchor="start")
    c.text(360, 284, T("neither keeps a copy of the page to compare with the next one",
                       "nenhum dos dois guarda uma cópia da página para comparar com a próxima"), size=10, fill="var(--amber)")
    c.caption = T("One component, two programs: a live one for the browser and a string builder for the server.",
                  "Um componente, dois programas: um vivo para o navegador e um montador de string para o servidor.")
    return c


FIGURES = [("what-svelte-is", planner), ("what-the-compiler-writes", compiler)]
