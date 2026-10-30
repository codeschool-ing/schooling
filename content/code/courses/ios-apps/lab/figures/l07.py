"""Lesson 7 figures."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from fig import Fig, lesson

L = "le-h94f2h1m"
f = Fig("l07-env", 720, 296,
        "PlannerApp holds one PlannerModel in @State and puts it in the environment at the root. Below it, a tree of views: CourseListView and WeekView read the model from the environment; a NavigationStack and a plain container between them read nothing and take no argument; CourseDetailView, further down, reads the model too. Only the views that ask for the model take it out; the ones in between never mention it.",
        "O PlannerApp guarda um PlannerModel em @State e o coloca no ambiente na raiz. Abaixo, uma árvore de views: CourseListView e WeekView leem o modelo do ambiente; um NavigationStack e um contêiner simples entre elas não leem nada e não recebem argumento; a CourseDetailView, mais abaixo, também lê o modelo. Só as views que pedem o modelo o tiram do ambiente; as do meio nunca o mencionam.")
f.box(230, 16, 260, 50, stroke="phosphor")
f.text(360, 34, "PlannerApp", mono=True, size=12, fill="paper", weight="600")
f.text(360, 52, "@State model  ·  .environment(model)", mono=True, size=10, fill="phosphor")
nodes = {"stack": (60, 110, "NavigationStack", False), "week": (420, 110, "WeekView", True),
         "list": (60, 190, "CourseListView", True), "tabs": (420, 190, "a plain VStack", False),
         "detail": (60, 260, "CourseDetailView", True)}
for k, (x, y, name, reads) in nodes.items():
    f.box(x, y - 20, 240, 40, stroke="amber" if reads else "wire", dashed=not reads)
    f.text(x + 120, y, name, mono=(k != "tabs"), size=11, fill="paper" if reads else "paper-dim", weight="600" if reads else None)
f.line(300, 66, 180, 88)
f.line(420, 66, 540, 88)
f.line(180, 130, 180, 168)
f.line(540, 130, 540, 168)
f.line(180, 210, 180, 238)
f.box(330, 234, 14, 14, stroke="amber", fill="panel")
f.text(352, 241, "reads @Environment(PlannerModel.self)", mono=True, size=10, fill="amber", anchor="start")
f.box(330, 262, 14, 14, stroke="wire", fill="panel", dashed=True)
f.text(352, 269, "never mentions the model", "nunca menciona o modelo", size=10, fill="paper-dim", anchor="start")
f.write(lesson(L, "environment"),
        "The model is put in the environment once, at the root. The views that ask for it take it out; the views between them take no argument and never mention it.",
        "O modelo é colocado no ambiente uma vez, na raiz. As views que o pedem o tiram de lá; as views entre elas não recebem argumento e nunca o mencionam.")
