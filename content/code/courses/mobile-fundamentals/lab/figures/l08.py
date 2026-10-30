"""Lesson 8: Android's width breakpoints on a ruler, and the planner in one pane or two."""
from fig import Fig

T = {
    "en": dict(
        r_aria="A ruler of window widths from 0 to 1800 dp, divided by Android's width breakpoints: compact below 600 dp, medium from 600 to 840, expanded from 840 to 1200, large from 1200 to 1600, and extra-large from 1600. Four example windows are marked: a phone in portrait at 360 dp, a foldable open in portrait at 700, the same foldable turned at 880, and a tablet in landscape at 1280.",
        r_head="window width in dp, and the class Android gives it",
        marks=[(360, "phone, portrait"), (700, "foldable, open"), (880, "foldable, turned"), (1280, "tablet, landscape")],
        r_cap="Android's width classes as bands on one ruler. The example windows are round numbers, not measurements of real devices; what matters is which band a window falls in, and that the same device lands in different bands as its window changes.",
        p_aria="Two ways to show the planner. On the left, one pane: the course list fills the window, tapping a course replaces it with that course's detail, and back returns to the list. On the right, two panes in a wide window: the list stays on the left with the selected course highlighted, and its detail fills the right.",
        one="one pane: the list, then the detail", two="two panes: list and detail side by side",
        courses="Courses", tap="tap", back="back",
        p_cap="The same two screens, arranged by the window. In one pane the detail replaces the list and back brings it back; in two panes the list never leaves, so there is nothing to go back to.",
    ),
    "pt": dict(
        r_aria="Uma régua de larguras de janela de 0 a 1800 dp, dividida pelos pontos de quebra de largura do Android: compact abaixo de 600 dp, medium de 600 a 840, expanded de 840 a 1200, large de 1200 a 1600 e extra-large a partir de 1600. Quatro janelas de exemplo estão marcadas: um celular em retrato com 360 dp, um dobrável aberto em retrato com 700, o mesmo dobrável virado com 880 e um tablet em paisagem com 1280.",
        r_head="largura da janela em dp, e a classe que o Android dá a ela",
        marks=[(360, "celular, retrato"), (700, "dobrável, aberto"), (880, "dobrável, virado"), (1280, "tablet, paisagem")],
        r_cap="As classes de largura do Android como faixas numa régua. As janelas de exemplo são números redondos, não medidas de aparelhos reais; o que importa é em que faixa uma janela cai, e que o mesmo aparelho cai em faixas diferentes conforme a janela muda.",
        p_aria="Dois jeitos de mostrar o planner. À esquerda, um painel: a lista de cursos ocupa a janela, tocar num curso a troca pelo detalhe dele, e voltar retorna à lista. À direita, dois painéis numa janela larga: a lista fica à esquerda com o curso escolhido destacado, e o detalhe ocupa a direita.",
        one="um painel: a lista, depois o detalhe", two="dois painéis: lista e detalhe lado a lado",
        courses="Cursos", tap="toque", back="voltar",
        p_cap="As mesmas duas telas, arrumadas pela janela. Num painel o detalhe substitui a lista e voltar a traz de volta; em dois painéis a lista nunca sai, então não há para onde voltar.",
    ),
}

BANDS = [(0, 600, "compact", "wire"), (600, 840, "medium", "phosphor"), (840, 1200, "expanded", "amber"),
         (1200, 1600, "large", "wire"), (1600, 1800, "extra-large", "wire")]


def ruler(t):
    f = Fig("l08-ruler", 720, 168, t["r_aria"])
    x0, k = 40, 640 / 1800
    X = lambda dp: round(x0 + dp * k, 1)
    f.text(360, 18, t["r_head"], size=10, fill="paper-dim", italic=True)
    for a, b, name, c in BANDS:
        f.box(X(a), 100, round((b - a) * k, 1), 30, [name], stroke=c, mono=True, size=9.5)
    for dp in (0, 600, 840, 1200, 1600):
        f.arrow([(X(dp), 130), (X(dp), 140)], color="wire", head=False)
        f.text(X(dp), 152, str(dp), size=9, mono=True, fill="paper-dim")
    f.text(X(1800), 152, "dp", size=9, mono=True, fill="paper-dim", anchor="end")
    for i, (dp, label) in enumerate(t["marks"]):
        y = 36 if i % 2 == 0 else 64
        f.text(X(dp), y, label, size=9.5)
        f.text(X(dp), y + 12, str(dp), size=9, mono=True, fill="paper-dim")
        f.arrow([(X(dp), y + 19), (X(dp), 98)], color="paper-dim")
    return f


def screen(f, x, y, w, h, title, rows, sel=None, mono=False):
    f.rect(x, y, w, h, stroke="wire", fill="panel", rx=8)
    f.text(x + 10, y + 16, title, anchor="start", size=10, bold=True, mono=mono)
    for i, r in enumerate(rows):
        ry = y + 30 + i * 30
        f.box(x + 8, ry, w - 16, 24, [r], stroke="phosphor" if i == sel else "wire", mono=True, size=9,
              anchor="start", fill="phosphor" if i == sel else "paper")


COURSES = ["sql", "mobile", "kotlin"]
DETAIL = ["2026-10-19  50 min", "2026-10-23  60 min"]


def panes(t):
    f = Fig("l08-panes", 720, 250, t["p_aria"])
    f.text(20, 18, t["one"], anchor="start", size=10, bold=True, fill="phosphor")
    f.text(380, 18, t["two"], anchor="start", size=10, bold=True, fill="amber")
    screen(f, 20, 36, 130, 190, t["courses"], COURSES, sel=0)
    screen(f, 200, 36, 130, 190, "sql", DETAIL, mono=True)
    f.arrow([(150, 80), (200, 80)])
    f.text(175, 70, t["tap"], size=9.5, fill="paper-dim")
    f.arrow([(200, 190), (150, 190)], dashed=True)
    f.text(175, 180, t["back"], size=9.5, fill="paper-dim")
    f.rect(380, 36, 320, 190, stroke="amber", fill="panel", rx=8)
    screen(f, 388, 44, 120, 174, t["courses"], COURSES, sel=0)
    screen(f, 516, 44, 176, 174, "sql", DETAIL, mono=True)
    return f


def figures(lang):
    t = T[lang]
    return {
        "l08-ruler": ruler(t).json(t["r_cap"], same=None),
        "l08-panes": panes(t).json(t["p_cap"], same=None),
    }
