"""Lesson 20 figures."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from fig import Fig, lesson

L = "le-6j9a1x5s"
f = Fig("l20-where", 720, 300,
        "Where each kind of test lives. On the left, the planner's Swift package, with its unit tests in Swift Testing and XCTest, run by swift test on any computer in a fraction of a second. On the right, the Xcode project on a Mac, holding the UI tests, which launch the app in a simulator and take seconds each, and the previews, which are looked at rather than run. The arrow from the package to the app says the app imports the tested rules.",
        "Onde vive cada tipo de teste. À esquerda, o pacote Swift do planner, com os testes unitários em Swift Testing e XCTest, rodados pelo swift test em qualquer computador numa fração de segundo. À direita, o projeto Xcode num Mac, com os testes de interface, que abrem o app num simulador e levam segundos cada, e as previews, que são olhadas e não executadas. A seta do pacote para o app diz que o app importa as regras testadas.")
f.box(20, 20, 320, 260, stroke="phosphor", fill="ink")
f.text(180, 42, "the package, any computer", "o pacote, qualquer computador", size=12, fill="phosphor", weight="600")
for i, (en, pt, sub_en, sub_pt) in enumerate([
        ("Swift Testing", "Swift Testing", "the week, Mondays, loading", "a semana, segundas, carga"),
        ("XCTest", "XCTest", "the older tests, beside them", "os testes antigos, ao lado"),
        ("swift test", "swift test", "milliseconds, on every change", "milissegundos, a cada mudança")]):
    y = 66 + i * 70
    f.box(40, y, 280, 54, stroke="wire")
    f.text(180, y + 18, en, mono=True, size=11, fill="paper", weight="600")
    f.text(180, y + 38, sub_en, sub_pt, size=10, fill="paper-dim")
f.box(400, 20, 300, 260, stroke="wire", fill="ink", dashed=True)
f.text(550, 42, "the app, on a Mac (not run here)", "o app, num Mac (não executado aqui)", size=12, fill="paper", weight="600")
f.box(420, 66, 260, 54, stroke="amber")
f.text(550, 84, "UI tests (XCTest)", "testes de interface (XCTest)", size=11, fill="amber", weight="600")
f.text(550, 104, "a few flows, seconds each", "poucos fluxos, segundos cada", size=10, fill="paper-dim")
f.box(420, 136, 260, 54, stroke="wire")
f.text(550, 154, "#Preview", mono=True, size=11, fill="paper", weight="600")
f.text(550, 174, "looked at, never failing", "olhadas, nunca falham", size=10, fill="paper-dim")
f.box(420, 206, 260, 54, stroke="wire")
f.text(550, 224, "PlannerApp", mono=True, size=11, fill="paper", weight="600")
f.text(550, 244, "imports PlannerCore", "importa PlannerCore", size=10, fill="paper-dim")
f.line(340, 233, 418, 233, color="phosphor")
f.write(lesson(L, "what-to-test"),
        "The rules are tested where they live, fast and anywhere; the app keeps the few tests only an app can run.",
        "As regras são testadas onde moram, rápido e em qualquer lugar; o app fica com os poucos testes que só um app roda.")
