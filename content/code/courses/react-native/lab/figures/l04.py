"""Lesson 4: PlanScreen, annotated, and the tree of native views it becomes."""
import pathlib
from fig import Fig

SRC = (pathlib.Path(__file__).parent.parent / "src" / "l04" / "PlanScreen.tsx").read_text().rstrip("\n").split("\n")
CUTS = [(0, 6), (6, 8), (8, 14), (14, 20), (20, 23), (23, 34), (34, 38)]
NOTES = [
 ("`useState` is the one piece of React state on this screen. The components come from `react-native`, the rules from lesson 3's `src/planner.ts`, unchanged.",
  "O `useState` é o único pedaço de estado React desta tela. Os componentes vêm de `react-native`, as regras do `src/planner.ts` da aula 3, sem mudança."),
 ("The screen takes the plan and the date as props rather than reading them itself, so a test can hand it any plan and any day.",
  "A tela recebe o plano e a data como props em vez de lê-los sozinha, então um teste pode lhe entregar qualquer plano e qualquer dia."),
 ("Everything computed here is recomputed on each render, from the props and the state: the total, and the course that is open, if any. The whole screen scrolls, with its padding on the content.",
  "Tudo o que é calculado aqui é recalculado a cada renderização, a partir das props e do estado: o total, e o curso aberto, se houver. A tela inteira rola, com o padding no conteúdo."),
 ("A row: the icon and the heading side by side. The icon is decorative, so `aria-hidden`; the heading has `role=\"heading\"`, which a screen reader uses to find it.",
  "Uma linha: o ícone e o título lado a lado. O ícone é decorativo, por isso `aria-hidden`; o título tem `role=\"heading\"`, que um leitor de tela usa para encontrá-lo."),
 ("The total, as one `Text` with the numbers in braces, so it is one sentence to a screen reader.",
  "O total, como um único `Text` com os números entre chaves, para ser uma frase só para um leitor de tela."),
 ("The list. `role=\"list\"` and `role=\"listitem\"` let a screen reader say *list, three items*. `map` turns each course into an element, and `key` tells React which element is which course from one render to the next; lesson 7 explains why it must be the id.",
  "A lista. `role=\"list\"` e `role=\"listitem\"` deixam um leitor de tela dizer *lista, três itens*. O `map` transforma cada curso num elemento, e o `key` diz ao React qual elemento é qual curso de uma renderização para a outra; a aula 7 explica por que precisa ser o id."),
 ("Shown only when a course is open. `role=\"status\"` makes a screen reader announce it when it appears, without moving the user's place.",
  "Mostrado só quando há um curso aberto. O `role=\"status\"` faz um leitor de tela anunciá-lo quando aparece, sem mudar o lugar do usuário."),
]
parts = []
for i, ((a, b), (en, pt)) in enumerate(zip(CUTS, NOTES)):
    code = "\n".join(SRC[a:b])
    parts.append((code, en, pt))
assert "\n".join(p[0] for p in parts) == "\n".join(SRC), "cuts lose lines"
EXAMPLES = {"the-screen": [{"language": "tsx", "file": "src/PlanScreen.tsx", "parts": parts}]}

T = {
 "en": dict(aria="The planner's first screen as a tree of components, and what each becomes on Android and on iOS. ScrollView becomes a native scroll view; View becomes a ViewGroup or a UIView; Image becomes an ImageView or a UIImageView; Text becomes a TextView or a UILabel; Pressable becomes a native view that receives touches.",
   comp="your components", and_="Android", ios="iOS", cap="Each component in your tree is one native view on each platform, created by Fabric on the main thread."),
 "pt": dict(aria="A primeira tela do planner como uma árvore de componentes, e no que cada um se transforma no Android e no iOS. ScrollView vira uma scroll view nativa; View vira um ViewGroup ou uma UIView; Image vira uma ImageView ou uma UIImageView; Text vira uma TextView ou um UILabel; Pressable vira uma view nativa que recebe toques.",
   comp="os seus componentes", and_="Android", ios="iOS", cap="Cada componente da sua árvore é uma view nativa em cada plataforma, criada pelo Fabric na thread principal."),
}
ROWS = [("<ScrollView>", 0, "ScrollView", "UIScrollView"), ("<View>", 1, "ViewGroup", "UIView"),
        ("<Image>", 2, "ImageView", "UIImageView"), ("<Text>", 2, "TextView", "UILabel"),
        ("<Pressable>", 2, "ViewGroup + touch", "UIView + touch")]


def figures(lang):
    t = T[lang]
    f = Fig("l04-tree", 720, 250, t["aria"])
    f.text(130, 20, t["comp"], size=10, fill="phosphor", bold=True)
    f.text(450, 20, t["and_"], size=10, fill="paper-dim", bold=True)
    f.text(620, 20, t["ios"], size=10, fill="paper-dim", bold=True)
    for i, (c, depth, a, b) in enumerate(ROWS):
        y = 36 + i * 42
        x = 30 + depth * 30
        f.box(x, y, 170, 30, [c], mono=True, size=9.5, stroke="phosphor")
        f.arrow([(x + 170, y + 15), (370, y + 15)], dashed=True)
        f.box(370, y, 160, 30, [a], mono=True, size=9.5)
        f.box(550, y, 140, 30, [b], mono=True, size=9.5)
    return {"l04-tree": f.json(caption=t["cap"], same=None if lang == "en" else ["Android", "iOS"])}
