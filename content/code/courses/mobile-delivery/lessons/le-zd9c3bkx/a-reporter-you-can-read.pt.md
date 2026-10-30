---
title: Um coletor de crashes que você consegue ler
version: 1
---

**Um coletor de crashes cabe em quarenta linhas, e escrever um é o jeito mais rápido de saber o que
os de verdade mandam.** Este roda no Node em vez de num celular, mas tem as mesmas quatro partes da
seção anterior: começa primeiro, guarda migalhas, grava um relatório quando o processo morre e manda
o que está no disco na próxima vez que começa.

## O coletor

Salve isto como `reporter.ts` em `~/planner`:

```schooling-example
{"language": "typescript", "file": "reporter.ts", "parts": [{"code": "// reporter.ts: a crash reporter in the shape every mobile one has: save on crash, send on next launch\nimport { randomUUID } from \"node:crypto\";\nimport { existsSync, mkdirSync, readdirSync, readFileSync, rmSync, writeFileSync } from \"node:fs\";\nimport { platform, release } from \"node:os\";\n\ntype Options = { version: string; build: number; endpoint: string };\nconst DIR = \"crashes\";\nconst crumbs: string[] = [];", "note": "Os relatórios esperam numa pasta chamada `crashes`. As migalhas moram na memória, porque só importam se o app morrer com elas."}, {"code": "function installId(): string {\n  if (!existsSync(\"install-id\")) writeFileSync(\"install-id\", randomUUID());\n  return readFileSync(\"install-id\", \"utf8\");\n}", "note": "Um identificador aleatório, criado uma vez e guardado num arquivo: ele conta instalações sem nomear ninguém."}, {"code": "export function breadcrumb(text: string) {\n  crumbs.push(text);\n  if (crumbs.length > 20) crumbs.shift();\n}", "note": "As últimas vinte coisas que o app disse ter feito. As mais antigas caem."}, {"code": "async function sendPending(endpoint: string) {\n  if (!existsSync(DIR)) return;\n  for (const name of readdirSync(DIR).sort()) {\n    const body = readFileSync(`${DIR}/${name}`, \"utf8\");\n    try {\n      const res = await fetch(endpoint, { method: \"POST\", headers: { \"content-type\": \"application/json\" }, body });\n      if (res.ok) rmSync(`${DIR}/${name}`);\n    } catch {\n      // No network: the report stays on disk and goes with the next launch.\n    }\n  }\n}", "note": "Todo relatório no disco é mandado, e só apagado depois que o servidor o aceitou. Sem rede, ele espera a abertura seguinte."}, {"code": "export async function start(o: Options) {\n  await sendPending(o.endpoint);\n  process.on(\"uncaughtException\", (err) => {\n    const report = {\n      version: o.version, build: o.build, os: `${platform()} ${release()}`,\n      install: installId(), at: new Date().toISOString(), breadcrumbs: crumbs,\n      error: { type: err.name, message: err.message, stack: err.stack?.split(\"\\n\").slice(1, 4).map((l) => l.trim()) },\n    };\n    mkdirSync(DIR, { recursive: true });\n    writeFileSync(`${DIR}/${Date.now()}.json`, JSON.stringify(report, null, 2));\n    process.exit(1);\n  });\n}", "note": "Na abertura: mandar o que o último crash deixou, e então esperar o próximo. Num crash: gravar o relatório, de forma síncrona, e sair. Nada é mandado de um processo morrendo."}]}
```

## Um app para quebrar, e um servidor para receber

O "app" é a tela de Estatísticas do planner com um bug: ela procura um curso que não está na lista.
Salve isto como `app.ts`:

```typescript
// app.ts: the planner, launched like an app, with the crash reporter started first
import { breadcrumb, start } from "./reporter.ts";

await start({ version: "1.5.0", build: 1050003, endpoint: "http://127.0.0.1:4312/crashes" });
const screen = process.argv[2] ?? "week";
breadcrumb(`open ${screen}`);

const courses: Record<string, { sessions: number[] }> = { spanish: { sessions: [30, 30] } };
if (screen === "statistics") {
  breadcrumb("tap Statistics for guitar");
  console.log(courses["guitar"].sessions.length);
}
console.log(`the planner showed ${screen}`);
```

E o servidor, que grava uma linha por relatório recebido. Salve isto como `collector.ts`, e o inicie
num segundo terminal com `node collector.ts`:

```typescript
// collector.ts: the server a crash reporter sends to, reduced to printing what arrives
import { createServer } from "node:http";
import { appendFileSync } from "node:fs";

createServer((req, res) => {
  if (req.method !== "POST") return res.writeHead(404).end();
  let body = "";
  req.on("data", (chunk) => (body += chunk));
  req.on("end", () => {
    const r = JSON.parse(body);
    appendFileSync("collected.log", `${r.version} (${r.build}) ${r.error.type}: ${r.error.message} | ${r.breadcrumbs.join(" > ")}\n`);
    res.writeHead(201).end();
  });
}).listen(4312, "127.0.0.1");
```

## O crash, o relatório e a abertura seguinte

```
ana@dev:~/planner$ node app.ts statistics; echo "exit status $?"
exit status 1
ana@dev:~/planner$ cat crashes/*.json
{
  "version": "1.5.0",
  "build": 1050003,
  "os": "linux 6.18.44-fc-v185",
  "install": "883eb634-dd16-40b2-8b0a-23164a6fd7c2",
  "at": "2026-10-30T18:50:39.606Z",
  "breadcrumbs": [
    "open statistics",
    "tap Statistics for guitar"
  ],
  "error": {
    "type": "TypeError",
    "message": "Cannot read properties of undefined (reading 'sessions')",
    "stack": [
      "at file:///home/ana/planner/app.ts:11:33"
    ]
  }
}
ana@dev:~/planner$ node app.ts week
the planner showed week
ana@dev:~/planner$ ls crashes; cat collected.log
1.5.0 (1050003) TypeError: Cannot read properties of undefined (reading 'sessions') | open statistics > tap Statistics for guitar
```

Leia em ordem. **O app não imprimiu nada e saiu com 1**: é isso que uma pessoa vê, um app que
sumiu. O relatório esperou no disco. **A abertura seguinte o mandou antes de mostrar qualquer
coisa**, a tela da semana apareceu, e a pasta `crashes` ficou vazia de novo.

## Lendo o relatório como quem decide o que mandar

Cada campo ali foi escolhido, e cada um é uma linha do inventário da lição 5:

- `install` é um **identificador aleatório** criado no primeiro crash e guardado num arquivo. Ele
  conta pessoas sem nomeá-las, e muda se o app for reinstalado, que é o ponto.
- `os` veio da máquina. Num celular são o modelo e a versão do sistema, que é o que a regra da lição
  8 precisa para agrupar crashes por aparelho.
- `breadcrumbs` são **o que quer que o app tenha escrito nelas**. "tap Statistics for guitar" é
  inofensivo; uma migalha com o texto que a pessoa digitou numa busca é coletá-lo. As migalhas são o
  lugar por onde dados pessoais vazam para relatórios de crash, mais do que em qualquer outro.
- A `stack` nomeia um caminho de arquivo no computador que gerou o código. Num celular é uma função
  num build minificado ou compilado, e a lição 13 é como ela volta a ser legível.
