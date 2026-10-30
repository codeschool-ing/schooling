"""Lesson 9: a screen's inset regions, and the keyboard covering the add-session button."""
from fig import Fig

T = {
    "en": dict(
        r_aria="A diagram of a phone screen, not a screenshot. In portrait, a band across the top holds the status bar, with a camera cutout in the middle of it, and a band across the bottom holds the gesture area; the safe area is the dashed rectangle between them. In landscape the cutout is on the left side, the bands are on the left and the right, a thinner band runs along the bottom, and the safe area is the dashed rectangle inside them.",
        portrait="portrait", landscape="landscape: the cutout moves to a side",
        status="status bar", cutout="cutout", gesture="gesture area", safe="safe area",
        r_cap="A diagram of the regions, not a picture of any phone. The app draws its background into all of them and keeps what the student reads or taps inside the dashed rectangle, which moves when the phone turns.",
        k_aria="Two diagrams of the planner's new-session form with the keyboard up. On the left the form keeps its place: the title field is visible but the Add session button is under the keyboard. On the right the content area ends at the top of the keyboard, so the form sits above it and the button is visible.",
        before="the layout ignores the keyboard", after="the keyboard is treated as an inset",
        field="Title", button="Add session", keyboard="keyboard", hidden="covered",
        k_cap="The field is often brought into view; the button under it is what gets lost. Treating the keyboard as one more bottom inset moves the form's bottom edge to the top of the keys.",
    ),
    "pt": dict(
        r_aria="Um diagrama da tela de um celular, não uma captura de tela. Em retrato, uma faixa no alto contém a barra de status, com um recorte da câmera no meio, e uma faixa embaixo contém a área de gestos; a área segura é o retângulo tracejado entre elas. Em paisagem o recorte fica no lado esquerdo, as faixas ficam à esquerda e à direita, uma faixa mais fina corre embaixo, e a área segura é o retângulo tracejado dentro delas.",
        portrait="retrato", landscape="paisagem: o recorte vai para um lado",
        status="barra de status", cutout="recorte", gesture="área de gestos", safe="área segura",
        r_cap="Um diagrama das regiões, não a imagem de algum celular. O app desenha o fundo em todas elas e mantém o que o aluno lê ou toca dentro do retângulo tracejado, que se move quando o celular vira.",
        k_aria="Dois diagramas do formulário de nova sessão do planner com o teclado aberto. À esquerda o formulário fica no lugar: o campo de título aparece, mas o botão Adicionar sessão fica embaixo do teclado. À direita a área de conteúdo termina no topo do teclado, então o formulário fica acima dele e o botão aparece.",
        before="o layout ignora o teclado", after="o teclado é tratado como inset",
        field="Título", button="Adicionar sessão", keyboard="teclado", hidden="coberto",
        k_cap="O campo muitas vezes é trazido à vista; o botão embaixo dele é o que se perde. Tratar o teclado como mais um inset inferior leva a borda de baixo do formulário ao topo das teclas.",
    ),
}


def regions(t):
    f = Fig("l09-regions", 720, 330, t["r_aria"])
    # portrait
    f.text(155, 14, t["portrait"], size=10, bold=True, fill="paper-dim")
    f.rect(60, 26, 190, 290, stroke="wire", fill="panel", rx=24, width=1.6)
    f.rect(60, 26, 190, 26, stroke="amber", fill="panel", dashed=True, rx=4)
    f.box(122, 31, 66, 16, [t["cutout"]], stroke="amber", size=8, fill="amber", ground="ink")
    f.rect(60, 290, 190, 26, stroke="amber", fill="panel", dashed=True, rx=4)
    f.rect(125, 301, 60, 4, stroke="paper-dim", fill="paper-dim", rx=2, width=1)
    f.box(70, 60, 170, 222, [t["safe"]], stroke="phosphor", dashed=True, size=10, fill="phosphor")
    f.arrow([(272, 39), (252, 39)])
    f.text(276, 39, t["status"], anchor="start", size=10)
    f.arrow([(272, 303), (252, 303)])
    f.text(276, 303, t["gesture"], anchor="start", size=10)
    # landscape
    f.text(565, 84, t["landscape"], size=10, bold=True, fill="paper-dim")
    f.rect(420, 98, 290, 170, stroke="wire", fill="panel", rx=24, width=1.6)
    f.rect(420, 98, 28, 170, stroke="amber", fill="panel", dashed=True, rx=4)
    f.rect(426, 158, 16, 50, stroke="amber", fill="ink", rx=6)
    f.rect(682, 98, 28, 170, stroke="amber", fill="panel", dashed=True, rx=4)
    f.rect(452, 250, 226, 18, stroke="amber", fill="panel", dashed=True, rx=4)
    f.rect(535, 258, 60, 4, stroke="paper-dim", fill="paper-dim", rx=2, width=1)
    f.box(454, 104, 222, 140, [t["safe"]], stroke="phosphor", dashed=True, size=10, fill="phosphor")
    return f


def phone_form(f, x, t, moved):
    f.rect(x, 30, 180, 290, stroke="wire", fill="panel", rx=22, width=1.6)
    kb_top = 210
    f.rect(x + 6, kb_top, 168, 104, stroke="wire", fill="ink")
    f.text(x + 90, kb_top + 88, t["keyboard"], size=10, fill="paper-dim")
    if moved:
        fy, by = 120, 166
    else:
        fy, by = 172, 228
    f.box(x + 16, fy, 148, 30, [t["field"]], stroke="phosphor", size=9.5, anchor="start")
    if moved:
        f.box(x + 40, by, 100, 32, [t["button"]], stroke="phosphor", size=9.5, fill="phosphor")
    else:
        f.rect(x + 40, by, 100, 32, stroke="amber", fill="panel", dashed=True)
        f.text(x + 90, by + 16, t["hidden"], size=9.5, fill="amber")


def keyboard(t):
    f = Fig("l09-keyboard", 720, 340, t["k_aria"])
    f.text(170, 16, t["before"], size=10, bold=True, fill="amber")
    f.text(550, 16, t["after"], size=10, bold=True, fill="phosphor")
    phone_form(f, 80, t, moved=False)
    phone_form(f, 460, t, moved=True)
    return f


def figures(lang):
    t = T[lang]
    return {
        "l09-regions": regions(t).json(t["r_cap"]),
        "l09-keyboard": keyboard(t).json(t["k_cap"]),
    }
