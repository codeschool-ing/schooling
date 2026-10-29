from fig import Canvas


def trees(T):
    c = Canvas(720, 330, T(
        "Four columns, one per meta-framework, each listing the files that make the planner's two addresses. "
        "Next.js: app/layout.tsx, app/page.tsx, app/courses/[slug]/page.tsx, and lib/plan.ts for the data. Nuxt: "
        "app/app.vue, app/pages/index.vue, app/pages/courses/[slug].vue, and server/api/plan.get.ts. SvelteKit: "
        "src/routes/+page.svelte and +page.server.ts, the same pair under courses/[slug], and src/lib/plan.ts. "
        "Angular: app.routes.ts with two paths, the components home.ts and course.ts, app.routes.server.ts, and "
        "plan.ts. Each column marks which file answers / and which answers /courses/git.",
        "Quatro colunas, uma por meta-framework, cada uma com os arquivos que fazem os dois endereços do planner. "
        "Next.js: app/layout.tsx, app/page.tsx, app/courses/[slug]/page.tsx, e lib/plan.ts para os dados. Nuxt: "
        "app/app.vue, app/pages/index.vue, app/pages/courses/[slug].vue, e server/api/plan.get.ts. SvelteKit: "
        "src/routes/+page.svelte e +page.server.ts, o mesmo par em courses/[slug], e src/lib/plan.ts. Angular: "
        "app.routes.ts com dois caminhos, os componentes home.ts e course.ts, app.routes.server.ts, e plan.ts. "
        "Cada coluna marca qual arquivo atende / e qual atende /courses/git."))
    cols = [
        ("Next.js", [("app/", 0, None), ("layout.tsx", 1, None), ("page.tsx", 1, "/"), ("courses/[slug]/", 1, None),
                     ("page.tsx", 2, "git"), ("lib/plan.ts", 0, "data")]),
        ("Nuxt", [("app/", 0, None), ("app.vue", 1, None), ("pages/index.vue", 1, "/"), ("pages/courses/", 1, None),
                  ("[slug].vue", 2, "git"), ("server/api/", 0, None), ("plan.get.ts", 1, "data")]),
        ("SvelteKit", [("src/routes/", 0, None), ("+page.svelte", 1, "/"), ("+page.server.ts", 1, "data"),
                       ("courses/[slug]/", 1, None), ("+page.svelte", 2, "git"), ("+page.server.ts", 2, "data"),
                       ("src/lib/plan.ts", 0, None)]),
        ("Angular", [("src/app/", 0, None), ("app.routes.ts", 1, None), ("  \"\" → Home", 2, "/"),
                     ("  courses/:slug → Course", 2, "git"), ("app.routes.server.ts", 1, None), ("plan.ts", 1, "data")]),
    ]
    w = 172
    for i, (name, rows) in enumerate(cols):
        x = 12 + i * (w + 6)
        c.rect(x, 20, w, 250, fill="var(--panel)", stroke="var(--wire)")
        c.text(x + w / 2, 40, name, size=12, weight="600")
        for j, (label, depth, mark) in enumerate(rows):
            y = 70 + j * 27
            colour = {"/": "var(--phosphor)", "git": "var(--amber)", "data": "var(--paper-dim)"}.get(mark, "var(--paper)")
            c.text(x + 10 + depth * 12, y, label.strip(), anchor="start", size=9.5, mono=True, fill=colour)
    c.rect(20, 290, 14, 14, fill="var(--ink)", stroke="var(--phosphor)")
    c.text(40, 297, T("answers /", "atende /"), anchor="start", size=10, fill="var(--phosphor)")
    c.rect(150, 290, 14, 14, fill="var(--ink)", stroke="var(--amber)")
    c.text(170, 297, T("answers /courses/git", "atende /courses/git"), anchor="start", size=10, fill="var(--amber)")
    c.rect(340, 290, 14, 14, fill="var(--ink)", stroke="var(--paper-dim)")
    c.text(360, 297, T("reads the data on the server", "lê os dados no servidor"), anchor="start", size=10,
           fill="var(--paper-dim)")
    c.caption = T("Three read the address from the folders; Angular reads it from a list. All four end with one file "
                  "per page and one place for the data.",
                  "Três leem o endereço das pastas; o Angular o lê de uma lista. Os quatro terminam com um arquivo por "
                  "página e um lugar para os dados.")
    return c


FIGURES = [
    ("routes-from-files", trees),
]


def weight(T):
    c = Canvas(720, 250, T(
        "A bar chart of the JavaScript each server's Git page ran in Chromium, uncompressed, as tools/weigh.ts "
        "measured it. Lesson 1's plain planner: 2.8 KB. SvelteKit: 89.1 KB. Nuxt: 195.8 KB. Angular: 264.2 KB. "
        "Next.js: 459.9 KB.",
        "Um gráfico de barras do JavaScript que a página do Git de cada servidor rodou no Chromium, sem compressão, "
        "como o tools/weigh.ts mediu. O planner puro da aula 1: 2,8 KB. SvelteKit: 89,1 KB. Nuxt: 195,8 KB. "
        "Angular: 264,2 KB. Next.js: 459,9 KB."))
    rows = [(T("plain planner", "planner puro"), 2.8, "2.8", "2,8"), ("SvelteKit", 89.1, "89.1", "89,1"),
            ("Nuxt", 195.8, "195.8", "195,8"), ("Angular", 264.2, "264.2", "264,2"), ("Next.js", 459.9, "459.9", "459,9")]
    x0, scale = 150, 480 / 459.9
    for i, (name, kb, en, pt) in enumerate(rows):
        y = 30 + i * 38
        c.text(x0 - 10, y + 12, name, anchor="end", size=11)
        c.rect(x0, y, max(kb * scale, 2), 24, fill="var(--ink)", stroke="var(--phosphor)", rx=2)
        c.text(x0 + max(kb * scale, 2) + 8, y + 12, T(en + " KB", pt + " KB"), anchor="start", size=10.5,
               fill="var(--paper-dim)")
    c.line(x0, 222, x0 + 490, 222, stroke="var(--wire)")
    c.text(x0, 238, T("JavaScript run by the Git page, uncompressed", "JavaScript rodado pela página do Git, sem compressão"),
           anchor="start", size=10, fill="var(--paper-dim)")
    c.caption = T("The same page, with the same HTML in its first response, and five very different amounts of code "
                  "to run once it has arrived.",
                  "A mesma página, com o mesmo HTML na primeira resposta, e cinco quantidades muito diferentes de "
                  "código para rodar depois que ela chegou.")
    return c


FIGURES.append(("the-same-page", weight))
