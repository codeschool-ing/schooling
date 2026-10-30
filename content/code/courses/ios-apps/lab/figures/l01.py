"""Lesson 1 figures."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from fig import Fig, lesson

L = "le-r8sx9rjk"

f = Fig("l01-project", 720, 364,
        "An Xcode project, Planner.xcodeproj, drawn as a large box holding three targets: the Planner app, PlannerTests and PlannerUITests. Below them, the Planner scheme, whose Run, Test and Archive actions point at the targets. To the right, outside the project, the planner directory: a Swift package whose library PlannerCore is linked into the app target. The project is built by Xcode on a Mac; the package is built by swift on any computer.",
        "Um projeto Xcode, Planner.xcodeproj, desenhado como uma caixa grande com três targets: o app Planner, PlannerTests e PlannerUITests. Abaixo deles, o scheme Planner, cujas ações Run, Test e Archive apontam para os targets. À direita, fora do projeto, o diretório planner: um pacote Swift cuja biblioteca PlannerCore é ligada ao target do app. O projeto é compilado pelo Xcode num Mac; o pacote, pelo swift em qualquer computador.")
D = 24  # everything below the lane is shifted down by D
f.box(20, 20 + D, 430, 300, stroke="wire", fill="ink")
f.text(235, 40 + D, "Planner.xcodeproj", mono=True, size=12, fill="paper", weight="600")
f.text(235, 58 + D, "targets: what to build", "targets: o que compilar", size=10, fill="paper-dim")
f.text(235, 302 + D, "built by Xcode, on a Mac", "compilado pelo Xcode, num Mac", size=11, fill="paper-dim")
for i, (name, en, pt) in enumerate([("Planner", "the app", "o app"),
                                     ("PlannerTests", "unit tests", "testes unitários"),
                                     ("PlannerUITests", "UI tests", "testes de interface")]):
    x = 40 + i * 138
    f.box(x, 70 + D, 128, 56, stroke="phosphor" if i == 0 else "wire")
    f.text(x + 64, 90 + D, name, mono=True, size=11, fill="paper", weight="600")
    f.text(x + 64, 110 + D, en, pt, size=10, fill="paper-dim")
f.box(40, 190 + D, 394, 84, stroke="amber")
f.text(237, 208 + D, "scheme Planner", mono=True, size=11, fill="amber", weight="600")
f.text(237, 230 + D, "what to do with the targets:", "o que fazer com os targets:", size=10, fill="paper-dim")
f.text(237, 252 + D, "Run · Test · Archive, in Debug or Release", "Run · Test · Archive, em Debug ou Release", size=10, fill="paper")
for x in (104, 242, 380):
    f.line(x, 190 + D, x, 130 + D, color="amber")
f.box(500, 70 + D, 200, 150, stroke="phosphor", fill="ink")
f.text(600, 90 + D, "planner/", mono=True, size=12, fill="paper", weight="600")
f.text(600, 108 + D, "a Swift package", "um pacote Swift", size=10, fill="paper-dim")
f.box(520, 124 + D, 160, 40, stroke="phosphor")
f.text(600, 144 + D, "PlannerCore", mono=True, size=11, fill="phosphor", weight="600")
f.text(600, 186 + D, "built by swift,", "compilado pelo swift,", size=10, fill="paper-dim")
f.text(600, 202 + D, "on any computer", "em qualquer computador", size=10, fill="paper-dim")
f.path(f"M680 {144 + D} L708 {144 + D} L708 12 L104 12 L104 {68 + D}", color="phosphor")
f.text(600, 30, "import PlannerCore", mono=True, size=10, fill="phosphor")
f.write(lesson(L, "the-project"),
        "A target is a product to build and a scheme says what to do with it. The package sits beside the project, and only its library crosses into the app.",
        "Um target é um produto a compilar, e um scheme diz o que fazer com ele. O pacote fica ao lado do projeto, e só a sua biblioteca entra no app.")
