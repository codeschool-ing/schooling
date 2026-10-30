"""Lesson 5: restore.ts as an example, the round trip, and the two sizes."""
from fig import Fig

EXAMPLES = {
    "round-trip": [
        {"language": "typescript", "file": "restore.ts", "parts": [
            ('// restore.ts: the screen\'s state, saved on the way out and put back after a kill\nimport { existsSync, readFileSync, writeFileSync } from "node:fs";\nimport { weekTotal, type Plan, type Session } from "./planner.ts";\n\n// The data. In the app it lives in a database on the device (lesson 16).\nconst plan: Plan = {\n  courses: [\n    { id: "sql", title: "SQL Databases" },\n    { id: "mobile", title: "Mobile Fundamentals" },\n  ],\n  sessions: [\n    { id: "s1", courseId: "sql", date: "2026-10-19", minutes: 50, done: true },\n    { id: "s2", courseId: "mobile", date: "2026-10-20", minutes: 40, done: true },\n    { id: "s3", courseId: "sql", date: "2026-10-23", minutes: 60, done: false },\n    { id: "s5", courseId: "mobile", date: "2026-10-22", minutes: 30, done: false },\n  ],\n};\n',
             "The data, as a constant standing in for the database. It survives the kill because it was never only in memory, so nothing here saves it.",
             "Os dados, como uma constante no lugar do banco. Eles sobrevivem à morte porque nunca estiveram só na memória, então nada aqui os salva."),
            ('// The UI state: where the user was and what they had half typed. Ids, not objects.\ntype UiState = {\n  courseId: string;\n  scrollY: number;\n  draft: { date: string; minutes: string } | null;\n};\nconst FILE = "saved-state.json";\nconst TODAY = "2026-10-21";\n\nfunction draw(ui: UiState) {\n  const course = plan.courses.find((c) => c.id === ui.courseId);\n  if (!course) throw new Error(`saved state names a course that does not exist: ${ui.courseId}`);\n  const own = { ...plan, sessions: plan.sessions.filter((s) => s.courseId === course.id) };\n  const t = weekTotal(own, TODAY);\n  console.log(`  ${course.title}, week of ${t.monday}: ${t.done} of ${t.planned} minutes done`);\n  console.log(`  scrolled to ${ui.scrollY} px`);\n  console.log(ui.draft ? `  new session, not saved yet: ${ui.draft.date}, "${ui.draft.minutes}" minutes` : "  no session being written");\n}\n',
             "The UI state names the course by its id and keeps the typed minutes as a string. `draw` is the screen: it looks the course up in the data and computes the week's numbers again rather than trusting a saved copy.",
             "O estado de UI nomeia o curso pelo id e guarda os minutos digitados como string. `draw` é a tela: procura o curso nos dados e calcula de novo os números da semana em vez de confiar numa cópia salva."),
            ('const mode = process.argv[2] ?? "open";\n\nif (mode === "use") {\n  // Ana opens a course, scrolls, starts typing a session...\n  const ui: UiState = { courseId: "mobile", scrollY: 640, draft: { date: "2026-10-22", minutes: "45" } };\n  console.log("on screen:");\n  draw(ui);\n  process.on("exit", () => console.log("goodbye")); // never printed\n  // ...the app goes to the background, and saves while it is still being told things.\n  const text = JSON.stringify(ui);\n  writeFileSync(FILE, text);\n  console.log(`saved ${Buffer.byteLength(text)} bytes to ${FILE}`);\n  // The system kills the suspended process: no callback, no exit handler.\n  process.kill(process.pid, "SIGKILL");\n',
             "`use` draws the screen, saves the UI state on the way out, and then kills its own process with `SIGKILL`, the signal no handler can catch. The `exit` handler is there to show that it does not run.",
             "`use` desenha a tela, salva o estado de UI na saída e depois mata o próprio processo com `SIGKILL`, o sinal que nenhum handler consegue capturar. O handler de `exit` está ali para mostrar que ele não roda."),
            ('} else if (mode === "open") {\n  if (existsSync(FILE)) {\n    console.log(`restored from ${FILE}:`);\n    draw(JSON.parse(readFileSync(FILE, "utf8")) as UiState);\n  } else {\n    console.log("nothing saved, a fresh start:");\n    draw({ courseId: plan.courses[0].id, scrollY: 0, draft: null });\n  }\n',
             "`open` is the next launch: a new process that knows nothing, reads the saved state if there is one, and otherwise opens on its default screen.",
             "`open` é o próximo lançamento: um processo novo que não sabe nada, lê o estado salvo se houver, e senão abre na tela padrão."),
            ('} else if (mode === "sizes") {\n  // The same screen, saved two ways, for a plan of 2,000 sessions.\n  const sessions: Session[] = [];\n  for (let i = 1; i <= 2000; i++) {\n    const day = String(1 + (i % 28)).padStart(2, "0");\n    sessions.push({ id: `s${i}`, courseId: i % 2 ? "sql" : "mobile", date: `2026-11-${day}`, minutes: 30 + (i % 4) * 15, done: i % 3 === 0 });\n  }\n  const big = { ...plan, sessions };\n  const ui: UiState = { courseId: "mobile", scrollY: 640, draft: { date: "2026-10-22", minutes: "45" } };\n  const ids = Buffer.byteLength(JSON.stringify(ui));\n  const whole = Buffer.byteLength(JSON.stringify({ ...ui, course: big.courses[1], plan: big }));\n  console.log(`ids only:       ${ids} bytes`);\n  console.log(`the whole plan: ${whole} bytes, ${(whole / 1024).toFixed(1)} KiB, ${Math.round(whole / ids)} times as much`);\n} else {\n  console.error(`unknown mode "${mode}": use, open or sizes`);\n  process.exit(1);\n}',
             "`sizes` builds a plan of 2,000 generated sessions and measures the same screen saved two ways: by ids, and with the course and the whole plan inside it. Any other mode is refused by name.",
             "`sizes` monta um plano de 2.000 sessões geradas e mede a mesma tela salva de dois jeitos: por ids, e com o curso e o plano inteiro dentro. Qualquer outro modo é recusado pelo nome."),
        ]},
    ],
}

IDS, WHOLE = 80, 157479   # bytes, from the capture of `node restore.ts sizes`
LIMIT = 50 * 1024         # Android's guide: keep saved state under 50 KB (read 30 October 2026)

T = {
    "en": dict(
        aria1="A round trip through process death. Process 1, node restore.ts use: Ana opens a course, scrolls and types 45; on the way out the program writes the UI state. Then the kill: SIGKILL, and nothing more runs. The UI state is in saved-state.json: course id, scroll position and draft. Process 2, node restore.ts open, starts from nothing, as an app does at onCreate, reads the saved state and draws the same screen.",
        p1=["process 1: restore.ts use", "Ana opens a course, scrolls, types \"45\"", "on the way out: writes the UI state"],
        p2=["process 2: restore.ts open", "starts from nothing, like onCreate", "reads the UI state, draws the screen"],
        kill="the kill: SIGKILL, and nothing more runs",
        disk=["saved-state.json", "course id · scroll · draft"],
        cap1="What crosses the kill is what was written before it. The process, its memory and its exit handler do not.",
        aria2="Two bars measuring the same screen's saved state. Saved as ids: 80 bytes, too small to see at this scale. Saved with the whole plan of 2,000 sessions inside: 157,479 bytes. A mark shows 50 KB, the most Android's guide recommends for saved state; the whole plan is about three times over it.",
        b1="ids only: 80 bytes", b2="the whole plan: 157,479 bytes",
        line="Android's guide: under 50 KB",
        cap2="The same screen, saved two ways. Measured with node restore.ts sizes; the 50 KB mark is from Android's guide to Parcelables and Bundles, read on 30 October 2026.",
    ),
    "pt": dict(
        aria1="Uma ida e volta pela morte do processo. Processo 1, node restore.ts use: Ana abre um curso, rola e digita 45; na saída o programa grava o estado de UI. Então a morte: SIGKILL, e nada mais roda. O estado de UI está em saved-state.json: id do curso, posição de rolagem e rascunho. Processo 2, node restore.ts open, começa do nada, como um app no onCreate, lê o estado salvo e desenha a mesma tela.",
        p1=["processo 1: restore.ts use", "Ana abre um curso, rola, digita \"45\"", "na saída: grava o estado de UI"],
        p2=["processo 2: restore.ts open", "começa do nada, como no onCreate", "lê o estado de UI, desenha a tela"],
        kill="a morte: SIGKILL, e nada mais roda",
        disk=["saved-state.json", "id do curso · rolagem · rascunho"],
        cap1="O que atravessa a morte é o que foi gravado antes dela. O processo, a memória dele e o handler de saída não atravessam.",
        aria2="Duas barras medindo o estado salvo da mesma tela. Salvo como ids: 80 bytes, pequeno demais para aparecer nesta escala. Salvo com o plano inteiro de 2.000 sessões dentro: 157.479 bytes. Uma marca mostra 50 KB, o máximo que o guia do Android recomenda para estado salvo; o plano inteiro passa disso umas três vezes.",
        b1="só ids: 80 bytes", b2="o plano inteiro: 157.479 bytes",
        line="guia do Android: menos de 50 KB",
        cap2="A mesma tela, salva de dois jeitos. Medido com node restore.ts sizes; a marca de 50 KB vem do guia do Android sobre Parcelables e Bundles, lido em 30 de outubro de 2026.",
    ),
}


def round_trip(t):
    f = Fig("l05-round-trip", 720, 230, t["aria1"])
    f.box(20, 40, 290, 78, t["p1"], size=9.5, stroke="phosphor")
    f.box(410, 40, 290, 78, t["p2"], size=9.5, stroke="phosphor")
    f.arrow([(360, 32), (360, 140)], color="amber", head=False, dashed=True, width=1.6)
    f.text(360, 18, t["kill"], size=9.5, bold=True, fill="amber")
    f.box(250, 166, 220, 44, t["disk"], size=9.5, stroke="amber")
    f.arrow([(165, 118), (165, 188), (248, 188)])
    f.arrow([(472, 188), (555, 188), (555, 120)])
    return f


def sizes(t):
    f = Fig("l05-sizes", 720, 150, t["aria2"])
    x0, w = 20, 600
    scale = w / WHOLE
    f.rect(x0, 34, max(1, round(IDS * scale)), 24, stroke="phosphor", fill="panel")
    f.text(x0 + 8, 46, t["b1"], anchor="start", size=9.5)
    f.rect(x0, 78, round(WHOLE * scale), 24, stroke="amber", fill="panel")
    f.text(x0 + 8, 90, t["b2"], anchor="start", size=9.5)
    lx = x0 + round(LIMIT * scale)
    f.arrow([(lx, 62), (lx, 75)], color="phosphor", head=False, width=1.6)
    f.arrow([(lx, 120), (lx, 106)], color="phosphor", width=1.4)
    f.text(lx, 134, t["line"], size=9.5, fill="phosphor")
    return f


def figures(lang):
    t = T[lang]
    return {
        "l05-round-trip": round_trip(t).json(t["cap1"], same=["saved-state.json"] if lang == "pt" else None),
        "l05-sizes": sizes(t).json(t["cap2"]),
    }
