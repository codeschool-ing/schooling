from fig import Canvas


def nested(T):
    c = Canvas(720, 330, T(
        "On the left, the planner's routes as files: the root layout and error page; a (planner) group with its own "
        "layout, the week page at / and the course page at /courses/ followed by a slug; and an (info) group with the "
        "About page. On the right, the same routes as nested components. The root layout wraps everything. Inside it, "
        "the (planner) layout wraps the provider, which holds the planner, which wraps the page. Moving between the week "
        "and a course replaces only the page. Going to About replaces the (planner) layout and everything in it, the "
        "planner included.",
        "À esquerda, as rotas do planner como arquivos: o layout raiz e a página de erro; um grupo (planner) com o seu "
        "próprio layout, a página da semana em / e a página do curso em /courses/ seguido de um slug; e um grupo (info) "
        "com a página About. À direita, as mesmas rotas como componentes aninhados. O layout raiz envolve tudo. Dentro "
        "dele, o layout de (planner) envolve o provider, que guarda o planner, que envolve a página. Ir da semana para um "
        "curso substitui só a página. Ir para About substitui o layout de (planner) e tudo o que está nele, o planner "
        "incluído."))
    c.text(20, 20, T("as files", "como arquivos"), size=11, weight="600", fill="var(--amber)", anchor="start")
    rows = [(0, "src/routes/", None), (1, "+layout.svelte", None), (1, "+error.svelte", None),
            (1, "(planner)/", None), (2, "+layout.svelte", None), (2, "+page.svelte", "/"),
            (2, "courses/[id=slug]/", None), (3, "+page.svelte", "/courses/…"),
            (1, "(info)/", None), (2, "about/", None), (3, "+page.svelte", "/about")]
    for k, (depth, name, addr) in enumerate(rows):
        y = 48 + k * 24
        c.text(28 + depth * 18, y, name, mono=True, size=10, anchor="start")
        if addr:
            c.text(300, y, addr, mono=True, size=10, fill="var(--phosphor)", anchor="end")
    # nested components
    c.text(340, 20, T("as components", "como componentes"), size=11, weight="600", fill="var(--amber)", anchor="start")
    c.rect(340, 34, 360, 270, fill="var(--panel)", stroke="var(--wire)")
    c.text(352, 52, "+layout.svelte", mono=True, size=10, anchor="start")
    c.text(688, 52, T("always stays", "fica sempre"), size=9.5, fill="var(--paper-dim)", anchor="end")
    c.rect(354, 66, 216, 222, fill="var(--ink)", stroke="var(--phosphor)")
    c.text(366, 84, "(planner)/+layout.svelte", mono=True, size=9.5, anchor="start")
    c.rect(366, 98, 192, 176, fill="var(--panel)", stroke="var(--phosphor)")
    c.text(378, 116, "PlannerProvider", mono=True, size=9.5, anchor="start")
    c.text(378, 134, T("the planner, in context", "o planner, no contexto"), size=9.5, fill="var(--phosphor)", anchor="start")
    c.rect(378, 150, 168, 108, fill="var(--ink)", stroke="var(--amber)", dash="4 3")
    c.text(462, 172, T("the page", "a página"), size=10, fill="var(--amber)")
    c.text(462, 196, "/", mono=True, size=10)
    c.text(462, 216, T("or", "ou"), size=9.5, fill="var(--paper-dim)")
    c.text(462, 236, "/courses/…", mono=True, size=10)
    c.rect(584, 66, 104, 222, fill="var(--ink)", stroke="var(--amber)", dash="4 3")
    c.text(636, 160, "(info)", mono=True, size=9.5)
    c.text(636, 180, "about/", mono=True, size=9.5)
    c.text(636, 200, "+page.svelte", mono=True, size=9.5)
    c.text(520, 320, T("dashed: replaced on navigation · solid: stays between the planner's pages",
                       "tracejado: substituído ao navegar · contínuo: fica entre as páginas do planner"),
           size=9.5, fill="var(--paper-dim)")
    c.caption = T("Between two pages of the group only the page changes. About is outside the group, so going there "
                  "replaces the group's layout, and the planner with it.",
                  "Entre duas páginas do grupo, só a página muda. About está fora do grupo, então ir até lá substitui o "
                  "layout do grupo, e o planner junto.")
    return c


FIGURES = [("navigation", nested)]
