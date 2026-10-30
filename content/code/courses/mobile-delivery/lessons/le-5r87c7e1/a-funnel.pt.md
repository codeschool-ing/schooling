---
title: Um funil, a partir de eventos
version: 1
---

**Um funil conta quantas pessoas chegaram a cada passo de um caminho, em ordem, e assim mostra onde
elas param.** Para o planner o caminho são os quatro eventos da seção anterior: abrir o app,
acrescentar um curso, planejar uma sessão, terminá-la. Todo produto de analytics desenha funis; aqui
a mesma coisa é feita com uma tabela no SQLite, para que todo número possa ser conferido.

## O código que registra eventos

Salve isto como `analytics.ts` em `~/planner`. Ele usa o `better-sqlite3`, instalado na lição 1:

```schooling-example
{"language": "typescript", "file": "analytics.ts", "parts": [{"code": "// analytics.ts: record product events, and refuse any property nobody decided to collect\nimport Database from \"better-sqlite3\";\n\nexport const SCHEMA: Record<string, string[]> = {\n  app_open: [],\n  course_added: [\"course_count\"],\n  session_added: [\"minutes\"],\n  session_done: [\"minutes\"],\n};", "note": "O esquema: cada evento que o app pode mandar, e as propriedades que ele pode levar. Ele mora no repositório e muda por pull request."}, {"code": "const db = new Database(\"events.db\");\ndb.exec(\"create table if not exists events (install text, name text, props text, at text)\");\nconst insert = db.prepare(\"insert into events values (?, ?, ?, ?)\");", "note": "Uma tabela, uma linha por evento. Num celular, esta seria a fila de eventos esperando para ser mandados."}, {"code": "export function track(install: string, name: string, props: Record<string, number> = {}, at: string) {\n  const allowed = SCHEMA[name];\n  if (!allowed) throw new Error(`event ${name} is not in the schema`);\n  const extra = Object.keys(props).filter((k) => !allowed.includes(k));\n  if (extra.length) throw new Error(`event ${name}: property ${extra.join(\", \")} is not in the schema`);\n  insert.run(install, name, JSON.stringify(props), at);\n}\n\nexport { db };", "note": "Um evento ou uma propriedade desconhecida é um erro, lançado onde roda o código que o mandou, antes de qualquer gravação. Propriedades são números, pelo tipo."}]}
```

## Uma semana de instalações

Uma semana de eventos de verdade vem dos celulares. Esta é feita por um programa curto: 500
instalações, cada uma abrindo o app num dia da semana de 19 de outubro de 2026, e depois
acrescentando um curso, planejando uma sessão e terminando-a com chances de 70%, 60% e 55%, a partir
de um gerador com semente, para toda execução fazer a mesma semana. No fim, ele tenta mandar um evento
com uma propriedade que o esquema não tem. Salve isto como `simulate.ts`:

```typescript
// simulate.ts: a week of installs of the planner, as the events they would send
import { db, track } from "./analytics.ts";

let seed = 16;
const random = () => ((seed = (seed * 1103515245 + 12345) % 2147483648) / 2147483648);
db.exec("delete from events");

for (let i = 0; i < 500; i++) {
  const install = `i${String(i).padStart(3, "0")}`;
  const day = `2026-10-${String(19 + (i % 7)).padStart(2, "0")}`;
  track(install, "app_open", {}, `${day}T09:00`);
  if (random() < 0.7) track(install, "course_added", { course_count: 1 }, `${day}T09:02`);
  else continue;
  if (random() < 0.6) track(install, "session_added", { minutes: 30 }, `${day}T09:05`);
  else continue;
  if (random() < 0.55) track(install, "session_done", { minutes: 30 }, `${day}T19:40`);
}
console.log(db.prepare("select name, count(*) as n from events group by name order by n desc").all());

try {
  track("i000", "course_added", { course_count: 2, course_name: 1 }, "2026-10-26T10:00");
} catch (e) {
  console.log(`refused: ${(e as Error).message}`);
}
```

## O funil

Salve isto como `funnel.ts`. Para cada instalação ele acha o primeiro horário de cada passo, e conta
uma instalação como tendo chegado a um passo só se ela chegou antes a todos os anteriores:

```typescript
// funnel.ts: how many installs reached each step, in order, and how many were lost between steps
import Database from "better-sqlite3";

const STEPS = ["app_open", "course_added", "session_added", "session_done"];
const db = new Database("events.db", { readonly: true });
const firsts = db.prepare(`
  select install, ${STEPS.map((s) => `min(case when name = '${s}' then at end) as ${s}`).join(", ")}
  from events group by install`).all() as Record<string, string | null>[];

const pct = (a: number, b: number) => `${Math.round((100 * a) / b)}%`;
const total = firsts.length;
let previous = total;
console.log("step            installs  of previous  of first");
STEPS.forEach((step, i) => {
  const reached = firsts.filter((f) =>
    STEPS.slice(0, i + 1).every((s, j) => f[s] !== null && (j === 0 || f[s]! >= f[STEPS[j - 1]]!)),
  ).length;
  console.log(`${step.padEnd(15)} ${String(reached).padStart(8)}  ${pct(reached, previous).padStart(11)}  ${pct(reached, total).padStart(8)}`);
  previous = reached;
});
```

```
ana@dev:~/planner$ node simulate.ts
[
  { name: 'app_open', n: 500 },
  { name: 'course_added', n: 374 },
  { name: 'session_added', n: 231 },
  { name: 'session_done', n: 127 }
]
refused: event course_added: property course_name is not in the schema
ana@dev:~/planner$ node funnel.ts
step            installs  of previous  of first
app_open             500         100%      100%
course_added         374          75%       75%
session_added        231          62%       46%
session_done         127          55%       25%
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" data-fig=\"l16-funnel\" aria-label=\"O funil do planner como quatro barras. 500 instalações abriram o app; 374 acrescentaram um curso, 75% delas; 231 planejaram uma sessão, 62% dessas; 127 terminaram uma sessão, 55% dessas e 25% de todos que abriram o app. A maior perda em pessoas fica entre acrescentar um curso e planejar uma sessão, 143 instalações; a maior perda em proporção é o último passo, 45%.\"><text x=\"150\" y=\"39\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">app_open</text><rect x=\"160\" y=\"24\" width=\"400\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"570\" y=\"39\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">500</text><text x=\"150\" y=\"85\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">course_added</text><rect x=\"160\" y=\"70\" width=\"299\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"469\" y=\"85\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">374</text><text x=\"509\" y=\"85\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">75%</text><text x=\"150\" y=\"131\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">session_added</text><rect x=\"160\" y=\"116\" width=\"185\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"355\" y=\"131\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">231</text><text x=\"395\" y=\"131\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">62%</text><text x=\"150\" y=\"177\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">session_done</text><rect x=\"160\" y=\"162\" width=\"102\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"272\" y=\"177\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">127</text><text x=\"312\" y=\"177\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">55%</text><text x=\"160\" y=\"220\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--amber)\">mais pessoas perdidas: 143 acrescentaram um curso e nunca planejaram uma sessão</text><text x=\"160\" y=\"240\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--amber)\">maior proporção perdida: 45% de quem planejou não estudou</text></svg>", "caption": "O passo do meio perde mais pessoas; o último perde a maior proporção. Um funil distingue os dois problemas."}
```

## Lendo o funil

**Um quarto das pessoas que abriram o planner terminou uma sessão.** A maior perda, em pessoas,
fica no meio: 143 instalações acrescentaram um curso e nunca planejaram uma sessão. A maior perda em
**proporção** é o último passo: 45% de quem planejou uma sessão não a fez. São dois problemas
diferentes, uma tela de curso que não leva a lugar nenhum e um lembrete que não traz as pessoas de
volta, e um funil é útil justamente porque os distingue.

A recusa no fim da simulação é o esquema funcionando: `course_name` são as palavras da própria
pessoa, ninguém decidiu coletá-las, e o evento nunca foi gravado.
