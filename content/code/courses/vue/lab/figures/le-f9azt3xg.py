from fig import Canvas


def flow(T):
    c = Canvas(720, 250, T(
        "Where the Nuxt planner's data lives. When the server starts, server/utils/planner-data.ts copies "
        "server/data/courses.json into memory. The week page asks GET /api/courses with useFetch and draws "
        "what comes back; ticking a session sends PATCH /api/sessions/s4, which changes the copy in memory, and "
        "the page then refreshes. A second browser asking GET /api/courses gets the same copy. Restarting the "
        "server copies courses.json again.",
        "Onde ficam os dados do planner em Nuxt. Quando o servidor inicia, o server/utils/planner-data.ts copia o "
        "server/data/courses.json para a memória. A página da semana pede GET /api/courses com o useFetch e "
        "desenha o que volta; marcar uma sessão envia PATCH /api/sessions/s4, que muda a cópia na memória, e "
        "a página então atualiza. Um segundo navegador que pede GET /api/courses recebe a mesma cópia. Reiniciar "
        "o servidor copia o courses.json de novo."))
    # browsers
    c.rect(20, 40, 190, 70, fill="var(--ink)", stroke="var(--phosphor)")
    c.text(115, 60, T("browser", "navegador"), size=11, fill="var(--phosphor)")
    c.text(115, 86, "pages/index.vue", mono=True, size=10)
    c.rect(20, 160, 190, 50, fill="var(--ink)", stroke="var(--wire)")
    c.text(115, 185, T("another browser", "outro navegador"), size=11)
    # server
    c.rect(270, 25, 270, 200, fill="var(--panel)", stroke="var(--amber)", dash="5 4")
    c.text(405, 42, T("Nitro, the server", "Nitro, o servidor"), size=11, fill="var(--amber)")
    c.rect(290, 60, 230, 30, fill="var(--ink)", stroke="var(--wire)")
    c.text(405, 75, "api/courses.get.ts", mono=True, size=10)
    c.rect(290, 100, 230, 30, fill="var(--ink)", stroke="var(--wire)")
    c.text(405, 115, "api/sessions/[id].patch.ts", mono=True, size=10)
    c.rect(290, 160, 230, 46, fill="var(--ink)", stroke="var(--amber)")
    c.text(405, 176, "planner", mono=True, size=11, weight="600", fill="var(--amber)")
    c.text(405, 194, T("the copy in memory", "a cópia na memória"), size=10)
    c.line(405, 92, 405, 98, stroke="var(--wire)")
    c.line(520, 115, 540, 115, stroke="var(--wire)")
    c.line(540, 75, 540, 183, stroke="var(--wire)")
    c.line(540, 75, 522, 75, stroke="var(--wire)", arrow=True)
    c.line(540, 183, 522, 183, stroke="var(--wire)", arrow=True)
    # file
    c.rect(580, 160, 125, 46, fill="var(--panel)", stroke="var(--wire)")
    c.text(642, 176, "courses.json", mono=True, size=10)
    c.text(642, 194, T("read at start", "lido ao iniciar"), size=10)
    c.line(578, 183, 524, 183, stroke="var(--amber)", arrow=True)
    # requests
    c.line(212, 66, 288, 66, stroke="var(--phosphor)", arrow=True)
    c.text(250, 56, "GET", mono=True, size=9.5, fill="var(--phosphor)")
    c.line(212, 106, 288, 106, stroke="var(--phosphor)", arrow=True)
    c.text(250, 96, "PATCH", mono=True, size=9.5, fill="var(--phosphor)")
    c.line(212, 180, 288, 80, stroke="var(--wire)", arrow=True, dash="3 3")
    c.caption = T("Every browser reads the server's one copy, and a restart starts it again from the file.",
                  "Todo navegador lê a única cópia do servidor, e reiniciar recomeça a partir do arquivo.")
    return c


def files_to_routes(T):
    c = Canvas(720, 245, T(
        "Files in app/pages on the left and the addresses they become on the right. index.vue is the route /. "
        "about.vue, dashed because the planner has none, would be /about. courses/[id].vue is /courses/:id, the "
        "square brackets making id a parameter, and it answers /courses/statistics, /courses/spanish and so on. "
        "Below, /courses/spanish/extra has no file, so there is no page, and the server answers with a real 404.",
        "Arquivos em app/pages à esquerda e os endereços que eles viram à direita. index.vue é a rota /. about.vue, "
        "tracejado porque o planner não tem um, seria /about. courses/[id].vue é /courses/:id, com os colchetes "
        "fazendo de id um parâmetro, e ele responde a /courses/statistics, /courses/spanish e assim por diante. "
        "Embaixo, /courses/spanish/extra não tem arquivo, então não há página, e o servidor responde com um 404 de "
        "verdade."))
    c.text(130, 18, "app/pages/", mono=True, size=11, fill="var(--amber)")
    c.text(405, 18, T("the route", "a rota"), size=10.5, fill="var(--paper-dim)")
    rows = [(36, "index.vue", "/", False), (86, "about.vue", "/about", True), (136, "courses/[id].vue", "/courses/:id", False)]
    for y, f, r, dashed in rows:
        d = "4 3" if dashed else None
        col = "var(--paper-dim)" if dashed else "var(--paper)"
        c.rect(40, y, 180, 32, fill="var(--panel)", stroke="var(--wire)", dash=d)
        c.text(130, y + 16, f, mono=True, size=10.5, fill=col)
        c.rect(330, y, 150, 32, fill="var(--ink)", stroke="var(--wire)" if dashed else "var(--phosphor)", dash=d)
        c.text(405, y + 16, r, mono=True, size=10.5, fill=col if dashed else "var(--phosphor)")
        c.line(222, y + 16, 326, y + 16, stroke="var(--wire)", dash=d, arrow=True)
    c.text(274, 92, T("would be", "seria"), size=9.5, fill="var(--paper-dim)")
    for i, ex in enumerate(["/courses/statistics", "/courses/spanish"]):
        y = 118 + i * 40
        c.rect(540, y, 160, 28, fill="var(--panel)", stroke="var(--wire)")
        c.text(620, y + 14, ex, mono=True, size=10)
        c.line(482, 152, 536, y + 14, stroke="var(--wire)", arrow=True)
    c.text(130, 218, T("no file for it", "nenhum arquivo para ele"), size=10, fill="var(--paper-dim)")
    c.rect(300, 204, 180, 28, fill="var(--ink)", stroke="var(--amber)", dash="4 3")
    c.text(390, 218, "/courses/spanish/extra", mono=True, size=10, fill="var(--amber)")
    c.line(482, 218, 526, 218, stroke="var(--amber)", arrow=True)
    c.rect(530, 204, 170, 28, fill="var(--ink)", stroke="var(--amber)")
    c.text(615, 218, T("404 from the server", "404 do servidor"), size=10, fill="var(--amber)")
    c.caption = T("A file's path in pages/ is its address; square brackets make a parameter.",
                  "O caminho de um arquivo em pages/ é o seu endereço; colchetes fazem um parâmetro.")
    return c


FIGURES = [("planner-in-nuxt", flow), ("pages", files_to_routes)]
