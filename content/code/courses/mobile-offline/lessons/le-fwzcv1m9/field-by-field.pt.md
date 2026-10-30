---
title: Mesclar campo a campo, contra a versão de que os dois partiram
version: 1
---

**Para mesclar duas edições você precisa de três versões, não de duas: a de que os dois aparelhos
partiram, e a cópia de cada aparelho.** Só com as duas cópias, o celular vê `minutes 30, done false`
e o servidor `minutes 20, done true`, e não sabe quem mudou o quê. O celular pôs 30, ou o tablet pôs
20? O `done` foi marcado, ou desmarcado? A versão de que os dois partiram, a **base**, responde cada
uma dessas perguntas, porque um campo que ainda tem o valor da base é um campo que aquele lado não
mexeu.

Então um aparelho que edita offline guarda duas cópias de cada linha que muda: a linha como o
servidor a mandou da última vez, e a linha como a pessoa a editou desde então. O Git faz o mesmo com
um ancestral comum, e chama isso de **mescla de três vias**.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l14-merge\" aria-label=\"Uma mescla de três vias da sessão s3, campo a campo. Colunas: base, a versão de que os dois aparelhos partiram; a cópia do celular; a cópia do tablet; a mescla. minutes: base 20, celular 30, tablet 20, mescla 30, tirado do celular. done: base false, celular false, tablet true, mescla true, tirado do tablet. course: guitar nos três, mantido. Embaixo, o outro caso: minutes base 20, celular 30, tablet 25: os dois mudaram, então é um conflito e os dois valores ficam guardados para a pessoa.\"><text x=\"150\" y=\"26\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">base</text><text x=\"250\" y=\"26\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">celular</text><text x=\"350\" y=\"26\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">tablet</text><text x=\"450\" y=\"26\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">mescla</text><text x=\"20\" y=\"57\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">minutes</text><rect x=\"110\" y=\"42\" width=\"80\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"150.0\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">20</text><rect x=\"210\" y=\"42\" width=\"80\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"250.0\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">30</text><rect x=\"310\" y=\"42\" width=\"80\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"350.0\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">20</text><rect x=\"410\" y=\"42\" width=\"80\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"450.0\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">30</text><text x=\"505\" y=\"57\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">só o celular mudou</text><text x=\"20\" y=\"97\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">done</text><rect x=\"110\" y=\"82\" width=\"80\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"150.0\" y=\"97.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">false</text><rect x=\"210\" y=\"82\" width=\"80\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"250.0\" y=\"97.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">false</text><rect x=\"310\" y=\"82\" width=\"80\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"350.0\" y=\"97.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">true</text><rect x=\"410\" y=\"82\" width=\"80\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"450.0\" y=\"97.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">true</text><text x=\"505\" y=\"97\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">só o tablet mudou</text><text x=\"20\" y=\"137\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">course</text><rect x=\"110\" y=\"122\" width=\"80\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"150.0\" y=\"137.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">guitar</text><rect x=\"210\" y=\"122\" width=\"80\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"250.0\" y=\"137.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">guitar</text><rect x=\"310\" y=\"122\" width=\"80\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"350.0\" y=\"137.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">guitar</text><rect x=\"410\" y=\"122\" width=\"80\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"450.0\" y=\"137.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">guitar</text><text x=\"505\" y=\"137\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">ninguém mudou</text><text x=\"20\" y=\"186\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">o outro caso: o mesmo campo dos dois lados</text><text x=\"20\" y=\"219\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">minutes</text><rect x=\"110\" y=\"204\" width=\"80\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"150.0\" y=\"219.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">20</text><rect x=\"210\" y=\"204\" width=\"80\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"250.0\" y=\"219.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">30</text><rect x=\"310\" y=\"204\" width=\"80\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"350.0\" y=\"219.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">25</text><rect x=\"410\" y=\"204\" width=\"180\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"500.0\" y=\"219.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">conflito: guardar os dois</text><text x=\"600\" y=\"219\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">os dois mudaram, diferente</text></svg>", "caption": "Um campo ainda no valor da base é um campo que aquele lado não mexeu. Só um campo que os dois lados mudaram, para valores diferentes, é um conflito de verdade.", "same": ["base", "tablet"]}
```

## A regra

Campo a campo, há quatro casos. Os dois lados concordam: mantém. Só um lado difere da base: aquele
lado mudou, fica o valor dele. Os dois diferem da base e entre si: **esse campo é um conflito de
verdade**, e nada no dado diz qual valor está certo. Salve isto como `merge3.ts` na
`~/planner/versions`:

```typescript
// merge3.ts: merge two edits of one record against the version both started from.
export type Fields = Record<string, unknown>;

export function merge3(base: Fields, mine: Fields, theirs: Fields) {
  const merged: Fields = {};
  const conflicts: string[] = [];
  for (const k of Object.keys(base)) {
    if (mine[k] === theirs[k]) merged[k] = mine[k]; // both agree
    else if (mine[k] === base[k]) merged[k] = theirs[k]; // only they changed it
    else if (theirs[k] === base[k]) merged[k] = mine[k]; // only I changed it
    else {
      merged[k] = theirs[k]; // both changed it: a real conflict
      conflicts.push(k);
    }
  }
  return { merged, conflicts };
}
```

A sincronização do celular o usa quando o servidor responde 409. Ela manda a edição com a versão que
leu; numa recusa, mescla a base, a cópia dela e a linha atual do servidor, e se nenhum campo
conflita manda a mescla com a versão do servidor. Salve como `sync.ts`:

```schooling-example
{"language": "typescript", "file": "sync.ts", "parts": [{"code": "// sync.ts: the phone sends its edit of s3; on a 409 it merges with the server's row and tries again.\nimport { merge3, type Fields } from \"./merge3.ts\";\n\nconst fields = [\"course\", \"date\", \"minutes\", \"done\"];\nconst pick = (row: Fields) => Object.fromEntries(fields.map((k) => [k, row[k]]));\n", "note": "Os campos que formam uma sessão, e uma função que guarda só eles de uma linha que o servidor mandou, que também traz `id` e `version`."}, {"code": "// What the phone last received from the server, and the edit made on top of it, offline.\nlet base: Fields = { course: \"guitar\", date: \"2026-10-21\", minutes: 20, done: false };\nlet version = 1;\nlet mine: Fields = { ...base };\nfor (const arg of process.argv.slice(2)) {\n  const [k, v] = arg.split(\"=\");\n  mine[k] = k === \"minutes\" ? Number(v) : v === \"true\";\n}\n", "note": "As duas cópias que o aparelho guarda: `base`, como o servidor mandou da última vez na versão 1, e `mine`, a edição da pessoa por cima dela. Os argumentos dizem o que foi editado, como `minutes=30`."}, {"code": "for (let attempt = 1; attempt <= 3; attempt++) {\n  const res = await fetch(\"http://localhost:8014/sessions/s3\", {\n    method: \"PUT\",\n    body: JSON.stringify({ ...mine, version }),\n  });\n  const reply = await res.json();\n  console.log(`PUT with version ${version}: ${res.status}`);\n  if (res.ok) {\n    console.log(\"saved  \", JSON.stringify(reply));\n    break;\n  }", "note": "Manda a edição com a versão de que ela partiu. Um 200 quer dizer que ninguém escreveu no meio, e a resposta é a linha salva."}, {"code": "  const theirs = pick(reply.current);\n  const { merged, conflicts } = merge3(base, mine, theirs);\n  if (conflicts.length) {\n    console.log(`conflict on ${conflicts.join(\", \")}: both versions kept for the person`);\n    console.log(`  mine   ${JSON.stringify(pick(mine))}`);\n    console.log(`  theirs ${JSON.stringify(theirs)}`);\n    break;\n  }", "note": "Um 409 traz a linha atual do servidor. Mescla contra a base; se um campo mudou dos dois lados, para e guarda as duas cópias."}, {"code": "  console.log(\"merged \", JSON.stringify(merged));\n  [base, mine, version] = [theirs, merged, reply.current.version];\n}", "note": "Se não, a mescla vira a nova edição, a linha do servidor vira a nova base, e a próxima tentativa cita a versão do servidor."}]}
```

## Os dois casos

Primeiro a manhã da aula 13: o tablet marca a sessão, depois o celular manda os 30 minutos. O
servidor acabou de ser reiniciado, então `s3` está de volta à versão 1:

```
ana@dev:~/planner/versions$ curl -s -X PUT http://localhost:8014/sessions/s3 -d '{"course":"guitar","date":"2026-10-21","minutes":20,"done":true,"version":1}' -w '%{http_code}\n'
{"id":"s3","course":"guitar","date":"2026-10-21","minutes":20,"done":true,"version":2}
200
ana@dev:~/planner/versions$ node sync.ts minutes=30
PUT with version 1: 409
merged  {"course":"guitar","date":"2026-10-21","minutes":30,"done":true}
PUT with version 2: 200
saved   {"id":"s3","course":"guitar","date":"2026-10-21","minutes":30,"done":true,"version":3}
```

**As duas edições sobreviveram.** O primeiro `PUT` foi recusado, a mescla tirou `minutes` do celular
e `done` do tablet, e o segundo `PUT`, com a versão 2, foi aceito como versão 3. Ninguém foi
perguntado nada, porque não havia nada a perguntar: os dois aparelhos mudaram campos diferentes.

Depois, o caso que a mescla não resolve. O tablet muda a mesma sessão para 25 minutos, e o celular,
offline, para 30:

```
ana@dev:~/planner/versions$ curl -s -X PUT http://localhost:8014/sessions/s3 -d '{"course":"guitar","date":"2026-10-21","minutes":25,"done":false,"version":1}' -w '%{http_code}\n'
{"id":"s3","course":"guitar","date":"2026-10-21","minutes":25,"done":false,"version":2}
200
ana@dev:~/planner/versions$ node sync.ts minutes=30
PUT with version 1: 409
conflict on minutes: both versions kept for the person
  mine   {"course":"guitar","date":"2026-10-21","minutes":30,"done":false}
  theirs {"course":"guitar","date":"2026-10-21","minutes":25,"done":false}
```

`minutes` mudou dos dois lados, para valores diferentes, então o programa para e guarda as duas
cópias. O servidor continua com 25, e os 30 do celular não se perderam: estão em `mine`, esperando
alguém escolher. **Esse é o único caso que uma mescla deve entregar a uma pessoa**, e ele é bem mais
raro que os conflitos que a última escrita vence vinha resolvendo em silêncio, porque a maioria das
edições concorrentes mexe em campos diferentes.
