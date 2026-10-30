from fig import Canvas


def tree(T):
    c = Canvas(720, 380, T(
        "The injector tree, from the top. NullInjector, which answers anything by throwing NG0201. Below it the "
        "platform injector, shared by the page. Below that the root injector, made from app.config.ts and every "
        "providedIn root. Below that, one injector per component: App, then Bench, then two Counters, each asking "
        "for a Tally. A dashed arrow from a Counter goes up: inject(Tally) starts at the Counter's own injector, "
        "passes every one with no recipe for it, and the root injector answers.",
        "A árvore de injetores, de cima para baixo. NullInjector, que responde qualquer pergunta lançando NG0201. "
        "Abaixo dele o injetor da plataforma, compartilhado pela página. Abaixo, o injetor raiz, feito do "
        "app.config.ts e de todo providedIn root. Abaixo, um injetor por componente: App, depois Bench, depois dois "
        "Counters, cada um pedindo um Tally. Uma seta tracejada sai de um Counter e sobe: inject(Tally) começa no "
        "injetor do próprio Counter, passa por todo injetor sem receita para ele, e o injetor raiz responde."))
    def box(x, y, w, title, sub, stroke, mono_title=True, mono_sub=False, h=44, dash=None):
        c.rect(x, y, w, h, stroke=stroke, dash=dash)
        c.text(x + w / 2, y + 15, title, size=10.5, mono=mono_title)
        c.text(x + w / 2, y + 31, sub, size=9, mono=mono_sub, fill="var(--paper-dim)")
    W, X = 300, 150
    box(X, 16, W, "NullInjector", T("answers anything by throwing NG0201", "responde tudo lançando NG0201"), "var(--paper-dim)", dash="4 3")
    box(X, 82, W, T("platform injector", "injetor da plataforma"), T("shared by the whole page", "compartilhado pela página inteira"), "var(--wire)", mono_title=False)
    box(X, 148, W, T("root injector", "injetor raiz"), "app.config.ts · providedIn: 'root'", "var(--amber)", mono_title=False, mono_sub=True)
    for y in (60, 126):
        c.line(X + W / 2, y + 22, X + W / 2, y + 2, arrow=True)
    # element injectors
    c.text(X + 60, 236, T("one per component", "um por componente"), size=9.5, anchor="end", fill="var(--phosphor)")
    box(X + 75, 214, 150, "App", T("its providers", "os providers dele"), "var(--phosphor)", h=40)
    box(X + 75, 270, 150, "Bench", T("its providers", "os providers dele"), "var(--phosphor)", h=40)
    box(X - 30, 326, 170, "Counter", T("asks for a Tally", "pede um Tally"), "var(--phosphor)", h=40)
    box(X + 160, 326, 170, "Counter", T("asks for a Tally", "pede um Tally"), "var(--phosphor)", h=40)
    c.line(X + W / 2, 212, X + W / 2, 194, arrow=True)
    c.line(X + W / 2, 268, X + W / 2, 256, arrow=True)
    c.line(X + 55, 324, X + 110, 312, arrow=True)
    c.line(X + 245, 324, X + 190, 312, arrow=True)
    # the question going up
    ax = 520
    c.path(f"M {X + 330} 346 L {ax} 346 L {ax} 170 L {X + W + 4} 170", stroke="var(--amber)", dash="5 3")
    c.line(X + W + 14, 170, X + W + 4, 170, stroke="var(--amber)", arrow=True)
    c.text(ax + 12, 250, "inject(Tally)", size=10, mono=True, anchor="start", fill="var(--amber)")
    c.text(ax + 12, 268, T("starts at the Counter's own,", "começa no do próprio Counter,"), size=9.5, anchor="start", fill="var(--paper-dim)")
    c.text(ax + 12, 284, T("passes every one with no recipe,", "passa por todo injetor sem receita,"), size=9.5, anchor="start", fill="var(--paper-dim)")
    c.text(ax + 12, 300, T("and the root answers", "e o raiz responde"), size=9.5, anchor="start", fill="var(--paper-dim)")
    c.caption = T("A question starts at the asking component and goes up; the first injector with a recipe answers, and the one at the top answers with an error.",
                  "Uma pergunta começa no componente que pergunta e sobe; o primeiro injetor com uma receita responde, e o do topo responde com um erro.")
    return c


FIGURES = [("hierarchy", tree)]
