from fig import Canvas


def two_ways(T):
    c = Canvas(720, 270, T(
        "The same planner reaching the browser two ways. On the left, npm run dev: the browser asks for main.ts, "
        "App.vue, HomeView.vue, planner.ts, the store and the rest one by one, thirty-three requests, and the dev "
        "server converts each file when it is asked for; only the dependencies, Vue, Pinia and Vue Router, were "
        "bundled ahead of time. On the right, npm run build: Rolldown reads the sixty-one modules once and writes "
        "dist, an index.html, one script, one stylesheet and the lazy chunks of the course routes. The week page "
        "then takes four requests: the page, the script, the stylesheet and the data.",
        "O mesmo planner chegando ao navegador de dois jeitos. À esquerda, npm run dev: o navegador pede main.ts, "
        "App.vue, HomeView.vue, planner.ts, a store e o resto um por um, trinta e três requisições, e o servidor de "
        "desenvolvimento converte cada arquivo quando ele é pedido; só as dependências, Vue, Pinia e Vue Router, "
        "foram empacotadas antes. À direita, npm run build: o Rolldown lê os sessenta e um módulos uma vez e "
        "escreve o dist, um index.html, um script, uma folha de estilo e os pedaços lazy das rotas do curso. A "
        "página da semana então leva quatro requisições: a página, o script, a folha de estilo e os dados."))
    # left: dev
    c.text(180, 18, "npm run dev", mono=True, size=12, weight="600", fill="var(--phosphor)")
    c.rect(110, 34, 140, 30, fill="var(--ink)", stroke="var(--phosphor)")
    c.text(180, 49, T("browser", "navegador"), size=11, fill="var(--phosphor)")
    files = ["main.ts", "App.vue", "HomeView.vue", "planner.ts", "stores/planner.ts", "router.ts",
             "SessionRow.vue", "deps/vue.js"]
    for i, name in enumerate(files):
        col, row = i % 2, i // 2
        x, y = 30 + col * 160, 100 + row * 34
        c.rect(x, y, 140, 24, fill="var(--panel)", stroke="var(--wire)")
        c.text(x + 70, y + 12, name, mono=True, size=9.5)
    c.line(180, 66, 180, 96, stroke="var(--phosphor)", arrow=True)
    c.text(180, 250, T("33 requests, each file converted when asked for",
                       "33 requisições, cada arquivo convertido quando é pedido"), size=10.5, fill="var(--phosphor)")
    c.line(360, 20, 360, 255, stroke="var(--scan)", dash="4 4")
    # right: build
    c.text(540, 18, "npm run build", mono=True, size=12, weight="600", fill="var(--amber)")
    c.rect(400, 40, 110, 64, fill="var(--panel)", stroke="var(--wire)")
    c.text(455, 62, "src/", mono=True, size=10.5)
    c.text(455, 84, T("61 modules", "61 módulos"), size=10)
    c.line(512, 72, 548, 72, stroke="var(--amber)", arrow=True)
    c.rect(550, 54, 140, 36, fill="var(--ink)", stroke="var(--amber)")
    c.text(620, 72, "Rolldown", mono=True, size=11, fill="var(--amber)")
    c.line(620, 92, 620, 116, stroke="var(--amber)", arrow=True)
    out = ["index.html", "assets/index-….js", "assets/index-….css", "assets/CourseView-….js"]
    for i, name in enumerate(out):
        y = 120 + i * 30
        c.rect(520, y, 170, 24, fill="var(--panel)", stroke="var(--amber)")
        c.text(605, y + 12, name, mono=True, size=9.5)
    c.text(540, 250, T("the week page: 4 requests", "a página da semana: 4 requisições"), size=10.5,
           fill="var(--amber)")
    c.caption = T("In development nothing is bundled but the dependencies; the build bundles everything once.",
                  "No desenvolvimento nada é empacotado além das dependências; o build empacota tudo uma vez.")
    return c


FIGURES = [("build", two_ways)]
