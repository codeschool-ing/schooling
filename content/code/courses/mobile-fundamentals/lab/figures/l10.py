"""Lesson 10: the four navigation shapes, the stacks per tab over time, and
backstack.ts as an annotated example."""
from fig import Fig

T = {
    "en": dict(
        aria1="Four navigation shapes, each drawn as a phone screen. A stack: three screens piled up, courses at the root, a course on it and a new-session form on top; only the top one shows, opening pushes and back pops. Tabs: two piles side by side, Courses and Week, with a bar at the bottom to switch between them; each keeps its own pile. A drawer: a panel of destinations slid in over the screen from the left. A sheet: a panel risen from the bottom over the current screen, for one task, with the screen under it unchanged.",
        t_stack="stack", t_tabs="tabs", t_drawer="drawer", t_sheet="sheet",
        root="(root)", push="push", pop="back pops",
        bar="tab bar",
        dests=["destination 1", "destination 2", "destination 3"],
        dnote=["slides in", "over the screen"],
        under="the screen under it",
        sheet=["one short task"],
        snote=["closing it changes", "nothing underneath"],
        tnote=["each tab keeps", "its own pile"],
        cap1="Four shapes, and what back means in each: a stack pops its top screen, tabs pop inside the tab showing, and a drawer or a sheet closes.",
        aria2="The Courses and Week stacks at seven moments of the session in taps.ts. After opening new-session, Courses holds courses, course:sql and new-session, and Week holds week. After opening session:s3 on Week, Week holds week and session:s3 while Courses is unchanged. After Android back on Courses, Courses loses new-session. After a second tap on Courses, Courses holds only its root. Then on Week, back pops session:s3, the next back switches to Courses, and the last back finds Courses at its root and the app leaves.",
        showing="the tab showing", row="row",
        leaves="the app leaves",
        cap2="Each tab's pile changes only while that tab is showing. The last three back presses pop, switch to the start tab, and leave.",
    ),
    "pt": dict(
        aria1="Quatro formatos de navegação, cada um desenhado como uma tela de celular. Uma pilha: três telas empilhadas, courses na raiz, um curso por cima e um formulário de nova sessão no topo; só a de cima aparece, abrir empilha e voltar desempilha. Abas: duas pilhas lado a lado, Courses e Week, com uma barra embaixo para trocar entre elas; cada uma guarda a própria pilha. Uma gaveta: um painel de destinos que desliza da esquerda por cima da tela. Uma folha: um painel que sobe de baixo por cima da tela atual, para uma tarefa, com a tela de baixo intacta.",
        t_stack="pilha", t_tabs="abas", t_drawer="gaveta", t_sheet="folha",
        root="(raiz)", push="empilha", pop="voltar desempilha",
        bar="barra de abas",
        dests=["destino 1", "destino 2", "destino 3"],
        dnote=["desliza por", "cima da tela"],
        under="a tela por baixo",
        sheet=["uma tarefa curta"],
        snote=["fechar não muda", "nada embaixo"],
        tnote=["cada aba guarda", "a própria pilha"],
        cap1="Quatro formatos, e o que voltar significa em cada um: a pilha desempilha a tela do topo, as abas desempilham dentro da aba que aparece, e uma gaveta ou uma folha se fecha.",
        aria2="As pilhas de Courses e de Week em sete momentos da sessão de taps.ts. Depois de abrir new-session, Courses tem courses, course:sql e new-session, e Week tem week. Depois de abrir session:s3 em Week, Week tem week e session:s3 e Courses não muda. Depois do voltar do Android em Courses, Courses perde new-session. Depois de um segundo toque em Courses, Courses fica só com a raiz. Então, em Week, voltar desempilha session:s3, o voltar seguinte troca para Courses, e o último voltar encontra Courses na raiz e o app sai.",
        showing="a aba que aparece", row="linha",
        leaves="o app sai",
        cap2="A pilha de cada aba só muda enquanto aquela aba aparece. Os três últimos voltar desempilham, trocam para a aba inicial e saem.",
    ),
}


def shapes(t):
    f = Fig("l10-shapes", 720, 280, t["aria1"])
    xs = [20, 200, 380, 560]
    for x, title in zip(xs, [t["t_stack"], t["t_tabs"], t["t_drawer"], t["t_sheet"]]):
        f.text(x + 70, 18, title, bold=True, size=11, fill="phosphor")
        f.rect(x, 32, 140, 230, stroke="wire", fill="ink", rx=12)
    # stack: three screens, offset
    x = xs[0]
    for i, (name, s) in enumerate([("courses", "wire"), ("course:sql", "wire"), ("new-session", "phosphor")]):
        f.box(x + 14 + i * 8, 150 - i * 34, 104, 44, [name], stroke=s, mono=True, size=9)
    f.text(x + 66, 206, t["root"], size=9, fill="paper-dim")
    f.text(x + 70, 228, t["push"] + " · " + t["pop"], size=9, fill="paper-dim")
    # tabs: two piles and a bar
    x = xs[1]
    for i, (name, s) in enumerate([("courses", "phosphor"), ("course:sql", "phosphor")]):
        f.box(x + 10, 120 - i * 30, 60, 26, [name], stroke=s, mono=True, size=7.5)
    f.box(x + 76, 120, 54, 26, ["week"], stroke="wire", mono=True, size=7.5)
    f.text(x + 70, 168, t["tnote"][0], size=9, fill="paper-dim")
    f.text(x + 70, 181, t["tnote"][1], size=9, fill="paper-dim")
    f.rect(x + 6, 222, 128, 32, stroke="wire", fill="panel", rx=4)
    f.text(x + 38, 238, "Courses", size=9, fill="phosphor", bold=True)
    f.text(x + 102, 238, "Week", size=9, fill="paper-dim")
    f.text(x + 70, 208, t["bar"], size=8.5, fill="paper-dim", italic=True)
    # drawer
    x = xs[2]
    f.rect(x + 2, 34, 92, 226, stroke="phosphor", fill="panel", rx=10)
    for i, d in enumerate(t["dests"]):
        f.text(x + 12, 64 + i * 24, d, anchor="start", size=9)
    f.text(x + 48, 150, t["dnote"][0], size=8.5, fill="paper-dim")
    f.text(x + 48, 162, t["dnote"][1], size=8.5, fill="paper-dim")
    f.arrow([(x + 60, 200), (x + 86, 200)], color="phosphor")
    # sheet
    x = xs[3]
    f.text(x + 70, 60, t["under"], size=9, fill="paper-dim")
    f.box(x + 4, 120, 132, 140, t["sheet"], stroke="phosphor", size=9.5)
    f.text(x + 70, 210, t["snote"][0], size=8.5, fill="paper-dim")
    f.text(x + 70, 222, t["snote"][1], size=8.5, fill="paper-dim")
    f.arrow([(x + 70, 116), (x + 70, 90)], color="phosphor")
    return f


SNAPS = [
    ("open new-session", "Courses", ["courses", "course:sql", "new-session"], ["week"]),
    ("open session:s3", "Week", ["courses", "course:sql", "new-session"], ["week", "session:s3"]),
    ("Android back", "Courses", ["courses", "course:sql"], ["week", "session:s3"]),
    ("tap Courses", "Courses", ["courses"], ["week", "session:s3"]),
    ("Android back", "Week", ["courses"], ["week"]),
    ("Android back", "Courses", ["courses"], ["week"]),
    ("Android back", "Courses", ["courses"], ["week"]),
]


def stacks(t):
    f = Fig("l10-stacks", 720, 290, t["aria2"])
    f.text(14, 100, "Courses", anchor="start", bold=True, size=10)
    f.text(14, 222, "Week", anchor="start", bold=True, size=10)
    for i, (label, tab, cs, ws) in enumerate(SNAPS):
        x = 76 + i * 92
        f.text(x + 42, 16, label, mono=True, size=8.5, fill="paper-dim")
        f.text(x + 42, 30, t["row"] + " " + str([3, 5, 7, 8, 10, 11, 12][i]), size=8.5, fill="paper-dim")
        for base, stack, name in ((142, cs, "Courses"), (262, ws, "Week")):
            s = "phosphor" if tab == name else "wire"
            for j, scr in enumerate(stack):
                f.box(x, base - 30 - j * 24, 84, 22, [scr], stroke=s, mono=True, size=8)
    f.rect(76, 150, 7 * 92 - 8, 1, stroke="wire", fill="wire", width=0.6, rx=0)
    f.box(76 + 6 * 92, 160, 84, 22, [t["leaves"]], stroke="amber", fill="amber", size=8.5, dashed=True)
    f.rect(20, 272, 14, 10, stroke="phosphor", fill="panel", rx=2)
    f.text(40, 277, t["showing"], anchor="start", size=9, fill="paper-dim")
    return f


def figures(lang):
    t = T[lang]
    same = None if lang == "en" else ["Courses", "Week"]
    return {
        "l10-shapes": shapes(t).json(t["cap1"], same=same),
        "l10-stacks": stacks(t).json(t["cap2"], same=same),
    }


EXAMPLES = {
    "the-model": [
        {"language": "typescript", "file": "backstack.ts", "parts": [
            ('// backstack.ts: the planner\'s two tabs, each with a stack of its own\nexport type Tab = "Courses" | "Week";\nexport type Nav = { tab: Tab; stacks: Record<Tab, string[]> };\n\n// The tab the app opens on. Back returns here before it leaves the app.\nexport const START: Tab = "Courses";\n\nexport function start(): Nav {\n  return { tab: START, stacks: { Courses: ["courses"], Week: ["week"] } };\n}\n',
             "The whole state of navigation: which tab shows, and one list per tab, root first. `Record<Tab, string[]>` makes TypeScript insist that both tabs have a stack. Each stack starts with its root, and a root is never removed.",
             "O estado inteiro da navegação: qual aba aparece, e uma lista por aba, raiz primeiro. `Record<Tab, string[]>` faz o TypeScript exigir uma pilha para cada aba. Cada pilha começa com a raiz, e uma raiz nunca sai."),
            ('// Open a screen: push it onto the stack of the tab that is showing.\nexport function open(nav: Nav, screen: string): Nav {\n  const stack = [...nav.stacks[nav.tab], screen];\n  return { ...nav, stacks: { ...nav.stacks, [nav.tab]: stack } };\n}\n',
             "Push. Only the stack of the tab showing grows; `[nav.tab]` picks it by name, and the other tab's stack is copied across untouched.",
             "Empilhar. Só cresce a pilha da aba que aparece; `[nav.tab]` a escolhe pelo nome, e a pilha da outra aba é copiada sem mudança."),
            ('// A tap on a tab. Another tab: show it, with its stack as it was left.\n// The tab already showing: go back to that tab\'s first screen.\nexport function tap(nav: Nav, tab: Tab): Nav {\n  if (tab !== nav.tab) return { ...nav, tab };\n  return { ...nav, stacks: { ...nav.stacks, [tab]: nav.stacks[tab].slice(0, 1) } };\n}\n',
             "Switching tabs changes `tab` and nothing else, so each stack waits where it was left. A second tap on the same tab keeps only the root, with `slice(0, 1)`.",
             "Trocar de aba muda `tab` e mais nada, então cada pilha espera onde foi deixada. Um segundo toque na mesma aba deixa só a raiz, com `slice(0, 1)`."),
            ('// Android\'s system back. `left` is true when there was nothing to go back to.\nexport function back(nav: Nav): { nav: Nav; left: boolean } {\n  const stack = nav.stacks[nav.tab];\n  if (stack.length > 1) {\n    return { nav: { ...nav, stacks: { ...nav.stacks, [nav.tab]: stack.slice(0, -1) } }, left: false };\n  }\n  if (nav.tab !== START) return { nav: { ...nav, tab: START }, left: false };\n  return { nav, left: true };\n}\n',
             "Three cases, in order: pop the top screen; at another tab's root, switch to `START`; at the root of `START`, report that the app leaves. The caller learns which happened from `left`, not from comparing states.",
             "Três casos, em ordem: desempilhar a tela do topo; na raiz de outra aba, trocar para `START`; na raiz de `START`, avisar que o app sai. Quem chama descobre o que aconteceu por `left`, sem comparar estados."),
            ("// iOS has no system back: the app draws a back button above any screen\n// that has one under it, and draws none at a tab's first screen.\nexport function backButton(nav: Nav): boolean {\n  return nav.stacks[nav.tab].length > 1;\n}",
             "The iOS half is a question, not a press: whether a back button is drawn at all. At a root there is none, so there is nothing to model beyond this.",
             "A metade iOS é uma pergunta, não um toque: se um botão de voltar é desenhado. Na raiz não há nenhum, então não há nada a modelar além disso."),
        ]},
    ],
}
