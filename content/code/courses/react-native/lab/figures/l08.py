"""Lesson 8: navigation.tsx annotated, and how the navigators nest."""
import pathlib
from fig import Fig

SRC = (pathlib.Path(__file__).parent.parent / "src" / "l08" / "navigation.tsx").read_text().rstrip("\n").split("\n")
blocks, cur = [], []
for line in SRC:
    if line == "" and cur:
        blocks.append(cur); cur = []
    else:
        cur.append(line)
blocks.append(cur)
NOTES = [
 ("The two navigator factories and the three screens. `LinkingOptions` and `NavigatorScreenParams` are types only.",
  "As duas fábricas de navegadores e as três telas. `LinkingOptions` e `NavigatorScreenParams` são só tipos."),
 ("**Every route and its params, in one place.** The tabs take none; the Course screen takes the course's `id`; the stack's `Tabs` route carries the tabs' own state.",
  "**Toda rota e seus parâmetros, num lugar só.** As abas não recebem nenhum; a tela Course recebe o `id` do curso; a rota `Tabs` da pilha carrega o estado das próprias abas."),
 ("The navigators, typed with those params, so `navigate` is checked.",
  "Os navegadores, tipados com esses parâmetros, para o `navigate` ser conferido."),
 ("The tabs. The list draws its own heading, so its tab shows no header; the week's tab is titled. No icons yet, on purpose.",
  "As abas. A lista desenha o próprio título, então a aba dela não mostra cabeçalho; a aba da semana tem título. Ainda sem ícones, de propósito."),
 ("The root stack: the tabs first, the course screen above them. `title` on `Tabs` is what a pushed screen's back button says.",
  "A pilha raiz: as abas primeiro, a tela do curso acima delas. O `title` em `Tabs` é o que diz o botão de voltar de uma tela empilhada."),
 ("Every screen's address, read in the section on addresses.",
  "O endereço de cada tela, lido na seção sobre endereços."),
]
assert len(blocks) == len(NOTES), len(blocks)
parts = [("\n".join(b) + ("\n" if i < len(blocks) - 1 else ""), en, pt) for i, (b, (en, pt)) in enumerate(zip(blocks, NOTES))]
EXAMPLES = {"stack-and-tabs": [{"language": "tsx", "file": "src/navigation.tsx", "parts": parts}]}

T = {
 "en": dict(aria="The planner's navigators. The root is a native stack. Its first screen is Tabs, a bottom-tab navigator holding Courses and This week. Above the tabs, the stack can push Course, with an id. Pushing Course covers the tab bar; going back returns to the tab the person was on.",
   stack="root: native stack", tabs="Tabs: bottom tabs", courses="Courses", week="This week", course="Course { id }",
   push="push", back="back", cap="Navigators nest: a course's screen sits in the stack above the tabs, so back returns to whichever tab was open."),
 "pt": dict(aria="Os navegadores do planner. A raiz é uma pilha nativa. A primeira tela dela é Tabs, um navegador de abas inferiores com Courses e This week. Acima das abas, a pilha pode empilhar Course, com um id. Empilhar Course cobre a barra de abas; voltar devolve à aba em que a pessoa estava.",
   stack="raiz: pilha nativa", tabs="Tabs: abas inferiores", courses="Courses", week="This week", course="Course { id }",
   push="empilha", back="volta", cap="Navegadores se aninham: a tela de um curso fica na pilha acima das abas, então voltar devolve à aba que estava aberta."),
}


def figures(lang):
    t = T[lang]
    f = Fig("l08-nesting", 720, 230, t["aria"])
    f.text(110, 20, t["stack"], size=10, fill="phosphor", bold=True)
    f.rect(20, 34, 380, 170, stroke="phosphor", fill="ink", dashed=True)
    f.text(130, 56, t["tabs"], size=9.5, fill="paper-dim", bold=True)
    f.box(40, 70, 150, 40, [t["courses"]], size=9.5)
    f.box(40, 130, 150, 40, [t["week"]], size=9.5)
    f.box(230, 100, 150, 40, [t["course"]], mono=True, size=9.5, stroke="amber")
    f.arrow([(190, 90), (230, 112)], color="amber")
    f.text(214, 84, t["push"], size=9, fill="amber", italic=True)
    f.arrow([(230, 128), (190, 150)], dashed=True)
    f.text(212, 160, t["back"], size=9, fill="paper-dim", italic=True)
    return {"l08-nesting": f.json(caption=t["cap"], same=None if lang == "en" else ["Courses", "This week"])}
