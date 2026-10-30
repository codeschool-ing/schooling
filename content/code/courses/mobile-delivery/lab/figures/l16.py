"""Lesson 16: analytics.ts, and the funnel as bars."""
from fig import Fig

P = [
    ("// analytics.ts: record product events, and refuse any property nobody decided to collect\nimport Database from \"better-sqlite3\";\n\nexport const SCHEMA: Record<string, string[]> = {\n  app_open: [],\n  course_added: [\"course_count\"],\n  session_added: [\"minutes\"],\n  session_done: [\"minutes\"],\n};",
     "The schema: each event the app may send, and the properties it may carry. It lives in the repository and changes by pull request.",
     "O esquema: cada evento que o app pode mandar, e as propriedades que ele pode levar. Ele mora no repositório e muda por pull request."),
    ("const db = new Database(\"events.db\");\ndb.exec(\"create table if not exists events (install text, name text, props text, at text)\");\nconst insert = db.prepare(\"insert into events values (?, ?, ?, ?)\");",
     "One table, one row per event. On a phone this would be the queue of events waiting to be sent.",
     "Uma tabela, uma linha por evento. Num celular, esta seria a fila de eventos esperando para ser mandados."),
    ("export function track(install: string, name: string, props: Record<string, number> = {}, at: string) {\n  const allowed = SCHEMA[name];\n  if (!allowed) throw new Error(`event ${name} is not in the schema`);\n  const extra = Object.keys(props).filter((k) => !allowed.includes(k));\n  if (extra.length) throw new Error(`event ${name}: property ${extra.join(\", \")} is not in the schema`);\n  insert.run(install, name, JSON.stringify(props), at);\n}\n\nexport { db };",
     "An unknown event or property is an error, thrown where the code that sent it runs, before anything is written. Properties are numbers by type.",
     "Um evento ou uma propriedade desconhecida é um erro, lançado onde roda o código que o mandou, antes de qualquer gravação. Propriedades são números, pelo tipo."),
]
EXAMPLES = {"a-funnel": [{"language": "typescript", "file": "analytics.ts", "parts": P}]}

T = {
    "en": dict(aria="The planner's funnel as four bars. 500 installs opened the app; 374 added a course, 75% of them; 231 planned a session, 62% of those; 127 finished a session, 55% of those and 25% of everybody who opened the app. The largest loss in people is between adding a course and planning a session, 143 installs; the largest loss in share is the last step, 45%.",
               steps=["app_open", "course_added", "session_added", "session_done"],
               lost1="143 added a course and never planned a session", first="most people lost:", last="largest share lost:", lost3="45% of planners did not study",
               cap="The middle step loses the most people; the last loses the largest share. A funnel tells the two problems apart."),
    "pt": dict(aria="O funil do planner como quatro barras. 500 instalações abriram o app; 374 acrescentaram um curso, 75% delas; 231 planejaram uma sessão, 62% dessas; 127 terminaram uma sessão, 55% dessas e 25% de todos que abriram o app. A maior perda em pessoas fica entre acrescentar um curso e planejar uma sessão, 143 instalações; a maior perda em proporção é o último passo, 45%.",
               steps=["app_open", "course_added", "session_added", "session_done"],
               lost1="143 acrescentaram um curso e nunca planejaram uma sessão", first="mais pessoas perdidas:", last="maior proporção perdida:", lost3="45% de quem planejou não estudou",
               cap="O passo do meio perde mais pessoas; o último perde a maior proporção. Um funil distingue os dois problemas."),
}


def figures(lang):
    t = T[lang]
    f = Fig("l16-funnel", 720, 260, t["aria"])
    vals = [500, 374, 231, 127]
    shares = ["", "75%", "62%", "55%"]
    for i, (step, v) in enumerate(zip(t["steps"], vals)):
        y = 24 + i * 46
        w = round(400 * v / 500)
        f.text(150, y + 15, step, anchor="end", mono=True, size=9.5, fill="paper")
        f.rect(160, y, w, 30, stroke="phosphor", fill="panel", rx=2)
        f.text(160 + w + 10, y + 15, f"{v}", anchor="start", mono=True, size=9.5, fill="phosphor")
        if shares[i]:
            f.text(160 + w + 50, y + 15, shares[i], anchor="start", mono=True, size=9.5, fill="paper-dim")
    f.text(160, 220, t["first"] + " " + t["lost1"], anchor="start", size=9.5, fill="amber", italic=True)
    f.text(160, 240, t["last"] + " " + t["lost3"], anchor="start", size=9.5, fill="amber", italic=True)
    return {"l16-funnel": f.json(t["cap"])}
