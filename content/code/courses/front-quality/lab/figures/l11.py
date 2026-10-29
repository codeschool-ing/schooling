"""Lesson 11: the focus ring before and after, the tab order of a course page, and the div
that has to be taught to be a button."""
from fig import Fig

FAKE = [
    ('<div class="tick" role="button" tabindex="0">Done</div>\n',
     "A `div` that looks like the planner's button. `role` tells a screen reader to announce a button, and `tabindex=\"0\"` puts it in the tab order, which a `div` is not in.",
     'Uma `div` com a cara do botão do planner. O `role` diz ao leitor de tela que anuncie um botão, e o `tabindex="0"` a põe na ordem de tabulação, onde uma `div` não está.'),
    ('<script>\n  const tick = document.querySelector(".tick");\n  tick.addEventListener("click", markDone);\n',
     "The click is the easy part, and the only part most people write.",
     "O clique é a parte fácil, e a única que a maioria das pessoas escreve."),
    ('  tick.addEventListener("keydown", (event) => {\n    if (event.key === "Enter" || event.key === " ") {\n      event.preventDefault();\n      markDone();\n    }\n  });\n</script>',
     "Enter and Space have to be taught. `preventDefault` stops Space from scrolling the page, which is what it does on anything that is not a button. And this still fires Space when the key goes down, where a button waits for it to come up.",
     "Enter e Espaço precisam ser ensinados. O `preventDefault` impede o Espaço de rolar a página, que é o que ele faz em tudo que não é botão. E isto ainda dispara o Espaço quando a tecla desce, onde um botão espera ela subir."),
]
EXAMPLES = {"custom-controls": [{"language": "html", "parts": FAKE}]}

T = {
    "en": dict(
        focus_aria="Two drawings of the same Done button with the focus on it. On the left, under the rule button:focus { outline: none; }, the button looks exactly as it does without the focus: nothing shows that Tab arrived. On the right, under :focus-visible { outline: 3px solid #2f6f4e; outline-offset: 2px; }, a green ring three pixels thick surrounds the button with a gap of two pixels between them.",
        before="Tab arrived, and nothing shows it",
        after="a 3px ring, 2px away, at 5.99:1",
        focus_cap="The same button, focused from the keyboard, under the old rule and the new one. The ring is drawn outside the button, so it is seen against the page.",
        order_aria="A course page of the planner, with each place the focus stops numbered in the order Tab reaches it. 1: the back link at the top. The heading JavaScript is not a stop. The first session, done, is not a stop. 2: the Done button of the second session. 3 to 6: the date field, four stops: month, day, year and the calendar button. 7: the minutes field. 8: the note field. 9: the Add session button. The total for the week at the foot is not a stop.",
        heading="JavaScript", s1="2026-10-20 · 60 min done", s2="2026-10-22 · 30 min",
        date="Date", minutes="Minutes", note="Note", add="Add session", week="This week: 90 min",
        parts="month · day · year · calendar",
        rule="Tab follows the HTML from the top",
        order_cap="The tab order of the JavaScript page, nine stops. It follows the document from the top, and only controls are stops; the heading, the rows and the total are read, not reached.",
    ),
    "pt": dict(
        focus_aria="Dois desenhos do mesmo botão Done com o foco nele. À esquerda, sob a regra button:focus { outline: none; }, o botão fica igual a quando não tem o foco: nada mostra que o Tab chegou. À direita, sob :focus-visible { outline: 3px solid #2f6f4e; outline-offset: 2px; }, um anel verde de três pixels de espessura envolve o botão, com um espaço de dois pixels entre eles.",
        before="o Tab chegou, e nada mostra",
        after="um anel de 3px, a 2px, a 5,99:1",
        focus_cap="O mesmo botão, focado pelo teclado, sob a regra antiga e a nova. O anel é desenhado fora do botão, então é visto contra a página.",
        order_aria="Uma página de curso do planner, com cada lugar onde o foco para numerado na ordem em que o Tab chega. 1: o link de voltar no alto. O título JavaScript não é uma parada. A primeira sessão, feita, não é uma parada. 2: o botão Done da segunda sessão. 3 a 6: o campo de data, quatro paradas: mês, dia, ano e o botão do calendário. 7: o campo de minutos. 8: o campo de nota. 9: o botão Add session. O total da semana no pé não é uma parada.",
        heading="JavaScript", s1="2026-10-20 · 60 min done", s2="2026-10-22 · 30 min",
        date="Date", minutes="Minutes", note="Note", add="Add session", week="This week: 90 min",
        parts="mês · dia · ano · calendário",
        rule="o Tab segue o HTML de cima para baixo",
        order_cap="A ordem de tabulação da página de JavaScript, nove paradas. Ela segue o documento de cima para baixo, e só controles são paradas; o título, as linhas e o total são lidos, não alcançados.",
    ),
}
SAME = ["JavaScript", "2026-10-20 · 60 min done", "2026-10-22 · 30 min", "Date", "Minutes", "Note",
        "Add session", "This week: 90 min", "Done"]


def figures(lang):
    t = T[lang]
    f = Fig("l11-focus", 720, 170, t["focus_aria"])
    for x, code, ring, label in ((20, "button:focus { outline: none; }", False, t["before"]),
                                 (380, ":focus-visible { outline: 3px … }", True, t["after"])):
        f.text(x + 160, 26, code, mono=True, size=10)
        bx, by = x + 125, 62
        if ring:
            f.rect(bx - 5, by - 5, 80, 46, stroke="phosphor", fill="ink", width=3, rx=6)
        f.box(bx, by, 70, 36, ["Done"], ground="panel", size=11)
        f.text(x + 160, 136, label, size=10, italic=True, fill="phosphor" if ring else "amber")
    f.arrow([(350, 80), (370, 80)])
    focus = f.json(t["focus_cap"], same=["Done"] if lang == "pt" else None)

    g = Fig("l11-order", 720, 330, t["order_aria"])
    g.rect(20, 14, 680, 302, stroke="wire", fill="ink")
    stops = []

    def stop(n, x, y):
        g.rect(x, y, 22, 18, stroke="amber", fill="panel", rx=9)
        g.text(x + 11, y + 9, str(n), size=9, bold=True, fill="amber")

    g.text(50, 40, "←", size=13, anchor="start")
    stop(1, 72, 31)
    g.text(50, 72, t["heading"], size=15, bold=True, anchor="start")
    g.text(50, 106, t["s1"], size=10, anchor="start", fill="paper-dim")
    g.text(50, 136, t["s2"], size=10, anchor="start")
    g.box(170, 126, 48, 20, ["Done"], size=9)
    stop(2, 226, 127)
    y = 180
    g.text(50, y, t["date"], size=10, anchor="start")
    g.box(86, y - 12, 130, 24, ["mm/dd/yyyy"], size=9, mono=True)
    for i in range(4):
        stop(3 + i, 222 + i * 26, y - 9)
    g.text(222, y + 26, t["parts"], size=9, anchor="start", italic=True, fill="paper-dim")
    g.text(340, y, t["minutes"], size=10, anchor="start")
    g.box(398, y - 12, 60, 24, [""], size=9)
    stop(7, 462, y - 9)
    g.text(498, y, t["note"], size=10, anchor="start")
    g.box(530, y - 12, 100, 24, [""], size=9)
    stop(8, 636, y - 9)
    g.box(50, 228, 100, 26, [t["add"]], size=10)
    stop(9, 156, 232)
    g.text(50, 284, t["week"], size=10, bold=True, anchor="start")
    g.text(690, 284, t["rule"], size=10, anchor="end", italic=True, fill="phosphor")
    order = g.json(t["order_cap"], same=SAME if lang == "pt" else None)
    return {"l11-focus": focus, "l11-order": order}
