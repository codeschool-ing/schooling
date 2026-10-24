from fig import Canvas


def scope(T):
    c = Canvas(720, 260, T(
        "Two ways to decide what a template may use. On the left, a module: one box, AppModule, declares App and "
        "SessionList and imports BrowserModule and RouterModule, and both components share that one scope. On the "
        "right, standalone: each component carries its own imports list, App importing RouterOutlet and Week, and "
        "Week importing WeekSummary.",
        "Dois jeitos de decidir o que um template pode usar. À esquerda, um módulo: uma caixa, AppModule, declara "
        "App e SessionList e importa BrowserModule e RouterModule, e os dois componentes dividem esse escopo. À "
        "direita, standalone: cada componente traz a própria lista de imports, App importando RouterOutlet e Week, "
        "e Week importando WeekSummary."))
    c.text(180, 18, T("NgModule: the module decides", "NgModule: o módulo decide"), size=11.5, weight="600")
    c.text(540, 18, T("standalone: each component decides", "standalone: cada componente decide"), size=11.5, weight="600")
    c.line(360, 8, 360, 250, dash="4 4")
    c.rect(30, 34, 300, 210, fill="var(--ink)", stroke="var(--amber)", dash="5 3")
    c.text(180, 52, "AppModule", mono=True, size=11, fill="var(--amber)")
    c.text(180, 72, T("one scope, shared by everything declared", "um escopo, dividido por tudo o que é declarado"), size=9.5, fill="var(--paper-dim)")
    for i, n in enumerate(("App", "SessionList")):
        c.rect(50 + i * 140, 90, 120, 40, fill="var(--panel)")
        c.text(110 + i * 140, 110, n, mono=True, size=10.5)
    c.text(180, 150, T("declarations", "declarations"), mono=True, size=9.5, fill="var(--paper-dim)")
    for i, n in enumerate(("BrowserModule", "RouterModule")):
        c.rect(50 + i * 140, 168, 120, 36, fill="var(--panel)", stroke="var(--wire)", dash="3 3")
        c.text(110 + i * 140, 186, n, mono=True, size=10)
    c.text(180, 224, "imports", mono=True, size=9.5, fill="var(--paper-dim)")
    def comp(x, y, name, imports):
        c.rect(x, y, 300, 82, fill="var(--ink)", stroke="var(--phosphor)")
        c.text(x + 16, y + 20, name, mono=True, size=11, anchor="start", fill="var(--phosphor)")
        c.text(x + 16, y + 44, "imports:", mono=True, size=9.5, anchor="start", fill="var(--paper-dim)")
        for i, n in enumerate(imports):
            c.rect(x + 86 + i * 104, y + 32, 96, 26, fill="var(--panel)")
            c.text(x + 134 + i * 104, y + 45, n, mono=True, size=9.5)
    comp(390, 50, "App", ["RouterOutlet", "Week"])
    comp(390, 150, "Week", ["WeekSummary"])
    c.text(540, 248, T("no module anywhere", "nenhum módulo em lugar nenhum"), size=9.5, fill="var(--paper-dim)")
    c.caption = T("Standalone moved the list of what a template may use from the module to the component.",
                  "O standalone levou a lista do que um template pode usar do módulo para o componente.")
    return c


def progress(T):
    c = Canvas(720, 250, T(
        "Lesson 1's component tree again, with the three components built so far drawn solid: App, Week and "
        "WeekSummary. The others, CoursePage, CourseCard, SessionList, SessionRow and AddSession, are drawn dashed, "
        "with the lesson that builds each.",
        "A árvore de componentes da aula 1 de novo, com os três componentes construídos até aqui desenhados em linha "
        "cheia: App, Week e WeekSummary. Os outros, CoursePage, CourseCard, SessionList, SessionRow e AddSession, "
        "estão tracejados, com a aula que constrói cada um."))
    def box(x, y, w, name, note, done):
        c.rect(x, y, w, 42, fill="var(--panel)" if done else "var(--ink)",
               stroke="var(--phosphor)" if done else "var(--wire)", dash=None if done else "4 3")
        c.text(x + w / 2, y + 15, name, mono=True, size=10.5, fill="var(--paper)" if done else "var(--paper-dim)")
        c.text(x + w / 2, y + 31, note, size=9, fill="var(--phosphor)" if done else "var(--paper-dim)")
    box(290, 12, 140, "App", T("built", "pronto"), True)
    box(110, 90, 180, "Week", T("built", "pronto"), True)
    box(430, 90, 180, "CoursePage", T("lesson 8", "aula 8"), False)
    c.line(330, 54, 220, 88, arrow=True)
    c.line(390, 54, 500, 88, arrow=True, dash="4 3")
    box(20, 176, 150, "WeekSummary", T("built", "pronto"), True)
    box(190, 176, 150, "CourseCard", T("lesson 8", "aula 8"), False)
    box(380, 176, 150, "SessionList", T("lesson 8", "aula 8"), False)
    box(550, 176, 150, "AddSession", T("lesson 14", "aula 14"), False)
    c.line(170, 132, 95, 174, arrow=True)
    c.line(230, 132, 265, 174, arrow=True, dash="4 3")
    c.line(490, 132, 455, 174, arrow=True, dash="4 3")
    c.line(550, 132, 625, 174, arrow=True, dash="4 3")
    c.caption = T("Three of lesson 1's components exist; the dashed ones say which lesson builds them.",
                  "Três dos componentes da aula 1 existem; os tracejados dizem que aula constrói cada um.")
    return c


FIGURES = [("ngmodule-code", scope), ("planner-shell", progress)]
