from fig import Canvas


def calls(T):
    c = Canvas(720, 250, T(
        "Two columns. On the left, a library: your code is at the top and calls down into the library's functions, "
        "and gets their answers back. On the right, a framework: Angular is at the top and calls down into your "
        "class, building it, reading its fields into the template, and reading them again when something changes.",
        "Duas colunas. À esquerda, uma biblioteca: o seu código está em cima e chama as funções da biblioteca, e "
        "recebe as respostas de volta. À direita, um framework: o Angular está em cima e chama a sua classe, "
        "construindo-a, lendo os campos dela para o template, e lendo de novo quando algo muda."))
    c.text(180, 22, T("a library", "uma biblioteca"), size=12, weight="600", fill="var(--paper)")
    c.text(540, 22, T("a framework", "um framework"), size=12, weight="600", fill="var(--paper)")
    c.line(360, 12, 360, 238, stroke="var(--wire)", dash="4 4")
    # library
    c.rect(70, 44, 220, 52, fill="var(--ink)", stroke="var(--phosphor)")
    c.text(180, 62, T("your code", "o seu código"), size=11, fill="var(--phosphor)")
    c.text(180, 80, T("decides when", "decide quando"), size=9.5, fill="var(--paper-dim)")
    c.rect(70, 170, 220, 52, fill="var(--panel)", stroke="var(--wire)")
    c.text(180, 188, T("the library", "a biblioteca"), size=11)
    c.text(180, 206, "format(date)", mono=True, size=10, fill="var(--paper-dim)")
    c.line(150, 96, 150, 168, stroke="var(--phosphor)", arrow=True)
    c.text(144, 132, T("calls", "chama"), anchor="end", size=9.5, fill="var(--phosphor)")
    c.line(210, 170, 210, 98, stroke="var(--paper-dim)", arrow=True)
    c.text(216, 132, T("answers", "responde"), anchor="start", size=9.5, fill="var(--paper-dim)")
    # framework
    c.rect(430, 44, 220, 52, fill="var(--ink)", stroke="var(--amber)")
    c.text(540, 62, "Angular", size=11, fill="var(--amber)")
    c.text(540, 80, T("decides when", "decide quando"), size=9.5, fill="var(--paper-dim)")
    c.rect(430, 170, 220, 52, fill="var(--panel)", stroke="var(--wire)")
    c.text(540, 188, T("your class", "a sua classe"), size=11)
    c.text(540, 206, "class Week { minutes = 165 }", mono=True, size=10, fill="var(--paper-dim)")
    for i, (en, pt) in enumerate((("builds it", "constrói"), ("reads minutes", "lê minutes"), ("reads it again", "lê de novo"))):
        x = 470 + i * 70
        c.line(x, 96, x, 168, stroke="var(--amber)", arrow=True)
        c.text(x + 4, 112 + i * 18, T(en, pt), anchor="start", size=9, fill="var(--amber)")
    c.caption = T("You call a library and it answers. A framework calls you, and decides when.",
                  "Você chama uma biblioteca e ela responde. Um framework chama você, e decide quando.")
    return c


def tree(T):
    c = Canvas(720, 300, T(
        "The planner's component tree. App at the top. Under it, the two screens: Week, which contains a week "
        "summary and one course card per course, and CoursePage, which contains a session list made of session "
        "rows, and a form to add a session.",
        "A árvore de componentes do planner. App no topo. Embaixo, as duas telas: Week, que contém um resumo da "
        "semana e um cartão por curso, e CoursePage, que contém uma lista de sessões feita de linhas de sessão, e "
        "um formulário para adicionar uma sessão."))
    def box(x, y, w, name, what, col="var(--wire)"):
        c.rect(x, y, w, 46, fill="var(--panel)", stroke=col)
        c.text(x + w / 2, y + 16, name, mono=True, size=10.5, fill="var(--paper)")
        c.text(x + w / 2, y + 33, what, size=9, fill="var(--paper-dim)")
    box(290, 14, 140, "App", T("the shell", "a casca"), "var(--amber)")
    box(110, 96, 180, "Week", T("screen: /", "tela: /"), "var(--phosphor)")
    box(430, 96, 180, "CoursePage", T("screen: /courses/:id", "tela: /courses/:id"), "var(--phosphor)")
    c.line(330, 60, 220, 94, arrow=True)
    c.line(390, 60, 500, 94, arrow=True)
    box(20, 190, 150, "WeekSummary", T("planned and done", "planejado e feito"))
    box(190, 190, 150, "CourseCard", T("one per course", "um por curso"))
    box(380, 190, 150, "SessionList", T("the course's sessions", "as sessões do curso"))
    box(550, 190, 150, "AddSession", T("a form", "um formulário"))
    c.line(170, 142, 95, 188, arrow=True)
    c.line(230, 142, 265, 188, arrow=True)
    c.line(490, 142, 455, 188, arrow=True)
    c.line(550, 142, 625, 188, arrow=True)
    c.rect(380, 254, 150, 34, fill="var(--ink)", stroke="var(--wire)", dash="4 3")
    c.text(455, 271, "SessionRow", mono=True, size=10.5, fill="var(--paper)")
    c.line(455, 236, 455, 252, arrow=True)
    c.text(540, 271, T("one per session", "uma por sessão"), anchor="start", size=9, fill="var(--paper-dim)")
    c.caption = T("Each box is a component you write; each line down is one template using another.",
                  "Cada caixa é um componente que você escreve; cada linha para baixo é um template usando outro.")
    return c


FIGURES = [("framework-or-library", calls), ("the-planner", tree)]
