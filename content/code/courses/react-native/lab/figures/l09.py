"""Lesson 9: planState.tsx annotated, and the provider with its readers."""
import pathlib
from fig import Fig

SRC = (pathlib.Path(__file__).parent.parent / "src" / "l09" / "planState.tsx").read_text().rstrip("\n").split("\n")
blocks, cur = [], []
for line in SRC:
    if line == "" and cur:
        blocks.append(cur); cur = []
    else:
        cur.append(line)
blocks.append(cur)
NOTES = [
 ("The plan's state needs React's context and reducer hooks, and the rules of lesson 3.", "O estado do plano precisa dos hooks de contexto e de reducer do React, e das regras da aula 3."),
 ("**Every change the plan can undergo, as a type.** A union: an action is one shape or the other, and TypeScript knows which fields each carries.",
  "**Toda mudança por que o plano pode passar, como um tipo.** Uma união: uma ação tem uma forma ou a outra, e o TypeScript sabe que campos cada uma traz."),
 ("The reducer: the plan and an action in, the next plan out. Each case hands the work to a rule that already exists, so nothing here can disagree with `src/planner.ts`.",
  "O reducer: o plano e uma ação entram, o próximo plano sai. Cada caso entrega o trabalho a uma regra que já existe, então nada aqui pode discordar do `src/planner.ts`."),
 ("The context, holding the plan and the function that sends actions. `null` until a provider gives it a value.",
  "O contexto, guardando o plano e a função que envia ações. `null` até um provider lhe dar um valor."),
 ("The provider: `useReducer` keeps the plan, starting from `initial`, and every component below can read it.",
  "O provider: o `useReducer` guarda o plano, a partir do `initial`, e todo componente abaixo pode lê-lo."),
 ("The hook screens call. It fails with a sentence, not a crash later, when nobody provided a plan.",
  "O hook que as telas chamam. Ele falha com uma frase, e não com uma falha mais adiante, quando ninguém forneceu um plano."),
]
assert len(blocks) == len(NOTES), len(blocks)
parts = [("\n".join(b) + ("\n" if i < len(blocks) - 1 else ""), en, pt) for i, (b, (en, pt)) in enumerate(zip(blocks, NOTES))]
EXAMPLES = {"reducer": [{"language": "tsx", "file": "src/planState.tsx", "parts": parts}]}

T = {
 "en": dict(aria="The plan's provider at the root of the app, around the navigators. It holds the plan and dispatch. The Courses, This week and Course screens all read it with usePlan. The This week and Course screens send a done action through dispatch; the reducer returns a new plan; every reader renders again.",
   prov="PlanProvider: plan + dispatch", red="planReducer", c1="Courses", c2="This week", c3="Course", read="usePlan()", act="{ type: \"done\", id }",
   cap="One plan at the root: screens read it, and change it only by sending an action."),
 "pt": dict(aria="O provider do plano na raiz do app, em volta dos navegadores. Ele guarda o plano e o dispatch. As telas Courses, This week e Course o leem com usePlan. As telas This week e Course enviam uma ação done pelo dispatch; o reducer devolve um plano novo; todo leitor renderiza de novo.",
   prov="PlanProvider: plan + dispatch", red="planReducer", c1="Courses", c2="This week", c3="Course", read="usePlan()", act="{ type: \"done\", id }",
   cap="Um plano na raiz: as telas o leem, e só o mudam enviando uma ação."),
}


def figures(lang):
    t = T[lang]
    f = Fig("l09-context", 720, 240, t["aria"])
    f.box(200, 20, 260, 40, [t["prov"]], mono=True, size=9.5, stroke="phosphor")
    f.box(520, 20, 160, 40, [t["red"]], mono=True, size=9.5, stroke="amber")
    f.arrow([(460, 40), (520, 40)], both=True, color="amber")
    for i, k in enumerate(("c1", "c2", "c3")):
        x = 60 + i * 220
        f.box(x, 160, 160, 40, [t[k]], size=9.5)
        f.arrow([(330, 60), (x + 80, 160)])
    f.text(170, 112, t["read"], mono=True, size=9, fill="paper-dim")
    f.text(560, 120, t["act"], mono=True, size=9, fill="amber")
    f.arrow([(580, 160), (600, 64)], dashed=True, color="amber")
    return {"l09-context": f.json(caption=t["cap"], same=None if lang == "en" else ["Courses", "This week", "Course"])}
