from fig import Canvas


def nesting(T):
    c = Canvas(720, 250, T(
        "The address /courses/spanish/all, split into its parts, and the boxes each part fills. App draws the "
        "header, the footer and a RouterView. The path /courses/spanish matches the course route, whose "
        "CourseView fills App's RouterView and has a RouterView of its own. The last segment, all, matches the "
        "child route, whose CourseAll fills CourseView's RouterView.",
        "O endereço /courses/spanish/all, dividido em partes, e as caixas que cada parte preenche. App desenha o "
        "cabeçalho, o rodapé e um RouterView. O caminho /courses/spanish casa com a rota do curso, cujo "
        "CourseView preenche o RouterView de App e tem um RouterView próprio. O último segmento, all, casa com a "
        "rota filha, cujo CourseAll preenche o RouterView de CourseView."))
    c.text(20, 22, "/courses/spanish", mono=True, size=13, anchor="start", fill="var(--phosphor)")
    c.text(156, 22, "/all", mono=True, size=13, anchor="start", fill="var(--amber)")
    c.rect(20, 40, 680, 200, fill="var(--panel)", stroke="var(--wire)")
    c.text(30, 56, T("App.vue: header and footer on every page", "App.vue: cabeçalho e rodapé em toda página"), anchor="start", size=10.5, fill="var(--paper-dim)")
    c.rect(40, 68, 640, 158, fill="var(--ink)", stroke="var(--phosphor)", dash="5 3")
    c.text(50, 84, "<RouterView>  →  CourseView", mono=True, size=10.5, anchor="start", fill="var(--phosphor)")
    c.text(50, 104, T("Spanish · goal: 120 minutes a week", "Spanish · meta: 120 minutos por semana"), anchor="start", size=10.5)
    c.rect(60, 120, 600, 92, fill="var(--panel)", stroke="var(--amber)", dash="5 3")
    c.text(70, 136, "<RouterView>  →  CourseAll", mono=True, size=10.5, anchor="start", fill="var(--amber)")
    c.text(70, 162, T("19 October 2026, Spanish, 30 minutes", "19 October 2026, Spanish, 30 minutes"), anchor="start", size=10.5)
    c.text(70, 184, T("23 October 2026, Spanish, 40 minutes", "23 October 2026, Spanish, 40 minutes"), anchor="start", size=10.5)
    c.caption = T("Each RouterView draws one level of the matched route: the parent's level inside App, the child's "
                  "inside the parent.",
                  "Cada RouterView desenha um nível da rota encontrada: o nível do pai dentro de App, o do filho "
                  "dentro do pai.")
    return c


def where_it_goes(T):
    c = Canvas(720, 240, T(
        "Three addresses on the left and where each one ends. /courses/spanish and /courses/latin both match the "
        "route /courses/:id, whose beforeEnter guard asks whether the course exists. For spanish it does, and the "
        "navigation continues to the course page. For latin it does not, and the guard returns the location of "
        "not-found, so the navigation is redirected to NotFound.vue, which keeps the path that was typed. "
        "/nowhere/at/all matches no route but the last, whose path matches everything, and lands on the same "
        "NotFound.vue.",
        "Três endereços à esquerda e onde cada um termina. /courses/spanish e /courses/latin casam com a rota "
        "/courses/:id, cujo guard beforeEnter pergunta se o curso existe. Para spanish existe, e a navegação segue "
        "para a página do curso. Para latin não existe, e o guard devolve a location de not-found, então a navegação "
        "é redirecionada para o NotFound.vue, que mantém o caminho digitado. /nowhere/at/all não casa com rota "
        "nenhuma além da última, cujo caminho casa com tudo, e chega ao mesmo NotFound.vue."))
    addrs = [(36, "/courses/spanish"), (96, "/courses/latin"), (176, "/nowhere/at/all")]
    for y, a in addrs:
        c.rect(20, y, 150, 30, fill="var(--panel)", stroke="var(--wire)")
        c.text(95, y + 15, a, mono=True, size=10)
    c.rect(220, 55, 130, 44, fill="var(--ink)", stroke="var(--wire)")
    c.text(285, 77, "/courses/:id", mono=True, size=10.5)
    c.rect(380, 50, 140, 54, fill="var(--ink)", stroke="var(--amber)")
    c.text(450, 67, "beforeEnter", mono=True, size=10.5, fill="var(--amber)")
    c.text(450, 87, T("does the course exist?", "o curso existe?"), size=10)
    c.rect(220, 170, 300, 42, fill="var(--ink)", stroke="var(--wire)", dash="4 3")
    c.text(370, 191, T("the last route: its path matches everything", "a última rota: o caminho dela casa com tudo"),
           size=10)
    c.rect(570, 24, 130, 36, fill="var(--phosphor-dim)", stroke="var(--phosphor)")
    c.text(635, 42, T("the course page", "a página do curso"), size=10.5)
    c.rect(570, 140, 130, 52, fill="var(--panel)", stroke="var(--amber)")
    c.text(635, 157, "NotFound.vue", mono=True, size=10.5, fill="var(--amber)")
    c.text(635, 176, T("keeps the typed path", "mantém o caminho digitado"), size=9.5)
    c.line(172, 51, 216, 68, stroke="var(--wire)", arrow=True)
    c.line(172, 111, 216, 88, stroke="var(--wire)", arrow=True)
    c.line(352, 77, 376, 77, stroke="var(--wire)", arrow=True)
    c.line(522, 60, 566, 44, stroke="var(--phosphor)", arrow=True)
    c.text(536, 40, T("yes", "sim"), size=9.5, fill="var(--phosphor)")
    c.line(522, 96, 590, 137, stroke="var(--amber)", arrow=True)
    c.text(548, 124, T("no: redirect", "não: redireciona"), size=9.5, fill="var(--amber)", anchor="end")
    c.line(172, 191, 216, 191, stroke="var(--wire)", arrow=True)
    c.line(522, 191, 566, 180, stroke="var(--wire)", arrow=True)
    c.caption = T("A guard's return value decides the navigation; an address no route takes ends on the same page.",
                  "O valor que o guard devolve decide a navegação; um endereço que nenhuma rota recebe acaba na mesma página.")
    return c


FIGURES = [("nested", nesting), ("guards", where_it_goes)]
