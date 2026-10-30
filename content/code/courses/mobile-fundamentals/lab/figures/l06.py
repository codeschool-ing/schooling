"""Lesson 6: the frame budget as slots, the two threads, and frames.ts as an annotated example."""
from fig import Fig

T = {
    "en": dict(
        f_aria="Twelve frame slots of 16.67 ms each, 200 ms in all. In the top row every task is short and a frame is drawn in every slot. In the bottom row the first two frames are drawn, then one task of 75 ms holds the main thread from the third slot to the middle of the seventh; the four frames due while it runs are dropped, and drawing resumes in the seventh slot.",
        f_head="the display asks for a frame every 16.67 ms (60 Hz)",
        f_a=["short tasks"], f_b=["one long", "task"],
        drawn="drawn", missed="dropped", task="one 75 ms task",
        f_cap="A slot either gets its frame or loses it. The 75 ms task covers four frame deadlines, so four frames are never drawn, and the screen shows the same picture for 83 ms.",
        t_aria="Two timelines. In the first, the main thread draws frames, then sorts the sessions, and no frame is drawn until the sort ends. In the second, the main thread sends go to a worker and keeps drawing a frame in every slot while the worker sorts; the worker sends the result back and the main thread shows it.",
        t_a="the sort on the main thread", t_b="the same sort on a worker",
        main=["main", "thread"], worker=["worker"],
        frame="frame", sort_main="sort: no frame is drawn meanwhile", sort_w="sort",
        go="go", result="result",
        t_cap="Moving the work does not make it faster. It makes it someone else's: the main thread keeps every slot, and only the result crosses back to it.",
    ),
    "pt": dict(
        f_aria="Doze espaços de quadro de 16,67 ms cada, 200 ms ao todo. Na linha de cima toda tarefa é curta e um quadro é desenhado em cada espaço. Na linha de baixo os dois primeiros quadros são desenhados, depois uma tarefa de 75 ms ocupa a thread principal do terceiro espaço até o meio do sétimo; os quatro quadros devidos enquanto ela roda são descartados, e o desenho volta no sétimo espaço.",
        f_head="a tela pede um quadro a cada 16,67 ms (60 Hz)",
        f_a=["tarefas curtas"], f_b=["uma tarefa", "longa"],
        drawn="feito", missed="perdido", task="uma tarefa de 75 ms",
        f_cap="Um espaço ganha o seu quadro ou o perde. A tarefa de 75 ms cobre quatro prazos de quadro, então quatro quadros nunca são desenhados, e a tela mostra a mesma imagem por 83 ms.",
        t_aria="Duas linhas do tempo. Na primeira, a thread principal desenha quadros, depois ordena as sessões, e nenhum quadro é desenhado até a ordenação acabar. Na segunda, a thread principal manda go a um worker e continua desenhando um quadro em cada espaço enquanto o worker ordena; o worker devolve o resultado e a thread principal o mostra.",
        t_a="a ordenação na thread principal", t_b="a mesma ordenação num worker",
        main=["thread", "principal"], worker=["worker"],
        frame="quadro", sort_main="ordenação: nenhum quadro enquanto isso", sort_w="ordenação",
        go="go", result="resultado",
        t_cap="Mudar o trabalho de lugar não o deixa mais rápido. Deixa-o com outro: a thread principal mantém todos os espaços, e só o resultado volta para ela.",
    ),
}


def frames(t):
    f = Fig("l06-frames", 720, 215, t["f_aria"])
    x0, w = 110, 48
    f.text(x0, 22, t["f_head"], anchor="start", size=10, fill="paper-dim", italic=True)
    for i, s in enumerate(t["f_a"]):
        f.text(20, 58 + i * 13, s, anchor="start", size=10)
    for k in range(12):
        f.box(x0 + k * w + 2, 44, w - 4, 28, [t["drawn"]], stroke="phosphor", size=9)
    for i, s in enumerate(t["f_b"]):
        f.text(20, 134 + i * 13 - 6, s, anchor="start", size=10)
    # the task: from slot 2.0 to slot 6.5
    f.rect(x0 + 2 * w, 92, int(4.5 * w), 20, stroke="amber", fill="panel")
    f.text(x0 + 2 * w + int(4.5 * w) / 2, 102, t["task"], size=9.5, fill="amber")
    for k in range(12):
        lost = 2 <= k <= 5
        f.box(x0 + k * w + 2, 120, w - 4, 28, [t["missed"] if lost else t["drawn"]],
              stroke="amber" if lost else "phosphor", dashed=lost, size=9,
              fill="amber" if lost else "paper")
    f.arrow([(x0, 170), (x0 + 12 * w + 6, 170)], color="wire")
    for k in range(0, 13, 3):
        x = x0 + k * w
        f.arrow([(x, 166), (x, 174)], color="wire", head=False)
        f.text(x, 188, f"{k * 50 // 3} ms", size=9, fill="paper-dim")
    return f


def threads(t):
    f = Fig("l06-two-threads", 720, 270, t["t_aria"])
    f.text(20, 20, t["t_a"], anchor="start", bold=True, size=10.5, fill="amber")
    for i, s in enumerate(t["main"]):
        f.text(20, 52 + i * 13, s, anchor="start", size=9.5)
    for x in (100, 144):
        f.box(x, 44, 40, 26, [t["frame"]], stroke="phosphor", size=9)
    f.box(188, 44, 340, 26, [t["sort_main"]], stroke="amber", size=9.5, fill="amber")
    for x in (532, 576, 620, 664):
        f.box(x, 44, 40, 26, [t["frame"]], stroke="phosphor", size=9)
    f.text(20, 108, t["t_b"], anchor="start", bold=True, size=10.5, fill="phosphor")
    for i, s in enumerate(t["main"]):
        f.text(20, 140 + i * 13, s, anchor="start", size=9.5)
    for k in range(13):
        f.box(100 + k * 44, 132, 40, 26, [t["frame"]], stroke="phosphor", size=9)
    f.text(20, 226, t["worker"][0], anchor="start", size=9.5)
    f.box(232, 212, 296, 28, [t["sort_w"]], stroke="wire", size=10)
    f.arrow([(208, 160), (208, 226), (230, 226)])
    f.text(196, 194, t["go"], anchor="end", size=9.5, mono=True, fill="paper-dim")
    f.arrow([(530, 226), (552, 226), (552, 160)])
    f.text(560, 194, t["result"], anchor="start", size=9.5, fill="paper-dim")
    return f


def figures(lang):
    t = T[lang]
    same = None if lang == "en" else ["worker"]
    return {
        "l06-frames": frames(t).json(t["f_cap"], same=None if lang == "en" else ["0 ms", "50 ms", "100 ms", "150 ms", "200 ms"]),
        "l06-two-threads": threads(t).json(t["t_cap"], same=same),
    }


FRAMES = [
    ('// frames.ts: a 60 Hz frame clock, and a sort that runs in its way or beside it\nimport { Worker, isMainThread, parentPort } from "node:worker_threads";\nimport type { Session } from "./planner.ts";\n\nconst mode = process.argv[2] ?? "idle"; // idle, main or worker\nconst N = Number(process.argv[3] ?? 300000);\n',
     "The program takes two arguments: where the sort runs, and how many sessions it sorts. `Session` is lesson 1's type, imported from `planner.ts`; `import type` disappears when `node` strips the types.",
     "O programa recebe dois argumentos: onde a ordenação roda e quantas sessões ela ordena. `Session` é o tipo da aula 1, importado de `planner.ts`; o `import type` some quando o `node` remove os tipos."),
    ('// N sessions from a fixed seed, so every run sorts the same data\nfunction makeSessions(n: number): Session[] {\n  let seed = 42;\n  const next = () => (seed = (seed * 16807) % 2147483647);\n  const out: Session[] = [];\n  for (let i = 0; i < n; i++) {\n    const day = String(1 + (next() % 28)).padStart(2, "0");\n    out.push({\n      id: "s" + i,\n      courseId: next() % 2 === 0 ? "sql" : "mobile",\n      date: `2026-10-${day}`,\n      minutes: 15 + (next() % 90),\n      done: false,\n    });\n  }\n  return out;\n}\n\n// By date, then by length; returns how long the sort took, in ms\nfunction sortSessions(list: Session[]): number {\n  const t0 = performance.now();\n  list.sort((a, b) => (a.date < b.date ? -1 : a.date > b.date ? 1 : a.minutes - b.minutes));\n  return performance.now() - t0;\n}\n',
     "The data is a month of made-up sessions. The numbers come from a fixed seed rather than `Math.random`, so every run sorts the same list. The sort is the planner's week view in miniature, and `performance.now()` times it to a fraction of a millisecond.",
     "Os dados são um mês de sessões inventadas. Os números vêm de uma semente fixa em vez de `Math.random`, então toda execução ordena a mesma lista. A ordenação é a visão da semana do planner em miniatura, e `performance.now()` mede o tempo dela em frações de milissegundo."),
    ('if (!isMainThread) {\n  // In the worker: make the same data, say ready, sort on "go", send the time back\n  const list = makeSessions(N);\n  parentPort!.postMessage("ready");\n  parentPort!.once("message", () => parentPort!.postMessage(sortSessions(list)));\n}\n',
     "This part runs only inside the worker. The same file is loaded a second time on another thread, where `isMainThread` is false. The worker makes its own copy of the data, so nothing large has to be copied across, and it sends back one number.",
     "Esta parte roda só dentro do worker. O mesmo arquivo é carregado uma segunda vez em outra thread, onde `isMainThread` é falso. O worker cria a própria cópia dos dados, então nada grande precisa atravessar, e devolve um número só."),
    ('// The frame clock: one slot every 16.67 ms, counted from `start`\nconst period = 1000 / 60;\nlet start = 0, last = -1, drawn = 0, dropped = 0, longest = 0, prev = 0, running = true;\n\nfunction frame() {\n  const now = performance.now();\n  const k = Math.floor((now - start) / period); // the slot we are in\n  if (k > last) {\n    dropped += k - last - 1; // slots that passed with no frame\n    drawn += 1;\n    if (last >= 0) longest = Math.max(longest, now - prev);\n    last = k;\n    prev = now;\n  }\n  if (running) setTimeout(frame, start + (k + 1) * period - now);\n}\n',
     "The clock stands in for the display. It asks to run at the start of each 16.67 ms slot, and when it runs it works out which slot it is in. Any slot it skipped is a dropped frame, the rule from the section on the budget: a frame that misses its slot is not drawn late, it is not drawn. `longest` keeps the widest gap between two frames.",
     "O relógio faz o papel da tela. Ele pede para rodar no começo de cada espaço de 16,67 ms e, quando roda, calcula em que espaço está. Todo espaço que ele pulou é um quadro perdido, a regra da seção sobre o orçamento: um quadro que perde o seu espaço não sai atrasado, não sai. `longest` guarda a maior distância entre dois quadros."),
    ('// Start the clock, run the work 200 ms in, stop 200 ms after it ends, print\nfunction measure(work: (done: (sortMs?: number) => void) => void) {\n  start = prev = performance.now();\n  frame();\n  setTimeout(() => work((sortMs) => setTimeout(() => {\n    running = false;\n    console.log(`${mode}: ${N} sessions, a frame due every ${period.toFixed(2)} ms`);\n    if (sortMs !== undefined) console.log(`  sort took      ${sortMs.toFixed(0)} ms`);\n    console.log(`  frames drawn   ${drawn}`);\n    console.log(`  frames dropped ${dropped}`);\n    console.log(`  longest gap    ${longest.toFixed(1)} ms`);\n  }, 200)), 200);\n}\n',
     "Every run has the same shape: 200 ms of quiet, the work, 200 ms of quiet, and then the counts.",
     "Toda execução tem o mesmo formato: 200 ms de calma, o trabalho, mais 200 ms de calma, e então as contagens."),
    ('if (isMainThread && mode === "idle") measure((done) => done());\n\nif (isMainThread && mode === "main") {\n  const list = makeSessions(N); // made before the clock starts\n  measure((done) => done(sortSessions(list)));\n}\n\nif (isMainThread && mode === "worker") {\n  const w = new Worker(new URL(import.meta.url), { argv: [mode, String(N)] });\n  w.once("message", () =>\n    measure((done) => {\n      w.postMessage("go");\n      w.once("message", (ms: number) => {\n        done(ms);\n        w.terminate();\n      });\n    }),\n  );\n}',
     "The three runs. `idle` does no work, so it shows what the clock does on its own. `main` sorts on the thread that runs the clock. `worker` starts a `Worker` from this same file, waits for it to be ready, says go, and keeps running the clock while the worker sorts.",
     "As três execuções. `idle` não faz trabalho nenhum, então mostra o que o relógio faz sozinho. `main` ordena na thread que roda o relógio. `worker` inicia um `Worker` a partir deste mesmo arquivo, espera que ele fique pronto, dá a partida e continua rodando o relógio enquanto o worker ordena."),
]

EXAMPLES = {
    "measured": [
        {"language": "typescript", "file": "frames.ts", "parts": FRAMES},
    ],
}
