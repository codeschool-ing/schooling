from fig import Canvas


def walk(T):
    c = Canvas(720, 270, T(
        "A tree of four components: App at the top, Week under it, and under Week a summary and a list. A walk "
        "starts at App and visits each component from the top down, evaluating its template's expressions. "
        "On the right, the same tree with the list marked OnPush and not marked: the walk skips it and everything "
        "below it.",
        "Uma árvore de quatro componentes: App no topo, Week abaixo, e abaixo de Week um resumo e uma lista. Uma "
        "passada começa no App e visita cada componente de cima para baixo, avaliando as expressões do template. À "
        "direita, a mesma árvore com a lista marcada OnPush e sem marca: a passada a pula, e tudo o que está abaixo "
        "dela."))
    def tree(x0, onpush):
        def box(x, y, name, state):
            col = {"visit": "var(--phosphor)", "skip": "var(--wire)"}[state]
            c.rect(x, y, 120, 36, fill="var(--panel)" if state == "visit" else "var(--ink)", stroke=col,
                   dash=None if state == "visit" else "4 3")
            c.text(x + 60, y + 18, name, mono=True, size=10.5, fill="var(--paper)" if state == "visit" else "var(--paper-dim)")
        box(x0 + 110, 40, "App", "visit")
        box(x0 + 110, 110, "Week", "visit")
        box(x0 + 20, 180, "WeekSummary", "visit")
        box(x0 + 200, 180, "CourseCard", "skip" if onpush else "visit")
        c.line(x0 + 170, 76, x0 + 170, 108, stroke="var(--phosphor)", arrow=True)
        c.line(x0 + 150, 146, x0 + 90, 178, stroke="var(--phosphor)", arrow=True)
        c.line(x0 + 190, 146, x0 + 250, 178, stroke="var(--wire)" if onpush else "var(--phosphor)",
               dash="4 3" if onpush else None, arrow=True)
        if onpush:
            c.text(x0 + 260, 232, T("OnPush, not marked: skipped", "OnPush, sem marca: pulado"), size=9.5, fill="var(--paper-dim)")
    c.text(170, 18, T("default: every component, every walk", "padrão: todo componente, toda passada"), size=11, weight="600")
    c.text(530, 18, T("OnPush: only what was marked", "OnPush: só o que foi marcado"), size=11, weight="600")
    tree(10, False)
    tree(370, True)
    c.line(360, 30, 360, 255, dash="4 4")
    c.caption = T("A walk goes from the root down. An OnPush component that nothing marked is skipped, with everything under it.",
                  "Uma passada vai da raiz para baixo. Um componente OnPush que nada marcou é pulado, com tudo o que está abaixo dele.")
    return c


FIGURES = [("what-it-does", walk)]
