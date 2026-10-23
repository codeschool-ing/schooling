"""Lesson 17: the figures."""
from fig import Fig

T = {
    "en": dict(
        tree_aria="What one line in a requirements file brings with it. The line flask==3.1.3 installs Flask, and Flask requires six more packages: blinker, click, itsdangerous, Jinja2, MarkupSafe and Werkzeug. Jinja2 in turn requires MarkupSafe. pip-audit, installed to check the others, brought 24 packages of its own. Every box is code that runs inside the application.",
        you="what you wrote", line="one line",
        came="what came with it", note="pip-audit itself brought 24 more",
        tree_cap="One line written, seven packages installed. A dependency's dependencies run with the same rights as your own code.",
        loop_aria="The routine that keeps pinned dependencies safe, drawn as a loop of five steps. Pin exact versions. An advisory is published for one of them. The audit run on every change fails and names the fixed version. Raise the pin to that version and run the tests. Commit the new pin, and the loop starts again.",
        s1="pin exact versions", s2="an advisory is published",
        s3="the audit fails, naming", s3b="the fixed version",
        s4="raise the pin,", s4b="run the tests", s5="commit the new pin",
        loop_cap="A pin is a decision you renew, not one you make once.",
    ),
    "pt": dict(
        tree_aria="O que uma linha num arquivo de requisitos traz junto. A linha flask==3.1.3 instala o Flask, e o Flask exige mais seis pacotes: blinker, click, itsdangerous, Jinja2, MarkupSafe e Werkzeug. O Jinja2 por sua vez exige o MarkupSafe. O pip-audit, instalado para verificar os outros, trouxe 24 pacotes próprios. Cada caixa é código que roda dentro da aplicação.",
        you="o que você escreveu", line="uma linha",
        came="o que veio junto", note="o próprio pip-audit trouxe mais 24",
        tree_cap="Uma linha escrita, sete pacotes instalados. As dependências de uma dependência rodam com os mesmos direitos do seu próprio código.",
        loop_aria="A rotina que mantém dependências fixadas seguras, desenhada como um ciclo de cinco passos. Fixar versões exatas. Um alerta é publicado para uma delas. A auditoria que roda a cada mudança falha e nomeia a versão corrigida. Subir a versão fixada para ela e rodar os testes. Fazer commit da nova versão, e o ciclo recomeça.",
        s1="fixar versões exatas", s2="um alerta é publicado",
        s3="a auditoria falha, nomeando", s3b="a versão corrigida",
        s4="subir a versão,", s4b="rodar os testes", s5="commit da nova versão",
        loop_cap="Fixar uma versão é uma decisão que se renova, não uma que se toma uma vez.",
    ),
}
PKGS = ["blinker", "click", "itsdangerous", "Jinja2", "MarkupSafe", "Werkzeug"]


def figures(lang):
    t = T[lang]
    out = {}
    f = Fig("l17-tree", 720, 300, t["tree_aria"])
    f.text(110, 22, t["you"], fill="paper-dim", italic=True)
    f.box(30, 120, 160, 44, ["flask==3.1.3"], stroke="phosphor", mono=True, bold=True)
    f.text(110, 180, t["line"], fill="paper-dim", italic=True)
    f.text(470, 22, t["came"], fill="paper-dim", italic=True)
    f.box(250, 120, 110, 44, ["Flask"], mono=True)
    for i, p in enumerate(PKGS):
        y = 40 + i * 38
        f.box(430, y, 140, 30, [p], mono=True, size=9.5)
        f.arrow([(360, 142), (395, 142), (395, y + 15), (430, y + 15)])
    f.arrow([(570, 169), (620, 169), (620, 207), (570, 207)], dashed=True)
    f.arrow([(190, 142), (250, 142)])
    f.text(470, 285, t["note"], fill="paper-dim", italic=True)
    out["l17-tree"] = f.json(t["tree_cap"])

    f = Fig("l17-loop", 720, 260, t["loop_aria"])
    f.box(270, 20, 180, 40, [t["s1"]], stroke="phosphor")
    f.box(510, 90, 190, 40, [t["s2"]], stroke="amber")
    f.box(430, 180, 200, 50, [t["s3"], t["s3b"]], stroke="amber")
    f.box(110, 180, 200, 50, [t["s4"], t["s4b"]])
    f.box(20, 90, 180, 40, [t["s5"]], stroke="phosphor")
    f.arrow([(450, 40), (605, 40), (605, 90)])
    f.arrow([(605, 130), (605, 155), (530, 155), (530, 180)])
    f.arrow([(430, 205), (310, 205)])
    f.arrow([(160, 180), (110, 180), (110, 130)])
    f.arrow([(110, 90), (110, 40), (270, 40)])
    out["l17-loop"] = f.json(t["loop_cap"])
    return out
