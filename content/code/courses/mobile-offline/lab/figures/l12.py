"""Lesson 12: the resync, as an annotated example; and one figure."""
from fig import Fig

EXAMPLES = {
    "the-snapshot": [{
        "language": "typescript", "file": "resync.ts",
        "parts": [
            ("// resync.ts: replace the device's copy with the server's snapshot, keeping what is not sent yet.\nimport { renameSync, rmSync } from \"node:fs\";\nimport { open } from \"./store.ts\";\n",
             "The whole of the device's side of a resync, in one function, so that `device.ts` can call it the moment the server answers 410.",
             "Todo o lado do aparelho numa ressincronização, numa função só, para o `device.ts` chamá-la no instante em que o servidor responder 410."),
            ("export async function resync(server: string, file: string) {\n  const text = await (await fetch(`${server}/snapshot`)).text();\n  const snapshot = JSON.parse(text) as { cursor: number; sessions: Record<string, unknown>[] };\n",
             "One request for everything the server has, with the cursor that goes with it. It is the only part that needs the network, and it happens before anything on the device changes.",
             "Uma requisição por tudo o que o servidor tem, com o cursor que vai junto. É a única parte que precisa de rede, e acontece antes de qualquer coisa mudar no aparelho."),
            ("  rmSync(`${file}.next`, { force: true });\n  const next = open(`${file}.next`);\n  const old = open(file);\n  next.transaction(() => {",
             "A second file beside the first. A leftover from a resync that crashed is removed first; the old file is opened only to be read.",
             "Um segundo arquivo ao lado do primeiro. Uma sobra de uma ressincronização que caiu é removida antes; o arquivo antigo é aberto só para ser lido."),
            ("    const save = next.prepare(\"insert or replace into sessions values (@id, @course, @date, @minutes)\");\n    for (const s of snapshot.sessions) save.run(s);\n    next.prepare(\"insert into meta values ('cursor', ?)\").run(String(snapshot.cursor));\n",
             "The snapshot goes into the new file, with its cursor.",
             "O snapshot vai para o arquivo novo, com o cursor dele."),
            ("    const pending = old.prepare(\"select seq, op, session, body from outbox order by seq\").all() as\n      { seq: number; op: string; session: string; body: string | null }[];\n    for (const o of pending) {\n      next.prepare(\"insert into outbox values (?, ?, ?, ?)\").run(o.seq, o.op, o.session, o.body);\n      if (o.op === \"delete\") next.prepare(\"delete from sessions where id = ?\").run(o.session);\n      else save.run(JSON.parse(o.body!));\n    }\n    console.log(`snapshot: ${snapshot.sessions.length} sessions, ${text.length} bytes; ${pending.length} pending carried over`);\n  })();",
             "Then the outbox is copied across, and each pending operation is applied again to the new copy, so the person's unsent work is still on the screen and still waiting to be sent.",
             "Depois a caixa de saída é copiada, e cada operação pendente é aplicada de novo à cópia nova, para o trabalho não enviado da pessoa continuar na tela e continuar esperando envio."),
            ("  old.close();\n  next.close();\n",
             "Both connections closed, so nothing is half written to either file.",
             "As duas conexões fechadas, para nada ficar meio escrito em nenhum dos arquivos."),
            ("  renameSync(`${file}.next`, file);\n}",
             "The swap. A rename within one folder is atomic: whoever opens `planner.db` afterwards gets the old file or the new one, never a mixture.",
             "A troca. Um rename dentro de uma pasta é atômico: quem abrir o `planner.db` depois recebe o arquivo antigo ou o novo, nunca uma mistura."),
        ],
    }],
}

T = {
    "en": dict(
        aria="Three steps of a resync. First, the screens read planner.db, the old copy, while planner.db.next is written beside it with the server's snapshot and then the pending outbox rows, applied again. Second, both files are closed. Third, one rename makes planner.db.next the new planner.db, and the screens read the new copy. At no moment is a file read half written.",
        s1="1 · written beside the old copy", s2="2 · one rename", s3="3 · the new copy",
        old="the screens read it", snap="the server's snapshot", out="+ the outbox, applied again",
        after="the screens read it",
        cap="Until the rename the app reads the old copy, whole; after it, the new one. Nothing ever reads a file that is half written.",
    ),
    "pt": dict(
        aria="Três passos de uma ressincronização. Primeiro, as telas leem o planner.db, a cópia antiga, enquanto o planner.db.next é escrito ao lado com o snapshot do servidor e depois as linhas pendentes da caixa de saída, aplicadas de novo. Segundo, os dois arquivos são fechados. Terceiro, um rename faz do planner.db.next o novo planner.db, e as telas leem a cópia nova. Em nenhum momento um arquivo é lido pela metade.",
        s1="1 · escrito ao lado da cópia antiga", s2="2 · um rename", s3="3 · a cópia nova",
        old="as telas o leem", snap="o snapshot do servidor", out="+ a caixa de saída, reaplicada",
        after="as telas o leem",
        cap="Até o rename o app lê a cópia antiga, inteira; depois dele, a nova. Nada nunca lê um arquivo escrito pela metade.",
    ),
}


def figures(lang):
    t = T[lang]
    f = Fig("l12-swap", 720, 220, t["aria"])
    f.text(20, 22, t["s1"], anchor="start", bold=True, size=10.5, fill="phosphor")
    f.box(20, 40, 200, 44, ["planner.db", t["old"]], stroke="wire")
    f.box(20, 104, 200, 64, ["planner.db.next", t["snap"], t["out"]], stroke="phosphor", dashed=True)
    f.text(300, 22, t["s2"], bold=True, size=10.5, fill="amber")
    f.arrow([(220, 136), (300, 136), (300, 62), (496, 62)], color="amber")
    f.text(350, 52, "rename", size=9.5, fill="amber", mono=True)
    f.text(500, 22, t["s3"], anchor="start", bold=True, size=10.5, fill="phosphor")
    f.box(500, 40, 200, 44, ["planner.db", t["after"]], stroke="phosphor")
    same = None if lang == "en" else ["planner.db", "planner.db.next"]
    return {"l12-swap": f.json(t["cap"], same=same)}
