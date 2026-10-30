---
title: Planos de consulta, e o índice que os muda
version: 1
---

**O SQLite responde a uma consulta lendo todas as linhas, a não ser que um índice o deixe pular
direto para as que ele quer, e o `EXPLAIN QUERY PLAN` diz qual das duas ele vai fazer.** Seis
sessões escondem isso por completo. Três anos de um planner usado todo dia não escondem, então esta
seção constrói um.

Salve isto como `big.ts` na `~/planner/db`. Ele cria 20.000 sessões em seis cursos e três anos, a
partir de um gerador pequeno com semente fixa, então toda execução cria exatamente as mesmas
linhas:

```typescript
// big.ts: a planner after three years of use: 20,000 sessions, made the same way on every run.
import Database from "better-sqlite3";

let seed = 2026; // a tiny seeded generator, so every run makes the same rows
function random(): number {
  seed = (seed * 1103515245 + 12345) % 2147483648;
  return seed / 2147483648;
}

const db = new Database("big.db");
db.exec(`
  DROP TABLE IF EXISTS sessions;
  CREATE TABLE sessions (id TEXT PRIMARY KEY, course TEXT NOT NULL, date TEXT NOT NULL,
                         minutes INTEGER NOT NULL, done INTEGER NOT NULL);
`);
const courses = ["spanish", "statistics", "guitar", "piano", "chemistry", "history"];
const add = db.prepare("INSERT INTO sessions VALUES (?, ?, ?, ?, ?)");
const start = Date.UTC(2023, 10, 1);
db.transaction(() => {
  for (let n = 1; n <= 20000; n++) {
    const day = new Date(start + Math.floor(random() * 1096) * 86400000).toISOString().slice(0, 10);
    const course = courses[Math.floor(random() * courses.length)];
    add.run(`s${n}`, course, day, 15 + 15 * Math.floor(random() * 4), random() < 0.7 ? 1 : 0);
  }
})();
console.log(db.prepare("SELECT count(*) AS n, min(date) AS first, max(date) AS last FROM sessions").get());
```

```
ana@dev:~/planner/db$ node big.ts
{ n: 20000, first: '2023-11-01', last: '2026-10-31' }
```

O planner faz dois tipos de pergunta sobre a semana: as sessões de um curso numa semana, para a
tela do curso, e as sessões de todos os cursos numa semana, para a tela da semana. Este programa
pergunta ao SQLite como ele responderia a cada uma, sem mudar nada. Salve como `plan.ts`:

```typescript
// plan.ts: how SQLite means to answer the planner's two week queries on big.db.
import Database from "better-sqlite3";

const db = new Database("big.db", { readonly: true });
const queries: Record<string, string> = {
  "one course, one week":
    "SELECT * FROM sessions WHERE course = 'statistics' AND date >= '2026-10-19' AND date < '2026-10-26'",
  "every course, one week": "SELECT * FROM sessions WHERE date >= '2026-10-19' AND date < '2026-10-26'",
};
for (const [name, sql] of Object.entries(queries)) {
  const plan = db.prepare(`EXPLAIN QUERY PLAN ${sql}`).all() as { detail: string }[];
  const rows = db.prepare(sql).all().length;
  console.log(`${name}: ${rows} rows`);
  for (const step of plan) console.log(`  ${step.detail}`);
}
```

## Antes, e depois

```
ana@dev:~/planner/db$ node plan.ts
one course, one week: 8 rows
  SCAN sessions
every course, one week: 158 rows
  SCAN sessions
ana@dev:~/planner/db$ sqlite3 big.db "CREATE INDEX sessions_course_date ON sessions (course, date)"
ana@dev:~/planner/db$ node plan.ts
one course, one week: 8 rows
  SEARCH sessions USING INDEX sessions_course_date (course=? AND date>? AND date<?)
every course, one week: 158 rows
  SCAN sessions
ana@dev:~/planner/db$ sqlite3 big.db "CREATE INDEX sessions_date ON sessions (date)"
ana@dev:~/planner/db$ node plan.ts
one course, one week: 8 rows
  SEARCH sessions USING INDEX sessions_course_date (course=? AND date>? AND date<?)
every course, one week: 158 rows
  SEARCH sessions USING INDEX sessions_date (date>? AND date<?)
```

**`SCAN sessions` quer dizer que cada uma das 20.000 linhas é lida para devolver 8.** Esse é o
trabalho que a consulta custa a cada visita à tela, e ele cresce com o histórico. Depois de
`sessions_course_date`, a primeira consulta é um `SEARCH`: o SQLite percorre o índice até as linhas
em que `course` é `statistics` e a data está dentro da semana, e lê só essas.

A segunda consulta não mudou. Um índice em `(course, date)` é ordenado primeiro pelo curso, então
ele ajuda uma consulta que cita um curso e não ajuda uma que não cita, do mesmo jeito que uma lista
telefônica ordenada por sobrenome não ajuda a achar todo mundo que se chama Ana. A tela da semana
precisou de um índice próprio, em `date`, e aí ela também virou um `SEARCH`.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l03-scan\" aria-label=\"Duas faixas representando as 20.000 linhas do big.db. Sem índice, o SCAN lê a faixa inteira para devolver 8 linhas. Com o índice em (course, date), as linhas ficam ordenadas por curso e depois por data, e o SEARCH salta para o bloco de statistics e lê só as 8 linhas dentro da semana.\"><defs><marker id=\"l03-scan-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"20\" y=\"24\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">sem índice: SCAN</text><rect x=\"20\" y=\"36\" width=\"680\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><path d=\"M30 38 L30 60\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M40 38 L40 60\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M50 38 L50 60\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M60 38 L60 60\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M70 38 L70 60\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M80 38 L80 60\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M90 38 L90 60\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M100 38 L100 60\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M110 38 L110 60\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M120 38 L120 60\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M130 38 L130 60\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M140 38 L140 60\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M150 38 L150 60\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M160 38 L160 60\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M170 38 L170 60\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M180 38 L180 60\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M190 38 L190 60\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M200 38 L200 60\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M210 38 L210 60\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M220 38 L220 60\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M230 38 L230 60\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M240 38 L240 60\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M250 38 L250 60\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M260 38 L260 60\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M270 38 L270 60\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M280 38 L280 60\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M290 38 L290 60\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M300 38 L300 60\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M310 38 L310 60\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M320 38 L320 60\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M330 38 L330 60\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M340 38 L340 60\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M350 38 L350 60\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M360 38 L360 60\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M370 38 L370 60\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M380 38 L380 60\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M390 38 L390 60\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M400 38 L400 60\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M410 38 L410 60\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M420 38 L420 60\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M430 38 L430 60\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M440 38 L440 60\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M450 38 L450 60\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M460 38 L460 60\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M470 38 L470 60\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M480 38 L480 60\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M490 38 L490 60\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M500 38 L500 60\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M510 38 L510 60\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M520 38 L520 60\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M530 38 L530 60\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M540 38 L540 60\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M550 38 L550 60\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M560 38 L560 60\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M570 38 L570 60\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M580 38 L580 60\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M590 38 L590 60\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M600 38 L600 60\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M610 38 L610 60\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M620 38 L620 60\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M630 38 L630 60\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M640 38 L640 60\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M650 38 L650 60\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M660 38 L660 60\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M670 38 L670 60\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M680 38 L680 60\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M690 38 L690 60\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"360\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">cada uma das 20.000 linhas é lida · 8 devolvidas</text><text x=\"20\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">índice em (course, date): SEARCH</text><rect x=\"20.0\" y=\"122\" width=\"113.3\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"76.7\" y=\"135\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">chemistry</text><rect x=\"133.3\" y=\"122\" width=\"113.3\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"190.0\" y=\"135\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">guitar</text><rect x=\"246.7\" y=\"122\" width=\"113.3\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"303.3\" y=\"135\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">history</text><rect x=\"360.0\" y=\"122\" width=\"113.3\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"416.7\" y=\"135\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">piano</text><rect x=\"473.3\" y=\"122\" width=\"113.3\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"530.0\" y=\"135\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">spanish</text><rect x=\"586.7\" y=\"122\" width=\"113.3\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"643.3\" y=\"135\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">statistics</text><text x=\"360\" y=\"162\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">o índice, ordenado por curso e depois por data</text><rect x=\"656.7\" y=\"180\" width=\"8\" height=\"26\" rx=\"4\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><path d=\"M660.7 150 L660.7 178\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l03-scan-ah-phosphor)\"></path><text x=\"644.7\" y=\"193\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">só as 8 linhas de statistics na semana</text></svg>", "caption": "A mesma consulta, nas mesmas linhas. O índice custa uma segunda cópia ordenada de duas colunas, e compra o direito de ler 8 linhas em vez de 20.000."}
```

## O que um índice custa

Um índice é uma segunda cópia, ordenada, das colunas que ele cobre, e não sai de graça. Comece de
novo de um `big.db` novo e meça o arquivo antes e depois dos dois índices:

```
ana@dev:~/planner/db$ rm big.db
ana@dev:~/planner/db$ node big.ts
{ n: 20000, first: '2023-11-01', last: '2026-10-31' }
ana@dev:~/planner/db$ wc -c big.db
1015808 big.db
ana@dev:~/planner/db$ sqlite3 big.db "CREATE INDEX sessions_course_date ON sessions (course, date)"
ana@dev:~/planner/db$ sqlite3 big.db "CREATE INDEX sessions_date ON sessions (date)"
ana@dev:~/planner/db$ wc -c big.db
1912832 big.db
```

**Os dois índices quase dobraram o arquivo**, de 1.015.808 bytes para 1.912.832, porque cada um
repete a data de cada linha, e o primeiro repete também o curso. Toda inserção e toda atualização
agora grava a tabela e os dois índices.

A regra que sai disso é a que este curso usa: **indexe para as consultas que uma tela de fato
roda**, e confira cada uma com `EXPLAIN QUERY PLAN` em vez de adivinhar. O Room declara um com
`@Entity(indices = [Index(value = ["course", "date"])])`, o SwiftData com `#Index` a partir do
iOS 18, e o plano de consulta que decide se algum deles ajuda é o do SQLite.
