"""Lesson 10: how WCAG 2.2 is built, with one branch followed down."""
from fig import Fig

T = {
    "en": dict(
        aria="WCAG 2.2 drawn as four layers, from the top. Four principles: perceivable, operable, understandable, robust. Under them, thirteen guidelines; under perceivable, for instance, 1.4 Distinguishable. Under the guidelines, 86 success criteria, each with a level: under 1.4, 1.4.3 Contrast (Minimum) at level AA and 1.4.6 Contrast (Enhanced) at level AAA. Under the criteria, techniques, which are examples of how to meet them and are not themselves required.",
        layers=[("4 principles", "perceivable · operable · understandable · robust"),
                ("13 guidelines", "1.4 Distinguishable"),
                ("86 success criteria", "1.4.3 Contrast (Minimum): AA · 1.4.6 Contrast (Enhanced): AAA"),
                ("techniques", "examples of how to meet a criterion, not requirements")],
        note="the testable layer",
        cap="Only the third layer is tested. A page meets or fails each success criterion, and its level decides whether a page that fails it can still claim A or AA.",
    ),
    "pt": dict(
        aria="A WCAG 2.2 desenhada em quatro camadas, de cima para baixo. Quatro princípios: perceptível, operável, compreensível, robusto. Abaixo deles, treze diretrizes; abaixo de perceptível, por exemplo, a 1.4 Distinguível. Abaixo das diretrizes, 86 critérios de sucesso, cada um com um nível: abaixo da 1.4, o 1.4.3 Contraste (Mínimo) no nível AA e o 1.4.6 Contraste (Melhorado) no nível AAA. Abaixo dos critérios, as técnicas, que são exemplos de como atendê-los e não são exigidas.",
        layers=[("4 princípios", "perceptível · operável · compreensível · robusto"),
                ("13 diretrizes", "1.4 Distinguível"),
                ("86 critérios de sucesso", "1.4.3 Contraste (Mínimo): AA · 1.4.6 Contraste (Melhorado): AAA"),
                ("técnicas", "exemplos de como atender a um critério, não requisitos")],
        note="a camada testável",
        cap="Só a terceira camada é testada. Uma página atende ou falha em cada critério de sucesso, e o nível dele decide se uma página que falha nele ainda pode afirmar A ou AA.",
    ),
}


def figures(lang):
    t = T[lang]
    f = Fig("l10-wcag", 720, 250, t["aria"])
    for i, (name, example) in enumerate(t["layers"]):
        y = 14 + i * 58
        stroke = "phosphor" if i == 2 else "wire"
        f.box(14, y, 170, 42, [name], stroke=stroke, bold=True, size=10)
        f.box(200, y, 506, 42, [example], stroke=stroke, size=9.5, dashed=(i == 3))
        if i < 3:
            f.arrow([(99, y + 42), (99, y + 58)])
    f.text(706, 14 + 2 * 58 - 6, t["note"], anchor="end", size=9, italic=True, fill="phosphor")
    return {"l10-wcag": f.json(t["cap"])}
