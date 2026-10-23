from fig import Canvas


def one_owner(T):
    c = Canvas(720, 230, T(
        "Before and after the store. Before: App owns the data and provides it to the views; the router's guard "
        "is outside the component tree, so it fetches courses.json itself, a second request. After: the planner "
        "store owns the data, inside Pinia's container; App, the views, the session rows and the guard all call "
        "usePlannerStore and reach the same store, and courses.json is fetched once.",
        "Antes e depois da store. Antes: App é dono dos dados e os provê às views; a guarda do router fica fora "
        "da árvore de componentes, então busca o courses.json por conta própria, uma segunda requisição. Depois: "
        "a store do planner é dona dos dados, dentro do contêiner do Pinia; App, as views, as linhas de sessão e "
        "a guarda chamam usePlannerStore e chegam à mesma store, e o courses.json é buscado uma vez."))
    c.text(170, 18, T("lesson 12: provide", "aula 12: provide"), size=11.5, weight="600")
    c.text(540, 18, T("lesson 13: one store", "aula 13: uma store"), size=11.5, weight="600")
    c.rect(100, 34, 140, 34, fill="var(--ink)", stroke="var(--amber)")
    c.text(170, 51, "App", mono=True, size=11, fill="var(--amber)")
    for i, v in enumerate(["HomeView", "CourseView"]):
        c.rect(30 + i * 160, 104, 130, 30, fill="var(--panel)", stroke="var(--wire)")
        c.text(95 + i * 160, 119, v, mono=True, size=10.5)
        c.line(170, 70, 95 + i * 160, 102, stroke="var(--wire)", arrow=True)
    c.text(170, 90, "provide", mono=True, size=9.5, fill="var(--paper-dim)")
    c.rect(30, 168, 130, 30, fill="var(--panel)", stroke="var(--wire)", dash="4 3")
    c.text(95, 183, "beforeEnter", mono=True, size=10.5)
    c.rect(200, 168, 130, 30, fill="var(--ink)", stroke="var(--amber)", dash="4 3")
    c.text(265, 183, "courses.json", mono=True, size=10.5, fill="var(--amber)")
    c.line(162, 183, 198, 183, stroke="var(--amber)", arrow=True)
    c.text(180, 214, T("a second request", "uma segunda requisição"), size=10, fill="var(--amber)")
    c.line(360, 30, 360, 210, stroke="var(--wire)", dash="2 4")
    c.rect(470, 100, 150, 40, fill="var(--ink)", stroke="var(--phosphor)")
    c.text(545, 120, "usePlannerStore", mono=True, size=10.5, fill="var(--phosphor)")
    users = [("App", 395, 40), ("HomeView", 600, 40), ("SessionRow", 395, 190), ("beforeEnter", 600, 190)]
    for name, x, y in users:
        c.rect(x, y - 15, 110, 30, fill="var(--panel)", stroke="var(--wire)")
        c.text(x + 55, y, name, mono=True, size=10)
        c.line(x + 55, y + (16 if y < 100 else -16), 545, 98 if y < 100 else 142, stroke="var(--phosphor-dim)", arrow=True)
    c.caption = T("A store is reached by import, so a guard reaches it as easily as a component does.",
                  "Uma store se alcança por import, então uma guarda chega a ela tão fácil quanto um componente.")
    return c


FIGURES = [("why-a-store", one_owner)]
