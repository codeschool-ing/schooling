"""Lesson 14 figures."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from fig import Fig, lesson

L = "le-r9e84dzs"
f = Fig("l14-layers", 720, 340,
        "Layers from top to bottom. At the top, the screens: CourseListView, CourseDetailView and WeekView, which need a Mac. They read PlannerModel, also on a Mac. Below, inside a region marked runs anywhere, the PlannerRepository actor. It answers the model with the plan at once, and talks to two protocols below it: PlanSource, on the left, implemented by APIClient and by the tests' FakeSource, which it calls to refresh and sync; and PlanStore, on the right, implemented by FileStore, which it calls to load and save.",
        "Camadas de cima para baixo. No topo, as telas: CourseListView, CourseDetailView e WeekView, que precisam de um Mac. Elas leem o PlannerModel, também num Mac. Abaixo, numa região marcada roda em qualquer lugar, o actor PlannerRepository. Ele responde ao modelo com o plano na hora, e fala com dois protocolos abaixo dele: PlanSource, à esquerda, implementado pelo APIClient e pelo FakeSource dos testes, que ele chama para atualizar e sincronizar; e PlanStore, à direita, implementado pelo FileStore, que ele chama para carregar e salvar.")
for i, n in enumerate(["CourseListView", "CourseDetailView", "WeekView"]):
    x = 120 + i * 170
    f.box(x, 14, 150, 34, stroke="wire")
    f.text(x + 75, 31, n, mono=True, size=11)
f.text(60, 31, "a Mac", "um Mac", size=10, fill="paper-dim")
f.box(260, 78, 200, 34, stroke="wire")
f.text(360, 95, "PlannerModel", mono=True, size=11)
for x in (195, 365, 535):
    f.line(x, 50, 360 if x == 365 else (300 if x < 365 else 420), 76, color="wire", arrow=False)
f.box(16, 128, 688, 200, stroke="phosphor-dim", fill="ink", dashed=True)
f.text(80, 146, "runs anywhere", "roda em qualquer lugar", size=10, fill="phosphor")
f.box(240, 150, 240, 44, stroke="phosphor")
f.text(360, 166, "PlannerRepository", mono=True, size=12, fill="phosphor", weight="600")
f.text(360, 183, "an actor", "um actor", size=10, fill="paper-dim")
f.line(360, 148, 360, 114, color="phosphor")
f.text(372, 139, "plan, at once", "o plano, na hora", size=10, fill="phosphor", anchor="start")
f.box(60, 240, 230, 74, stroke="amber")
f.text(175, 258, "PlanSource", mono=True, size=11, fill="amber", weight="600")
f.text(175, 278, "APIClient", mono=True, size=10)
f.text(175, 296, "FakeSource, in the tests", "FakeSource, nos testes", size=10, fill="paper-dim")
f.box(430, 240, 230, 74, stroke="amber")
f.text(545, 258, "PlanStore", mono=True, size=11, fill="amber", weight="600")
f.text(545, 278, "FileStore", mono=True, size=10)
f.text(545, 296, "one JSON file", "um arquivo JSON", size=10, fill="paper-dim")
f.line(300, 196, 200, 238, color="amber")
f.text(206, 214, "refresh, sync", "atualizar, sincronizar", size=10, fill="amber", anchor="end")
f.line(420, 196, 520, 238, color="amber")
f.text(514, 214, "load, save", "carregar, salvar", size=10, fill="amber", anchor="start")
f.write(lesson(L, "why-a-repository"),
        "The screens see one object. The repository sees two protocols, and everything inside the dashed line runs, and is tested, without a Mac.",
        "As telas veem um objeto. O repositório vê dois protocolos, e tudo dentro da linha tracejada roda, e é testado, sem um Mac.")
