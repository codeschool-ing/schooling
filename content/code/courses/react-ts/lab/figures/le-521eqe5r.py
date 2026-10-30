from fig import Fig

steps = Fig("three-steps", 720, 190,
            {"en": "Three boxes in a row. Trigger: the first render, or a state setter being called. Render: React calls "
                   "the components and collects a new tree, with nothing on the page changed. Commit: React compares "
                   "the new tree with the last one and changes the page only where they differ. The page is touched "
                   "only in the third box.",
             "pt": "Três caixas em fila. Gatilho: a primeira renderização, ou um setter de estado sendo chamado. "
                   "Renderização: o React chama os componentes e junta uma árvore nova, sem nada mudar na página. "
                   "Commit: o React compara a árvore nova com a anterior e muda a página só onde elas diferem. A "
                   "página só é tocada na terceira caixa."},
            {"en": "Only the commit touches the page. Everything before it can be repeated or thrown away.",
             "pt": "Só o commit toca na página. Tudo antes dele pode ser repetido ou descartado."})
cols = [({"en": "1 · trigger", "pt": "1 · gatilho"}, [{"en": "first render, or", "pt": "primeira renderização, ou"}, "setMonday(…)"]),
        ({"en": "2 · render", "pt": "2 · renderização"}, [{"en": "call App, then its", "pt": "chamar App, depois os"}, {"en": "children, down the tree", "pt": "filhos, árvore abaixo"}]),
        ({"en": "3 · commit", "pt": "3 · commit"}, [{"en": "compare with last tree,", "pt": "comparar com a árvore anterior,"}, {"en": "change only the difference", "pt": "mudar só a diferença"}])]
for i, (head, lines) in enumerate(cols):
    x = 20 + i * 240
    steps.text(x + 100, 26, head, anchor="middle", tone="phosphor" if i < 2 else "amber", size=12)
    steps.box(x, 44, 200, 80, (), tone="phosphor" if i < 2 else "amber")
    for j, l in enumerate(lines):
        mono = isinstance(l, str)
        steps.text(x + 100, 72 + j * 22, l, anchor="middle", mono=mono, tone="paper", size=10.5 if mono else 11)
    if i < 2:
        steps.arrow(x + 202, 84, x + 238, 84)
steps.line(20, 150, 460, 150, tone="wire", dashed=True)
steps.text(240, 168, {"en": "nothing on the page changes", "pt": "nada muda na página"}, anchor="middle", tone="dim", size=10.5)
steps.line(500, 150, 700, 150, tone="amber")
steps.text(600, 168, {"en": "the page changes here", "pt": "a página muda aqui"}, anchor="middle", tone="amber", size=10.5)

cas = Fig("cascade", 720, 250,
          {"en": "The planner's tree with App's state changed. Every component under App is drawn highlighted, because "
                 "every one of them rendered again: WeekNav, WeekSummary, CourseList, the three CourseCards and the "
                 "three Cards. A note says ten calls for one changed value.",
           "pt": "A árvore do planejador com o estado do App mudado. Todo componente abaixo do App aparece destacado, "
                 "porque todos renderizaram de novo: WeekNav, WeekSummary, CourseList, os três CourseCards e os três "
                 "Cards. Uma nota diz dez chamadas para um valor mudado."},
          {"en": "A state change in App renders App and everything below it.",
           "pt": "Uma mudança de estado no App renderiza o App e tudo abaixo dele."})
cas.box(290, 14, 140, 32, ["App", "monday ← changed"], mono=True, tone="amber", size=9.5)
for x, n in ((70, "WeekNav"), (250, "WeekSummary"), (470, "CourseList")):
    cas.box(x, 86, 150, 28, n, mono=True, tone="amber")
    cas.arrow(360, 46, x + 75, 86, tone="amber")
for i in range(3):
    x = 330 + i * 130
    cas.box(x, 150, 110, 26, "CourseCard", mono=True, tone="amber")
    cas.arrow(545, 114, x + 55, 150, tone="amber")
    cas.box(x + 20, 206, 70, 24, "Card", mono=True, tone="amber")
    cas.arrow(x + 55, 176, x + 55, 206, tone="amber")
cas.text(30, 170, {"en": "1 value changed,", "pt": "1 valor mudou,"}, tone="paper", size=11)
cas.text(30, 190, {"en": "10 components called", "pt": "10 componentes chamados"}, tone="amber", size=11)

diff = Fig("diff", 720, 250,
           {"en": "Two columns of the same tree, before and after the click. Most nodes are drawn the same in both and "
                  "are labelled kept. Only the text nodes differ: 19 Oct 2026 becomes 26 Oct 2026, 80 and 195 become 0, "
                  "and the course lines change their numbers. Arrows mark the ten text changes; no element is added or removed.",
            "pt": "Duas colunas da mesma árvore, antes e depois do clique. A maioria dos nós aparece igual nas duas e "
                  "está marcada como mantida. Só os nós de texto diferem: 19 Oct 2026 vira 26 Oct 2026, 80 e 195 viram 0, "
                  "e as linhas dos cursos mudam os números. Setas marcam as dez mudanças de texto; nenhum elemento é "
                  "criado ou removido."},
           {"en": "The commit compares two trees and writes only the difference.",
            "pt": "O commit compara duas árvores e escreve só a diferença."})
diff.text(170, 22, {"en": "last tree", "pt": "árvore anterior"}, anchor="middle", tone="dim", size=10.5)
diff.text(550, 22, {"en": "new tree", "pt": "árvore nova"}, anchor="middle", tone="dim", size=10.5)
rows = [("<h1> Study planner", "<h1> Study planner", False),
        ("<button> Previous week", "<button> Previous week", False),
        ("<p> Week of 19 Oct 2026", "<p> Week of 26 Oct 2026", True),
        ("<p> 80 of 195 minutes done", "<p> 0 of 0 minutes done", True),
        ("<h2> Statistics", "<h2> Statistics", False),
        ("<p> 2 sessions · 90 min", "<p> 0 sessions · 0 min", True),
        ("<h2> Organic chemistry", "<h2> Organic chemistry", False),
        ("<p> 1 session · 45 min", "<p> 0 sessions · 0 min", True)]
for i, (a, b, changed) in enumerate(rows):
    y = 38 + i * 25
    tone = "amber" if changed else "wire"
    diff.box(40, y, 260, 20, a, mono=True, tone=tone, text_tone="paper", size=9.5)
    diff.box(420, y, 260, 20, b, mono=True, tone=tone, text_tone="amber" if changed else "paper", size=9.5)
    if changed:
        diff.arrow(302, y + 10, 418, y + 10, tone="amber")
    else:
        diff.text(360, y + 10, {"en": "kept", "pt": "mantido"}, anchor="middle", tone="dim", size=10)
diff.text(360, 242, {"en": "only text changed: 10 characterData records", "pt": "só o texto mudou: 10 registros characterData"},
          anchor="middle", tone="amber", size=10.5)

ident = Fig("identity", 720, 230,
            {"en": "Two cases side by side. On the left, after Next week the first CourseCard still holds a Card that "
                   "holds a Probe at the same place, so React keeps its count of 2. On the right, CourseList has the "
                   "key 2026-10-19 before and 2026-10-26 after; a different key is a different component, so the "
                   "whole subtree is created again and the count is 0.",
             "pt": "Dois casos lado a lado. À esquerda, depois de Next week o primeiro CourseCard ainda tem um Card que "
                   "tem um Probe no mesmo lugar, então o React mantém a contagem 2. À direita, o CourseList tem a key "
                   "2026-10-19 antes e 2026-10-26 depois; uma key diferente é um componente diferente, então a "
                   "subárvore inteira é criada de novo e a contagem é 0."},
            {"en": "Same type at the same position keeps its state; a new key starts again.",
             "pt": "O mesmo tipo na mesma posição mantém o estado; uma key nova começa do zero."})
for side, (x0, title, key_a, key_b, after, tone) in enumerate([
        (20, {"en": "same position: kept", "pt": "mesma posição: mantido"}, "CourseList", "CourseList", "Probe · 2", "phosphor"),
        (380, {"en": "new key: started again", "pt": "key nova: recomeçou"}, "key=2026-10-19", "key=2026-10-26", "Probe · 0", "amber")]):
    ident.text(x0 + 160, 22, title, anchor="middle", tone=tone, size=11.5)
    for col, (label, last) in enumerate([(key_a, "Probe · 2"), (key_b, after)]):
        cx = x0 + 10 + col * 170
        ident.text(cx + 70, 46, {"en": "before" if col == 0 else "after", "pt": "antes" if col == 0 else "depois"},
                   anchor="middle", tone="dim", size=10)
        for j, n in enumerate([label, "CourseCard", "Card", last]):
            t = tone if (col == 1 and (j == 3 or (side == 1 and j == 0))) else "wire"
            ident.box(cx, 58 + j * 40, 140, 26, n, mono=True, tone=t, text_tone="paper" if t == "wire" else t, size=10)
            if j < 3:
                ident.arrow(cx + 70, 84 + j * 40, cx + 70, 98 + j * 40)

FIGS = [steps, cas, diff, ident]
