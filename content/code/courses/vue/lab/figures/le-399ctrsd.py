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


FIGURES = [("nested", nesting)]
