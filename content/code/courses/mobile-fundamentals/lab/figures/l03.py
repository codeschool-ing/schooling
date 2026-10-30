"""Lesson 3: the matrix as an example, the flip as bars, and the track's fork."""
from fig import Fig

EXAMPLES = {
    "the-matrix": [
        {"language": "typescript", "file": "choose.ts", "parts": [
            ('// choose.ts: criteria, approaches and weights, for one team\'s decision\ntype Approach = "native" | "react-native" | "flutter" | "kmp" | "wrapper";\ntype Row = Record<Approach, number>;\n\n// How much each criterion matters to this team: 0 (not at all) to 5.\nconst weights: Record<string, number> = {\n  languages: 4,\n  features: 2,\n  performance: 2,\n  time: 3,\n  platforms: 3,\n  cost: 3,\n  hiring: 2,\n};\n',
             "The weights: the team's priorities, and the part of the file to argue about first. Zero means the criterion does not count at all.",
             "Os pesos: as prioridades da equipe, e a parte do arquivo a discutir primeiro. Zero quer dizer que o critério não conta nada."),
            ('// How well each approach serves each criterion, for this team: 1 to 5.\nconst scores: Record<string, Row> = {\n  languages:   { native: 1, "react-native": 5, flutter: 2, kmp: 1, wrapper: 5 },\n  features:    { native: 5, "react-native": 4, flutter: 4, kmp: 5, wrapper: 3 },\n  performance: { native: 5, "react-native": 4, flutter: 4, kmp: 5, wrapper: 2 },\n  time:        { native: 1, "react-native": 3, flutter: 3, kmp: 2, wrapper: 5 },\n  platforms:   { native: 2, "react-native": 5, flutter: 5, kmp: 4, wrapper: 5 },\n  cost:        { native: 2, "react-native": 4, flutter: 4, kmp: 3, wrapper: 3 },\n  hiring:      { native: 4, "react-native": 4, flutter: 3, kmp: 2, wrapper: 4 },\n};\n',
             "The scores, one row per criterion. `languages` gives React Native and the wrapper 5 because this team writes TypeScript; `time` gives the wrapper 5 because the team's web app already has its screens. Another team fills in different numbers.",
             "As notas, uma linha por critério. `languages` dá 5 ao React Native e ao embrulho porque esta equipe escreve TypeScript; `time` dá 5 ao embrulho porque o app web da equipe já tem as telas. Outra equipe preenche números diferentes."),
            ('function fail(message: string): never {\n  console.error(message);\n  process.exit(1);\n}\n\n// node choose.ts time=5 changes one weight for this run.\nfor (const arg of process.argv.slice(2)) {\n  const [name, value] = arg.split("=");\n  if (!(name in weights)) fail(`no criterion "${name}"; there are: ${Object.keys(weights).join(", ")}`);\n  const w = Number(value);\n  if (!Number.isInteger(w) || w < 0 || w > 5) fail(`the weight of ${name} must be 0 to 5, not "${value}"`);\n  weights[name] = w;\n}\n',
             "A weight can be changed from the command line, for one run, without editing the file. A name that is not a criterion, or a weight outside 0 to 5, stops the program instead of being ignored.",
             "Um peso pode ser mudado na linha de comando, para uma execução, sem editar o arquivo. Um nome que não é critério, ou um peso fora de 0 a 5, para o programa em vez de ser ignorado."),
            ('const approaches = Object.keys(scores.languages) as Approach[];\nconst ranked = approaches\n  .map((a) => ({ a, total: Object.keys(weights).reduce((sum, c) => sum + weights[c] * scores[c][a], 0) }))\n  .sort((x, y) => y.total - x.total);\n\nconsole.log("weights:", Object.entries(weights).map(([c, w]) => `${c} ${w}`).join(", "));\nfor (const { a, total } of ranked) console.log(String(total).padStart(4), a);',
             "Each approach's total is the sum of weight times score over the seven criteria, and the list is printed highest first, under the weights that produced it.",
             "O total de cada abordagem é a soma de peso vezes nota nos sete critérios, e a lista sai do maior para o menor, embaixo dos pesos que a produziram."),
        ]},
    ],
}

RUNS = [  # (approach, total with time 3, total with time 5), from the capture
    ("react-native", 80, 86), ("wrapper", 77, 87), ("flutter", 66, 72), ("kmp", 55, 59), ("native", 47, 49),
]

T = {
    "en": dict(
        aria1="Two bar charts of the planner's matrix. With time to market weighted 3: React Native 80, wrapper 77, Flutter 66, Kotlin Multiplatform 55, native 47. With time to market weighted 5, and nothing else changed: wrapper 87, React Native 86, Flutter 72, Kotlin Multiplatform 59, native 49. The first two places swap.",
        left="time weighted 3", right="time weighted 5",
        cap1="One weight moved by two points, and the first two places swap. The scores did not change; what the team wants did.",
        aria2="The mobile track as a line of courses. web-fundamentals, git and mobile-fundamentals come first. Then the fork, which way to build: Android with Kotlin, through kotlin and android-apps; iOS with Swift, through swift and ios-apps; or multiplatform with React Native, through javascript and react-native. The three routes meet again at mobile-offline, then testing-cicd and mobile-delivery.",
        trunk="the trunk, for everyone", fork="the fork: one route",
        a="Android with Kotlin", i="iOS with Swift", r="React Native",
        meet="together again",
        cap2="The fork after this course is lesson 3's question asked once, for real. All three routes come back together at mobile-offline.",
    ),
    "pt": dict(
        aria1="Dois gráficos de barras da matriz do planner. Com tempo até a loja de peso 3: React Native 80, embrulho 77, Flutter 66, Kotlin Multiplatform 55, nativo 47. Com tempo até a loja de peso 5, e nada mais mudado: embrulho 87, React Native 86, Flutter 72, Kotlin Multiplatform 59, nativo 49. As duas primeiras posições trocam.",
        left="time com peso 3", right="time com peso 5",
        cap1="Um peso subiu dois pontos, e as duas primeiras posições trocam. As notas não mudaram; o que a equipe quer mudou.",
        aria2="A trilha mobile como uma linha de cursos. web-fundamentals, git e mobile-fundamentals vêm primeiro. Depois a bifurcação, o jeito de construir: Android com Kotlin, por kotlin e android-apps; iOS com Swift, por swift e ios-apps; ou multiplataforma com React Native, por javascript e react-native. Os três caminhos se encontram de novo em mobile-offline, depois testing-cicd e mobile-delivery.",
        trunk="o tronco, para todos", fork="a bifurcação: um caminho",
        a="Android com Kotlin", i="iOS com Swift", r="React Native",
        meet="juntos de novo",
        cap2="A bifurcação depois deste curso é a pergunta da aula 3 feita uma vez, de verdade. Os três caminhos voltam a se juntar em mobile-offline.",
    ),
}


def flip(t):
    f = Fig("l03-flip", 720, 210, t["aria1"])
    scale = 2.2
    for col, (x0, title, idx) in enumerate([(20, t["left"], 1), (380, t["right"], 2)]):
        f.text(x0, 18, title, anchor="start", bold=True, size=10, mono=False,
               fill="paper" if col == 0 else "amber")
        rows = sorted(RUNS, key=lambda r: -r[idx])
        for k, r in enumerate(rows):
            y = 36 + k * 32
            f.text(x0 + 92, y + 11, r[0], anchor="end", mono=True, size=9.5)
            first = k == 0
            f.rect(x0 + 100, y, round(r[idx] * scale), 22, stroke="amber" if first else "wire",
                   fill="panel")
            f.text(x0 + 106 + round(r[idx] * scale), y + 11, str(r[idx]), anchor="start", mono=True,
                   size=9.5, fill="amber" if first else "paper-dim")
    return f


def fork(t):
    f = Fig("l03-fork", 780, 215, t["aria2"])
    f.text(10, 16, t["trunk"], anchor="start", italic=True, size=9.5, fill="paper-dim")
    for x, w, s in [(10, 112, "web-fundamentals"), (132, 40, "git"), (182, 126, "mobile-fundamentals")]:
        f.box(x, 92, w, 32, [s], mono=True, size=9, stroke="amber" if s == "mobile-fundamentals" else "wire")
    f.arrow([(122, 108), (130, 108)])
    f.arrow([(172, 108), (180, 108)])
    f.text(455, 16, t["fork"], italic=True, size=9.5, fill="amber")
    routes = [(t["a"], "kotlin", "android-apps"), (t["i"], "swift", "ios-apps"), (t["r"], "javascript", "react-native")]
    for k, (name, c1, c2) in enumerate(routes):
        y = 34 + k * 64
        f.text(455, y, name, bold=True, size=9.5)
        f.box(360, y + 10, 78, 30, [c1], mono=True, size=9)
        f.box(450, y + 10, 100, 30, [c2], mono=True, size=9)
        f.arrow([(438, y + 25), (448, y + 25)])
        f.arrow([(308, 108), (358, y + 25)])
        f.arrow([(550, y + 25), (580, 108)])
    f.text(630, 60, t["meet"], italic=True, size=9.5, fill="paper-dim")
    f.box(582, 92, 96, 32, ["mobile-offline"], mono=True, size=9)
    f.box(688, 95, 88, 26, ["testing-cicd"], mono=True, size=9)
    f.box(688, 150, 88, 26, ["mobile-delivery"], mono=True, size=9)
    f.arrow([(678, 108), (686, 108)])
    f.arrow([(732, 121), (732, 148)])
    return f


def figures(lang):
    t = T[lang]
    return {
        "l03-flip": flip(t).json(t["cap1"]),
        "l03-fork": fork(t).json(t["cap2"], same=["React Native"] if lang == "pt" else None),
    }
