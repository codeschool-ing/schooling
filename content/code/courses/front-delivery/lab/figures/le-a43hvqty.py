from fig import Canvas


def trees(T):
    c = Canvas(720, 250, T(
        "Two trees for one element. The light DOM is what the page wrote: planner-session with the attributes id, "
        "date and minutes, holding the text JavaScript. The shadow tree is what the element draws: a style sheet, a "
        "slot, a span with class when, a button with part button, and a hidden span saying done. The light text is "
        "drawn where the slot is, and the row on screen reads JavaScript, 2026-10-15 · 45 min, and a Mark done button.",
        "Duas árvores para um elemento. O light DOM é o que a página escreveu: planner-session com os atributos id, "
        "date e minutes, contendo o texto JavaScript. A árvore shadow é o que o elemento desenha: uma folha de "
        "estilo, um slot, um span com a classe when, um botão com part button e um span escondido dizendo done. O "
        "texto do light DOM é desenhado onde está o slot, e a linha na tela diz JavaScript, 2026-10-15 · 45 min, e um "
        "botão Mark done."))
    c.text(20, 22, T("light DOM: what the page wrote", "light DOM: o que a página escreveu"), size=10.5, anchor="start", weight="600")
    c.rect(20, 36, 300, 110, fill="var(--panel)")
    c.text(32, 58, '<planner-session id="session-6"', mono=True, size=10, anchor="start")
    c.text(48, 76, 'date="2026-10-15" minutes="45">', mono=True, size=10, anchor="start")
    c.text(48, 100, "JavaScript", mono=True, size=10.5, anchor="start", fill="var(--phosphor)")
    c.text(32, 124, "</planner-session>", mono=True, size=10, anchor="start")
    c.text(400, 22, T("shadow tree: what the element draws", "árvore shadow: o que o elemento desenha"), size=10.5, anchor="start", weight="600")
    c.rect(400, 36, 300, 150, fill="var(--ink)", stroke="var(--phosphor)", dash="4 3")
    c.text(412, 56, "#shadow-root (open)", mono=True, size=10, anchor="start", fill="var(--paper-dim)")
    for i, s in enumerate(["<style>…</style>", "<slot></slot>", '<span class="when">', '<button part="button">', '<span class="done" hidden>']):
        c.text(428, 78 + i * 21, s, mono=True, size=10, anchor="start", fill="var(--phosphor)" if i == 1 else "var(--paper)")
    c.path("M 125 104 C 220 104, 300 99, 418 99", stroke="var(--phosphor)", dash="4 3")
    c.line(410, 99, 418, 99, stroke="var(--phosphor)", arrow=True)
    c.text(250, 168, T("drawn where the slot is", "desenhado onde está o slot"), size=10, fill="var(--phosphor)")
    c.rect(20, 200, 680, 36, fill="var(--panel)", stroke="var(--amber)")
    c.text(36, 218, T("on screen", "na tela"), size=10, anchor="start", fill="var(--amber)")
    c.text(120, 218, "JavaScript", size=11, anchor="start")
    c.text(206, 218, "2026-10-15 · 45 min", size=11, anchor="start", fill="var(--paper-dim)")
    c.rect(350, 207, 90, 22, fill="var(--ink)", stroke="var(--phosphor)")
    c.text(395, 218, "Mark done", size=10.5)
    c.caption = T("The page writes the light DOM and the element draws the shadow tree; the light content appears at the slot.",
                  "A página escreve o light DOM e o elemento desenha a árvore shadow; o conteúdo do light DOM aparece no slot.")
    return c


def boundary(T):
    c = Canvas(720, 240, T(
        "What crosses the shadow boundary. From the page, four things are tried against the row's button. The selector "
        "main button with a red background is stopped at the boundary. Inherited properties such as color and font "
        "cross it. Custom properties such as --accent cross it, which is how the tokens reach the button. A rule on "
        "planner-session::part(button) crosses it, because the element named that part.",
        "O que atravessa a fronteira do shadow. Da página, quatro coisas tentam chegar ao botão da linha. O seletor "
        "main button com fundo vermelho para na fronteira. Propriedades herdadas, como color e font, atravessam. "
        "Propriedades customizadas, como --accent, atravessam, e é assim que os tokens chegam ao botão. Uma regra em "
        "planner-session::part(button) atravessa, porque o elemento deu nome a essa parte."))
    c.text(20, 22, T("the page", "a página"), size=10.5, anchor="start", weight="600")
    c.text(560, 22, T("the shadow tree", "a árvore shadow"), size=10.5, anchor="start", weight="600")
    c.line(470, 36, 470, 224, stroke="var(--paper-dim)", dash="5 4")
    c.text(470, 232, T("the boundary", "a fronteira"), size=9.5, fill="var(--paper-dim)")
    rows = [
        ("main button { background: red }", T("a selector: stopped", "um seletor: barrado"), False),
        ("color, font-family, line-height", T("inherited: crosses", "herdadas: atravessam"), True),
        ("--accent: #2f6f4e", T("a custom property: crosses", "propriedade customizada: atravessa"), True),
        ("planner-session::part(button)", T("a named part: crosses", "uma parte com nome: atravessa"), True),
    ]
    for i, (code, label, through) in enumerate(rows):
        y = 56 + i * 44
        col = "var(--phosphor)" if through else "var(--amber)"
        c.text(20, y, code, mono=True, size=10, anchor="start", fill=col)
        c.text(20, y + 16, label, size=9.5, anchor="start", fill="var(--paper-dim)")
        if through:
            c.line(260, y + 4, 556, 130, stroke=col, arrow=True)
        else:
            c.line(260, y + 4, 462, y + 4, stroke=col, dash="4 3")
            c.line(458, y - 2, 466, y + 10, stroke=col, sw=1.6)
            c.line(458, y + 10, 466, y - 2, stroke=col, sw=1.6)
    c.rect(560, 110, 140, 40, fill="var(--ink)", stroke="var(--phosphor)")
    c.text(630, 130, '<button part="button">', mono=True, size=9.5)
    c.caption = T("Selectors stop at a shadow root; inherited values, custom properties and named parts are the ways in.",
                  "Seletores param na raiz shadow; valores herdados, propriedades customizadas e partes com nome são os caminhos para dentro.")
    return c


FIGURES = [("shadow-dom", trees), ("styling-through-the-boundary", boundary)]
