"""Lesson 12: the crash reporter, and its four moments."""
from fig import Fig

R = [
    ("// reporter.ts: a crash reporter in the shape every mobile one has: save on crash, send on next launch\nimport { randomUUID } from \"node:crypto\";\nimport { existsSync, mkdirSync, readdirSync, readFileSync, rmSync, writeFileSync } from \"node:fs\";\nimport { platform, release } from \"node:os\";\n\ntype Options = { version: string; build: number; endpoint: string };\nconst DIR = \"crashes\";\nconst crumbs: string[] = [];",
     "Reports wait in a folder named `crashes`. The breadcrumbs live in memory, because they only matter if the app dies with them.",
     "Os relatórios esperam numa pasta chamada `crashes`. As migalhas moram na memória, porque só importam se o app morrer com elas."),
    ("function installId(): string {\n  if (!existsSync(\"install-id\")) writeFileSync(\"install-id\", randomUUID());\n  return readFileSync(\"install-id\", \"utf8\");\n}",
     "A random identifier, made once and kept in a file: it counts installations without naming anybody.",
     "Um identificador aleatório, criado uma vez e guardado num arquivo: ele conta instalações sem nomear ninguém."),
    ("export function breadcrumb(text: string) {\n  crumbs.push(text);\n  if (crumbs.length > 20) crumbs.shift();\n}",
     "The last twenty things the app said it did. Older ones fall off.",
     "As últimas vinte coisas que o app disse ter feito. As mais antigas caem."),
    ("async function sendPending(endpoint: string) {\n  if (!existsSync(DIR)) return;\n  for (const name of readdirSync(DIR).sort()) {\n    const body = readFileSync(`${DIR}/${name}`, \"utf8\");\n    try {\n      const res = await fetch(endpoint, { method: \"POST\", headers: { \"content-type\": \"application/json\" }, body });\n      if (res.ok) rmSync(`${DIR}/${name}`);\n    } catch {\n      // No network: the report stays on disk and goes with the next launch.\n    }\n  }\n}",
     "Every report on disk is sent, and deleted only once the server has accepted it. Without a network, it waits for the launch after.",
     "Todo relatório no disco é mandado, e só apagado depois que o servidor o aceitou. Sem rede, ele espera a abertura seguinte."),
    ("export async function start(o: Options) {\n  await sendPending(o.endpoint);\n  process.on(\"uncaughtException\", (err) => {\n    const report = {\n      version: o.version, build: o.build, os: `${platform()} ${release()}`,\n      install: installId(), at: new Date().toISOString(), breadcrumbs: crumbs,\n      error: { type: err.name, message: err.message, stack: err.stack?.split(\"\\n\").slice(1, 4).map((l) => l.trim()) },\n    };\n    mkdirSync(DIR, { recursive: true });\n    writeFileSync(`${DIR}/${Date.now()}.json`, JSON.stringify(report, null, 2));\n    process.exit(1);\n  });\n}",
     "At start: send what the last crash left, then wait for the next one. On a crash: write the report, synchronously, and exit. Nothing is sent from a dying process.",
     "Na abertura: mandar o que o último crash deixou, e então esperar o próximo. Num crash: gravar o relatório, de forma síncrona, e sair. Nada é mandado de um processo morrendo."),
]
EXAMPLES = {"a-reporter-you-can-read": [{"language": "typescript", "file": "reporter.ts", "parts": R}]}

T = {
    "en": dict(aria="Two launches of the app on a timeline. During the first launch, the reporter starts first, the app keeps breadcrumbs as it runs, then it crashes; the reporter writes the report to the phone's disk and the app vanishes. The person opens the app again. During the second launch, the reporter starts first again, finds the report on disk and sends it to the server, which answers that it accepted it, and the report is deleted from the disk.",
               l1="launch 1", l2="launch 2", start="reporter starts", crumbs="breadcrumbs kept", crash="crash",
               write="report written to disk", gone="the app vanishes", again="opened again",
               send="report sent", ok="accepted, deleted", disk="the phone's disk", server="crash server",
               cap="The report crosses the gap between two launches on disk. Nothing is sent at the moment of the crash, because a crashing process is the last place to trust with a network request."),
    "pt": dict(aria="Duas aberturas do app numa linha do tempo. Na primeira, o coletor começa primeiro, o app guarda migalhas enquanto roda, e então quebra; o coletor grava o relatório no disco do celular e o app some. A pessoa abre o app de novo. Na segunda abertura, o coletor começa primeiro de novo, acha o relatório no disco e o manda ao servidor, que responde que o aceitou, e o relatório é apagado do disco.",
               l1="abertura 1", l2="abertura 2", start="coletor começa", crumbs="migalhas guardadas", crash="crash",
               write="relatório gravado no disco", gone="o app some", again="aberto de novo",
               send="relatório mandado", ok="aceito, apagado", disk="o disco do celular", server="servidor de crash",
               cap="O relatório atravessa o intervalo entre duas aberturas no disco. Nada é mandado no momento do crash, porque um processo quebrando é o último lugar em que confiar uma requisição de rede."),
}


def figures(lang):
    t = T[lang]
    f = Fig("l12-sequence", 720, 290, t["aria"])
    f.rect(20, 20, 300, 160, stroke="wire", fill="panel")
    f.text(170, 38, t["l1"], bold=True, size=10.5, fill="phosphor")
    f.rect(400, 20, 300, 160, stroke="wire", fill="panel")
    f.text(550, 38, t["l2"], bold=True, size=10.5, fill="phosphor")
    steps1 = [(t["start"], "paper"), (t["crumbs"], "paper"), (t["crash"], "amber"), (t["write"], "paper"), (t["gone"], "paper-dim")]
    for i, (s, c) in enumerate(steps1):
        f.text(40, 60 + i * 24, f"{i + 1}  {s}", anchor="start", size=9.5, fill=c, bold=(c == "amber"))
    steps2 = [(t["start"], "paper"), (t["send"], "phosphor"), (t["ok"], "paper")]
    for i, (s, c) in enumerate(steps2):
        f.text(420, 60 + i * 24, f"{i + 1}  {s}", anchor="start", size=9.5, fill=c)
    f.arrow([(320, 100), (398, 100)], color="paper-dim", dashed=True)
    f.text(359, 90, t["again"], size=9, fill="paper-dim", italic=True)
    f.box(150, 220, 180, 40, [t["disk"]], stroke="amber", ground="ink")
    f.box(470, 220, 160, 40, [t["server"]], stroke="phosphor", ground="ink")
    f.arrow([(170, 180), (210, 218)], color="amber")
    f.arrow([(330, 230), (468, 230)], color="phosphor")
    same = None if lang == "en" else ["3 crash"]
    return {"l12-sequence": f.json(t["cap"], same=same)}
