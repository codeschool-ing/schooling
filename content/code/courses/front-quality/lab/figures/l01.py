"""Lesson 1: the two figures, and the annotated planner.ts and view.ts."""
from fig import Fig

PLANNER = [
    ("// src/planner.ts\nexport interface Course {\n  id: string;\n  title: string;\n}\n\nexport interface Session {\n  id: number;\n  course: string;\n  date: string;\n  minutes: number;\n  done: boolean;\n}\n\nexport interface Plan {\n  courses: Course[];\n  sessions: Session[];\n}\n",
     "Three shapes, and they are the whole of the data. A session names its course by the course's `id`, and its date is a string like `2026-10-21`, the way `courses.json` writes it.",
     "Três formatos, e eles são todos os dados. Uma sessão aponta para o curso pelo `id` dele, e a data é um texto como `2026-10-21`, do jeito que o `courses.json` escreve."),
    ("export function addSession(plan: Plan, course: string, date: string, minutes: number): Plan {\n  if (!plan.courses.some((c) => c.id === course)) throw new Error(`no course ${course}`);\n  if (!/^\\d{4}-\\d{2}-\\d{2}$/.test(date)) throw new Error(`not a date: ${date}`);\n  if (!Number.isInteger(minutes) || minutes < 1 || minutes > 600) {\n    throw new Error(`minutes must be a whole number from 1 to 600, not ${minutes}`);\n  }\n  const id = Math.max(0, ...plan.sessions.map((s) => s.id)) + 1;\n  return { ...plan, sessions: [...plan.sessions, { id, course, date, minutes, done: false }] };\n}\n",
     "Adding a session refuses what it cannot store, and says which value it refused. It never changes the plan it was given: it returns a new one with the session on the end.",
     "Adicionar uma sessão recusa o que não dá para guardar, e diz qual valor recusou. A função nunca altera o plano que recebeu: devolve um novo, com a sessão no fim."),
    ("export function markDone(plan: Plan, id: number): Plan {\n  return { ...plan, sessions: plan.sessions.map((s) => (s.id === id ? { ...s, done: true } : s)) };\n}\n",
     "The same habit: a new plan, in which one session is done.",
     "O mesmo hábito: um plano novo, em que uma sessão está feita."),
    ("export function today(now: Date = new Date()): string {\n  const m = String(now.getMonth() + 1).padStart(2, \"0\");\n  const d = String(now.getDate()).padStart(2, \"0\");\n  return `${now.getFullYear()}-${m}-${d}`;\n}\n",
     "Today's date on the student's own calendar, in the same shape as a session's. `getMonth()` counts from 0, hence the `+ 1`.",
     "A data de hoje no calendário do próprio estudante, no mesmo formato da data de uma sessão. O `getMonth()` conta a partir de 0, daí o `+ 1`."),
    ("export function weekOf(day: string): [string, string] {\n  const d = new Date(day);\n  const monday = new Date(d);\n  monday.setDate(d.getDate() - ((d.getDay() + 6) % 7));\n  const sunday = new Date(monday);\n  sunday.setDate(monday.getDate() + 6);\n  return [monday.toISOString().slice(0, 10), sunday.toISOString().slice(0, 10)];\n}\n",
     "The week a day belongs to, Monday to Sunday. `getDay()` says 0 for Sunday and 1 for Monday, so `(getDay() + 6) % 7` is how many days ago Monday was.",
     "A semana a que um dia pertence, de segunda a domingo. O `getDay()` dá 0 para domingo e 1 para segunda, então `(getDay() + 6) % 7` é quantos dias atrás foi a segunda."),
    ("export function weekTotal(plan: Plan, day: string, course?: string): number {\n  const [from, to] = weekOf(day);\n  return plan.sessions\n    .filter((s) => s.date >= from && s.date <= to)\n    .filter((s) => course === undefined || s.course === course)\n    .reduce((sum, s) => sum + s.minutes, 0);\n}",
     "The minutes planned in that week, for every course or for one. Dates written as `YYYY-MM-DD` sort as text in the same order as on a calendar, which is why `>=` and `<=` work on them.",
     "Os minutos planejados naquela semana, de todos os cursos ou de um só. Datas escritas como `YYYY-MM-DD` ficam, em ordem de texto, na mesma ordem do calendário, e é por isso que `>=` e `<=` funcionam com elas."),
]

VIEW = [
    ("// src/view.ts\nimport { addSession, markDone, weekTotal, type Plan } from \"./planner\";\n\nexport function render(root: HTMLElement, plan: Plan, day: string, route: string, update: (next: Plan) => void): void {\n  const course = plan.courses.find((c) => route === `#/course/${c.id}`);\n  root.replaceChildren();",
     "One function draws the whole screen into `root`, from the plan, today's date and the address after `#`. When something changes it does not touch the plan itself: it hands a new plan to `update`, and whoever called it draws again.",
     "Uma função desenha a tela inteira dentro de `root`, a partir do plano, da data de hoje e do endereço depois do `#`. Quando algo muda, ela não mexe no plano: entrega um plano novo a `update`, e quem a chamou desenha de novo."),
    ("  if (!course) {\n    root.append(el(\"h1\", \"Study planner\"));\n    const list = el(\"ul\", \"\", \"courses\");\n    for (const c of plan.courses) {\n      const link = el(\"a\", c.title);\n      link.href = `#/course/${c.id}`;\n      const icon = el(\"img\");\n      icon.src = \"/book.svg\";\n      link.prepend(icon);\n      const item = el(\"li\");\n      item.append(link, el(\"span\", ` ${weekTotal(plan, day, c.id)} min this week`, \"mins\"));\n      list.append(item);\n    }\n    root.append(list, el(\"p\", `This week: ${weekTotal(plan, day)} min`, \"week\"));\n    return;\n  }",
     "No course in the address: the list of courses, each a link to its own page with a small book in front of it, and the week's total for everything at the bottom.",
     "Nenhum curso no endereço: a lista de cursos, cada um com um link para a própria página e um livrinho na frente, e o total da semana de tudo no fim."),
    ("  const back = el(\"a\", \"←\", \"back\");\n  back.href = \"#/\";\n  root.append(back, el(\"h1\", course.title));\n  const list = el(\"ul\", \"\", \"sessions\");\n  for (const s of plan.sessions.filter((s) => s.course === course.id)) {\n    const item = el(\"li\", `${s.date} · ${s.minutes} min `, s.done ? \"session done\" : \"session\");\n    if (s.done) {\n      item.append(el(\"span\", \"done\", \"state\"));\n    } else {\n      const tick = el(\"button\", \"Done\", \"tick\");\n      tick.addEventListener(\"click\", () => update(markDone(plan, s.id)));\n      item.append(tick);\n    }\n    list.append(item);\n  }",
     "A course's page: an arrow back to the list, the title, and its sessions. A session still to do carries a Done button; one already done says so.",
     "A página de um curso: uma seta de volta para a lista, o título e as sessões dele. Uma sessão por fazer tem um botão Done; uma já feita diz que está feita."),
    ("  const form = el(\"form\", \"\", \"add\");\n  form.innerHTML = `<input name=\"date\" type=\"date\" placeholder=\"Date\">\n    <input name=\"minutes\" type=\"number\" placeholder=\"Minutes\">\n    <button>Add session</button>`;\n  form.addEventListener(\"submit\", (event) => {\n    event.preventDefault();\n    const data = new FormData(form);\n    update(addSession(plan, course.id, String(data.get(\"date\")), Number(data.get(\"minutes\"))));\n  });\n  root.append(list, form, el(\"p\", `This week: ${weekTotal(plan, day, course.id)} min`, \"week\"));\n}\n",
     "The form that adds a session, and the course's total for the week. `preventDefault()` keeps the browser from sending the form anywhere; `FormData` reads the two fields by their `name`.",
     "O formulário que adiciona uma sessão, e o total do curso na semana. O `preventDefault()` impede o navegador de enviar o formulário para algum lugar; o `FormData` lê os dois campos pelo `name`."),
    ("function el<K extends keyof HTMLElementTagNameMap>(tag: K, text = \"\", cls = \"\"): HTMLElementTagNameMap[K] {\n  const e = document.createElement(tag);\n  e.textContent = text;\n  if (cls) e.className = cls;\n  return e;\n}",
     "A small helper: an element, its text and its class in one call. The type parameter makes `el(\"a\")` an `HTMLAnchorElement`, so `link.href` type-checks.",
     "Um ajudante pequeno: um elemento, o texto e a classe numa chamada só. O parâmetro de tipo faz de `el(\"a\")` um `HTMLAnchorElement`, e por isso `link.href` passa na checagem de tipos."),
]

EXAMPLES = {
    "the-planner": [{"language": "typescript", "file": "src/planner.ts", "parts": PLANNER}],
    "the-page": [{"language": "typescript", "file": "src/view.ts", "parts": VIEW}],
}

T = {
    "en": dict(
        pyr_aria="Two shapes side by side. On the left, the testing pyramid: a wide base of unit tests, a narrower band of integration tests above it, and a small tip of end-to-end tests. On the right, the testing trophy: a thin base of static checks, a small band of unit tests, a wide band of integration tests, and a small top of end-to-end tests. An arrow beside them says that towards the top a test is slower, costs more to keep and gives more confidence that the whole works; towards the bottom it is faster, cheaper and closer to the line that broke.",
        pyramid="the pyramid", trophy="the trophy",
        layers_p=["end-to-end", "integration", "unit"],
        layers_t=["end-to-end", "integration", "unit", "static"],
        up=["slower, dearer to keep,", "more confidence in the whole"],
        down=["faster, cheaper,", "closer to the broken line"],
        pyr_cap="Cohn's pyramid (2009) and Dodds's trophy (2018) agree on the axis and disagree on where most tests should sit. For a front-end, the trophy's wide middle is where the bugs the user sees are.",
        lay_aria="The study planner's files, and which kind of test reaches each. tsc, the static layer, reads every TypeScript file without running any of it. Vitest in Node runs planner.ts on its own: unit tests, lesson 2. Vitest with a simulated DOM, jsdom, runs view.ts together with planner.ts: component tests, lessons 2 and 3. Playwright drives a real Chromium against Vite's dev server, which serves index.html, main.ts, style.css and courses.json as well: end-to-end tests, lesson 4.",
        h_layer="layer", h_runs="what runs", h_lesson="lesson",
        rows=[("static", "tsc reads every .ts file, runs none", "1"),
              ("unit", "Vitest, Node: planner.ts alone", "2"),
              ("component", "Vitest, jsdom: view.ts and planner.ts", "2, 3"),
              ("end-to-end", "Playwright, Chromium, Vite: all of it", "4")],
        files_h="the planner's files",
        lay_cap="Each layer adds what the one below leaves out. Only the last one has CSS, the network and a real browser in it, and only the first one costs nothing to run.",
    ),
    "pt": dict(
        pyr_aria="Duas formas lado a lado. À esquerda, a pirâmide de testes: uma base larga de testes unitários, uma faixa mais estreita de testes de integração acima dela e uma ponta pequena de testes de ponta a ponta. À direita, o troféu de testes: uma base fina de checagens estáticas, uma faixa pequena de testes unitários, uma faixa larga de testes de integração e um topo pequeno de testes de ponta a ponta. Uma seta ao lado diz que, quanto mais perto do topo, mais lento é o teste, mais custa mantê-lo e mais confiança ele dá de que o todo funciona; quanto mais perto da base, mais rápido, mais barato e mais perto da linha que quebrou.",
        pyramid="a pirâmide", trophy="o troféu",
        layers_p=["ponta a ponta", "integração", "unitário"],
        layers_t=["ponta a ponta", "integração", "unitário", "estático"],
        up=["mais lento, mais caro de manter,", "mais confiança no todo"],
        down=["mais rápido, mais barato,", "mais perto da linha quebrada"],
        pyr_cap="A pirâmide de Cohn (2009) e o troféu de Dodds (2018) concordam no eixo e discordam sobre onde deve ficar a maioria dos testes. Num front-end, o meio largo do troféu é onde estão os defeitos que o usuário vê.",
        lay_aria="Os arquivos do planner de estudos, e que tipo de teste alcança cada um. O tsc, a camada estática, lê todos os arquivos TypeScript sem executar nenhum. O Vitest no Node executa o planner.ts sozinho: testes unitários, aula 2. O Vitest com um DOM simulado, o jsdom, executa o view.ts junto com o planner.ts: testes de componente, aulas 2 e 3. O Playwright controla um Chromium de verdade contra o servidor de desenvolvimento do Vite, que também serve o index.html, o main.ts, o style.css e o courses.json: testes de ponta a ponta, aula 4.",
        h_layer="camada", h_runs="o que executa", h_lesson="aula",
        rows=[("estática", "o tsc lê cada .ts e não executa nenhum", "1"),
              ("unitária", "Vitest, Node: só o planner.ts", "2"),
              ("componente", "Vitest, jsdom: view.ts e planner.ts", "2, 3"),
              ("ponta a ponta", "Playwright, Chromium, Vite: tudo", "4")],
        files_h="os arquivos do planner",
        lay_cap="Cada camada acrescenta o que a de baixo deixa de fora. Só a última tem CSS, rede e um navegador de verdade, e só a primeira não custa nada para rodar.",
    ),
}


def figures(lang):
    t = T[lang]
    out = {}
    f = Fig("l01-shapes", 720, 290, t["pyr_aria"])
    # the pyramid: three bands, widest at the bottom
    cx, top, h = 150, 40, 60
    widths = [(84, "phosphor"), (172, "wire"), (260, "wire")]
    for i, (name, (w, stroke)) in enumerate(zip(t["layers_p"], widths)):
        y0 = top + i * h
        wt = 0 if i == 0 else widths[i - 1][0]
        f.poly([(cx - wt / 2, y0), (cx + wt / 2, y0), (cx + w / 2, y0 + h), (cx - w / 2, y0 + h)],
               stroke=stroke)
        f.text(cx, y0 + h / 2 + (12 if i == 0 else 0), name, size=9 if i == 0 else 10)
    f.text(cx, 270, t["pyramid"], bold=True)
    # the trophy: top cup band, wide integration, narrow unit, thin static base
    tx = 470
    bands = [(130, 40, 46, "wire"), (210, 86, 88, "phosphor"), (110, 174, 40, "wire"), (180, 214, 30, "wire")]
    for (w, y, hh, stroke), name in zip(bands, t["layers_t"]):
        f.rect(tx - w / 2, y, w, hh, stroke=stroke)
        f.text(tx, y + hh / 2, name, size=10 if hh > 30 else 9.5)
    f.text(tx, 270, t["trophy"], bold=True)
    # the axis
    ax = 640
    f.arrow([(ax, 230), (ax, 50)], color="amber", both=True)
    for i, s in enumerate(t["up"]):
        f.text(ax - 6, 22 + i * 12, s, anchor="end", size=9, fill="paper-dim")
    for i, s in enumerate(t["down"]):
        f.text(ax - 6, 248 + i * 12, s, anchor="end", size=9, fill="paper-dim")
    out["l01-shapes"] = f.json(t["pyr_cap"])

    f = Fig("l01-layers", 760, 250, t["lay_aria"])
    f.text(20, 22, t["h_layer"], anchor="start", bold=True, size=9.5)
    f.text(140, 22, t["h_runs"], anchor="start", bold=True, size=9.5)
    f.text(722, 22, t["h_lesson"], anchor="middle", bold=True, size=9.5)
    files = ["planner.ts", "view.ts", "main.ts", "style.css", "index.html", "courses.json"]
    # columns of files on the right of each row: which files the layer reaches
    reach = [[1, 1, 1, 0, 0, 0], [1, 0, 0, 0, 0, 0], [1, 1, 0, 0, 0, 0], [1, 1, 1, 1, 1, 1]]
    fx = [392 + i * 58 for i in range(6)]
    f.text((fx[0] + fx[5]) / 2, 22, t["files_h"], bold=True, size=9.5)
    for i, name in enumerate(files):
        f.text(fx[i], 44, name, mono=True, size=7.5, fill="paper-dim")
    for r, ((layer, runs, lesson), hits) in enumerate(zip(t["rows"], reach)):
        y = 60 + r * 44
        stroke = "amber" if r == 3 else "wire"
        f.box(14, y, 110, 34, [layer], stroke=stroke, bold=True, size=9.5)
        f.text(140, y + 17, runs, anchor="start", size=9.5)
        for i, hit in enumerate(hits):
            if hit:
                f.rect(fx[i] - 15, y + 7, 30, 20, stroke="phosphor", fill="panel", width=1.2)
            else:
                f.rect(fx[i] - 15, y + 7, 30, 20, stroke="wire", fill="ink", width=0.8, dashed=True)
        f.text(722, y + 17, lesson, mono=True, size=10)
    out["l01-layers"] = f.json(t["lay_cap"])
    return out
