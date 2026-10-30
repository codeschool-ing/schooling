"""Lesson 2 figures."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from fig import Fig, lesson

L = "le-tmze4cyj"

f = Fig("l02-scenes", 720, 300,
        "The PlannerApp value at the top declares one WindowGroup. On an iPhone the group makes one window; on an iPad it makes two windows side by side. Each window holds its own CourseListView with its own state, so two windows showing @State would hold two separate plans.",
        "O valor PlannerApp no topo declara um WindowGroup. Num iPhone o grupo faz uma janela; num iPad faz duas janelas lado a lado. Cada janela tem o seu CourseListView com o seu próprio estado, então duas janelas com @State teriam dois planos separados.")
f.box(260, 16, 200, 40, stroke="phosphor")
f.text(360, 36, "PlannerApp", mono=True, size=12, fill="phosphor", weight="600")
f.box(260, 84, 200, 40, stroke="amber")
f.text(360, 104, "WindowGroup", mono=True, size=12, fill="amber", weight="600")
f.line(360, 56, 360, 82, color="wire")
f.text(150, 104, "a template", "um modelo", size=10, fill="paper-dim")
# iPhone
f.box(30, 160, 180, 110, stroke="wire", fill="ink")
f.text(120, 176, "iPhone: one window", "iPhone: uma janela", size=10, fill="paper-dim")
f.box(50, 196, 140, 56, stroke="wire")
f.text(120, 214, "CourseListView", mono=True, size=10, fill="paper")
f.text(120, 234, "its own @State", "o seu @State", size=10, fill="paper-dim")
# iPad
f.box(290, 160, 400, 110, stroke="wire", fill="ink")
f.text(490, 176, "iPad: two windows from the same group", "iPad: duas janelas do mesmo grupo", size=10, fill="paper-dim")
for x in (310, 500):
    f.box(x, 196, 170, 56, stroke="wire")
    f.text(x + 85, 214, "CourseListView", mono=True, size=10, fill="paper")
    f.text(x + 85, 234, "its own @State", "o seu @State", size=10, fill="paper-dim")
f.line(330, 124, 125, 158, color="amber")
f.line(380, 124, 395, 158, color="amber")
f.line(420, 124, 580, 158, color="amber")
f.write(lesson(L, "scenes"),
        "One declaration, as many windows as the platform allows, and separate @State in each of them.",
        "Uma declaração, tantas janelas quanto a plataforma permitir, e um @State separado em cada uma.")

g = Fig("l02-tree", 720, 300,
        "The planner's view tree. PlannerApp at the top, then WindowGroup, then CourseListView. Below CourseListView, CourseDetailView, and below that SessionForm; WeekView hangs from CourseListView as well. Data travels down the tree, drawn as arrows pointing down on the left; events travel up as changes to data a parent owns, drawn as arrows pointing up on the right.",
        "A árvore de views do planner. PlannerApp no topo, depois WindowGroup, depois CourseListView. Abaixo de CourseListView, CourseDetailView, e abaixo dele SessionForm; WeekView também pende de CourseListView. Os dados descem pela árvore, desenhados como setas para baixo à esquerda; os eventos sobem como mudanças em dados que um pai possui, desenhados como setas para cima à direita.")
nodes = {"PlannerApp": (360, 30), "WindowGroup": (360, 85), "CourseListView": (360, 140),
         "CourseDetailView": (260, 200), "WeekView": (470, 200), "SessionForm": (260, 260)}
for name, (x, y) in nodes.items():
    g.box(x - 80, y - 17, 160, 34, stroke="phosphor" if name == "CourseListView" else "wire")
    g.text(x, y, name, mono=True, size=11, fill="paper")
for a, b in [("PlannerApp", "WindowGroup"), ("WindowGroup", "CourseListView"), ("CourseListView", "CourseDetailView"),
             ("CourseListView", "WeekView"), ("CourseDetailView", "SessionForm")]:
    (x1, y1), (x2, y2) = nodes[a], nodes[b]
    g.line(x1, y1 + 17, x2, y2 - 19, color="wire")
g.line(70, 60, 70, 250, color="phosphor")
g.text(70, 270, "data goes down", "os dados descem", size=10, fill="phosphor")
g.line(650, 250, 650, 60, color="amber")
g.text(650, 270, "events go up", "os eventos sobem", size=10, fill="amber")
g.write(lesson(L, "the-view-tree"),
        "The four screens in one tree. Lesson 6 makes the downward arrow a value and the upward one a Binding.",
        "As quatro telas numa árvore. A aula 6 faz da seta para baixo um valor e da seta para cima um Binding.")
