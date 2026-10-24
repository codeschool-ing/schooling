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


FIGURES = [("planner-in-nuxt", flow)]
