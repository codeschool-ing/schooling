"""Lesson 5: the privacy script, and the three boxes of Apple's label."""
from fig import Fig

P = [
    ("// privacy.ts: turn the data inventory into the answers each store's privacy form asks for\nimport { readFileSync } from \"node:fs\";\n\ntype Entry = {\n  what: string; to: string; thirdParty: boolean; purposes: string[];\n  linked: boolean; tracking: boolean; optional: boolean; apple: string; google: string;\n};\nconst file = process.argv[2] ?? \"inventory.json\";\nconst inv = JSON.parse(readFileSync(file, \"utf8\")) as { app: string; encryptedInTransit: boolean; deletionOnRequest: boolean; data: Entry[] };",
     "One type for an entry of the inventory, and the file to read, `inventory.json` unless another is named.",
     "Um tipo para uma entrada do inventário, e o arquivo a ler, `inventory.json` se nenhum outro for nomeado."),
    ("const fields = [\"what\", \"to\", \"thirdParty\", \"purposes\", \"linked\", \"tracking\", \"optional\", \"apple\", \"google\"];\nfor (const e of inv.data) {\n  const missing = fields.filter((f) => !(f in e) || (f === \"purposes\" && e.purposes.length === 0));\n  if (missing.length) {\n    console.error(`${e.what ?? \"an entry\"}: no answer for ${missing.join(\", \")}`);\n    process.exit(1);\n  }\n}",
     "An entry with a question left unanswered stops the script. A form filled with a guess is worse than one not filled.",
     "Uma entrada com uma pergunta sem resposta para o script. Um formulário preenchido com um palpite é pior do que um não preenchido."),
    ("const row = (label: string, rest: string) => console.log(`    ${label.padEnd(44)} ${rest}`);\nconsole.log(`Apple, privacy details for ${inv.app}`);\nfor (const [box, pick] of [\n  [\"Data Used to Track You\", (e: Entry) => e.tracking],\n  [\"Data Linked to You\", (e: Entry) => !e.tracking && e.linked],\n  [\"Data Not Linked to You\", (e: Entry) => !e.tracking && !e.linked],\n] as const) {\n  const hits = inv.data.filter(pick);\n  console.log(`  ${box}:${hits.length ? \"\" : \" none\"}`);\n  for (const e of hits) row(e.apple, e.purposes.join(\", \"));\n}",
     "Apple's three boxes. Tracking wins over everything; otherwise an entry is linked to the person or it is not.",
     "As três caixas da Apple. Rastreamento vence tudo; fora isso, uma entrada está ligada à pessoa ou não está."),
    ("console.log(`Google Play, Data safety for ${inv.app}`);\nfor (const e of inv.data) {\n  const how = [\"collected\", e.thirdParty ? \"shared\" : \"\", e.optional ? \"optional\" : \"\"].filter(Boolean).join(\", \");\n  row(e.google, `${how}; ${e.purposes.join(\", \")}`);\n}\nconsole.log(`  encrypted in transit: ${inv.encryptedInTransit ? \"yes\" : \"no\"}`);\nconsole.log(`  people can ask for their data to be deleted: ${inv.deletionOnRequest ? \"yes\" : \"no\"}`);",
     "Google's form, one line per kind of data: collected, shared with a third party, optional, and why. Then the two questions about the app as a whole.",
     "O formulário do Google, uma linha por tipo de dado: coletado, compartilhado com terceiros, opcional, e por quê. Depois as duas perguntas sobre o app inteiro."),
]
EXAMPLES = {"the-inventory": [{"language": "typescript", "file": "privacy.ts", "parts": P}]}

T = {
    "en": dict(aria="Apple's privacy label as three boxes, with the planner's four kinds of data placed in them. Data Used to Track You is empty. Data Linked to You holds the e-mail address and the courses and sessions, because the account ties them to the person. Data Not Linked to You holds the crash reports and the product events, which carry no account. A note says that data which never leaves the phone appears in no box.",
               track="Data Used to Track You", linked="Data Linked to You", notl="Data Not Linked to You",
               none="none: nothing is shared with an advertiser",
               email="e-mail address", sess="courses and sessions", crash="crash reports", events="product events",
               why1="the account ties them to the person", why2="no account, a random install id",
               note="data that never leaves the phone is in no box at all",
               cap="The planner's four kinds of data in Apple's three boxes. What decides the box is whether something ties the data to the person, not how sensitive the data feels."),
    "pt": dict(aria="O rótulo de privacidade da Apple como três caixas, com os quatro tipos de dado do planner dentro delas. Data Used to Track You está vazia. Data Linked to You guarda o endereço de e-mail e os cursos e sessões, porque a conta os liga à pessoa. Data Not Linked to You guarda os relatórios de crash e os eventos de produto, que não levam conta nenhuma. Uma nota diz que dado que nunca sai do celular não aparece em caixa nenhuma.",
               track="Data Used to Track You", linked="Data Linked to You", notl="Data Not Linked to You",
               none="vazia: nada é compartilhado com anunciante",
               email="endereço de e-mail", sess="cursos e sessões", crash="relatórios de crash", events="eventos de produto",
               why1="a conta os liga à pessoa", why2="sem conta, um id de instalação aleatório",
               note="dado que nunca sai do celular não fica em caixa nenhuma",
               cap="Os quatro tipos de dado do planner nas três caixas da Apple. O que decide a caixa é se algo liga o dado à pessoa, e não quão sensível o dado parece."),
}


def figures(lang):
    t = T[lang]
    f = Fig("l05-label", 720, 250, t["aria"])
    cols = [(20, t["track"], [], t["none"]), (260, t["linked"], [t["email"], t["sess"]], t["why1"]),
            (500, t["notl"], [t["crash"], t["events"]], t["why2"])]
    for x, title, items, why in cols:
        f.rect(x, 20, 200, 180, stroke="phosphor" if items else "wire", fill="panel", dashed=not items)
        f.text(x + 100, 42, title, bold=True, size=10.5, fill="phosphor")
        for i, it in enumerate(items):
            f.box(x + 16, 62 + i * 40, 168, 30, [it], stroke="wire", ground="ink")
        f.text(x + 100, 170, why, size=9, fill="paper-dim", italic=True)
    f.text(360, 228, t["note"], size=9.5, fill="amber", italic=True)
    same = None if lang == "en" else ["Data Used to Track You", "Data Linked to You", "Data Not Linked to You"]
    return {"l05-label": f.json(t["cap"], same=same)}
