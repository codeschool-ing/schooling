---
title: Um teste de contrato
version: 1
---

**Um teste de contrato escreve o que cada versão suportada lê, e faz o build do servidor falhar
quando uma resposta deixa de entregar isso.** Os testes do próprio servidor conferem que ele faz o
que os desenvolvedores querem hoje. Este confere que ele ainda faz o que um app compilado há um ano
espera, e ninguém do time do servidor está pensando nisso quando renomeia um campo.

## Um arquivo por versão

Cada versão da janela de suporte ganha um arquivo que lista, para cada endpoint que ela chama, os
campos que lê e o que espera deles: um tipo, ou a lista de valores que ela sabe desenhar. Crie uma
pasta para eles com `mkdir ~/planner/contracts`.

Salve isto em `~/planner/contracts` como `1.3.1.json`:

```json
{
  "GET /sessions": {
    "id": "string",
    "course": "string",
    "minutes": "number",
    "day": "string",
    "status": ["done", "planned"]
  }
}
```

A 1.5.2 lê os mesmos campos e aprendeu mais um status, `"skipped"`, quando pular uma sessão virou
recurso. Salve isto em `~/planner/contracts` como `1.5.2.json`:

```json
{
  "GET /sessions": {
    "id": "string",
    "course": "string",
    "minutes": "number",
    "day": "string",
    "status": ["done", "planned", "skipped"]
  }
}
```

Num projeto real, esses arquivos são escritos a partir do código do app, por quem muda o jeito como
o app lê uma resposta, no mesmo pull request. Times de Kotlin, Swift e React Native fazem a mesma
coisa com ferramentas diferentes; o Pact é uma comum, que grava o contrato a partir dos testes do
próprio cliente. A ideia é a mesma em todas, e cabe num script.

## O teste

Salve isto como `contract.ts`. Ele pega o módulo que monta as respostas do servidor, pede as sessões
a ele, e confere cada sessão contra o arquivo de cada versão:

```schooling-example
{"language": "typescript", "file": "contract.ts", "parts": [{"code": "// contract.ts: every supported version's contract, checked against what the server would send\nimport { readdirSync, readFileSync } from \"node:fs\";\n\nconst { sessions } = await import(`./${process.argv[2]}`);\nconst body: Record<string, unknown>[] = sessions();", "note": "O módulo dado na linha de comando monta a resposta. O teste o chama diretamente, então nenhum servidor precisa rodar."}, {"code": "function problems(item: Record<string, unknown>, fields: Record<string, string | string[]>): string[] {\n  const found: string[] = [];\n  for (const [field, want] of Object.entries(fields)) {\n    const value = item[field];\n    if (value === undefined) found.push(`${field} is missing`);\n    else if (Array.isArray(want)) { if (!want.includes(value as string)) found.push(`${field} \"${value}\" is not one of ${want.join(\", \")}`); }\n    else if (typeof value !== want) found.push(`${field} is a ${typeof value}, not a ${want}`);\n  }\n  return found;\n}", "note": "Três jeitos de quebrar uma promessa: o campo sumiu, guarda um valor que a versão não sabe desenhar, ou mudou de tipo. Um campo que o arquivo não lista nunca é conferido, e é isso que deixa o servidor acrescentar um."}, {"code": "let failed = 0;\nfor (const file of readdirSync(\"contracts\").sort()) {\n  const version = file.replace(/\\.json$/, \"\");\n  const fields = JSON.parse(readFileSync(`contracts/${file}`, \"utf8\"))[\"GET /sessions\"];\n  const broken = body.flatMap((item) => problems(item, fields).map((p) => `${item.id}: ${p}`));\n  console.log(`${version}  GET /sessions  ${broken.length ? \"BROKEN\" : \"ok\"}`);\n  for (const b of broken) console.log(`  ${b}`);\n  failed += broken.length;\n}\nprocess.exitCode = failed ? 1 : 0;", "note": "Uma linha por versão, cada promessa quebrada embaixo dela, e um status de saída em que o pipeline pode parar."}]}
```

## Duas mudanças no servidor

A resposta da semana é montada por uma função, então o teste pode chamá-la sem subir nada. Aqui estão
duas propostas para o próximo lançamento do servidor.

A primeira acrescenta `seconds` ao lado de `minutes`, o passo de expandir da seção anterior. Salve
isto como `api-additive.ts`:

```typescript
// api-additive.ts: adds seconds beside minutes; every old field stays as it was
export function sessions() {
  return [
    { id: "s-101", course: "statistics", minutes: 25, seconds: 1500, day: "2026-10-12", status: "done" },
    { id: "s-102", course: "python", minutes: 40, seconds: 2400, day: "2026-10-13", status: "planned" },
  ];
}
```

A segunda renomeia `minutes` para `durationMinutes`, porque o nome é mais claro, e devolve uma sessão
pulada, agora que a 1.5.2 sabe desenhar uma. Salve isto como `api-rename.ts`:

```typescript
// api-rename.ts: a clearer name for minutes, and the new skipped status
export function sessions() {
  return [
    { id: "s-101", course: "statistics", durationMinutes: 25, day: "2026-10-12", status: "done" },
    { id: "s-102", course: "python", durationMinutes: 40, day: "2026-10-13", status: "planned" },
    { id: "s-103", course: "python", durationMinutes: 30, day: "2026-10-14", status: "skipped" },
  ];
}
```

Rode o teste contra as duas:

```
ana@dev:~/planner$ node contract.ts api-additive.ts; echo "exit status $?"
1.3.1  GET /sessions  ok
1.5.2  GET /sessions  ok
exit status 0
ana@dev:~/planner$ node contract.ts api-rename.ts; echo "exit status $?"
1.3.1  GET /sessions  BROKEN
  s-101: minutes is missing
  s-102: minutes is missing
  s-103: minutes is missing
  s-103: status "skipped" is not one of done, planned
1.5.2  GET /sessions  BROKEN
  s-101: minutes is missing
  s-102: minutes is missing
  s-103: minutes is missing
exit status 1
```

**A mudança aditiva passa para as duas versões, e o status de saída é 0. A renomeação quebra as
duas, e a 1.3.1 por dois motivos.** Toda sessão perdeu `minutes`, que as duas versões somam para a
semana, e a sessão pulada traz um status que a 1.3.1 nunca aprendeu a desenhar, coisa que um
desenvolvedor do servidor trabalhando no recurso da 1.5.2 tinha todo motivo para achar que estava
certa. O status de saída 1 é o que faz disso um teste: rode-o no pipeline do servidor, lição 10, e a
renomeação nunca chega à produção.

## O que o teste não cobre

- **Comportamento.** Um campo pode manter nome e tipo e mudar de significado: `minutes` arredondado
  de outro jeito, `day` em UTC em vez do fuso da pessoa. O contrato registra o formato; o
  significado exige que os arquivos carreguem valores, e que uma pessoa pense.
- **Requisições.** Este teste confere respostas. O que cada versão *manda* é a outra metade: um campo
  obrigatório novo numa requisição quebra toda versão antiga do mesmo jeito, e ganha um arquivo
  próprio na mesma pasta.
- **Versões que ninguém registrou.** Uma versão sem arquivo não está protegida. Quando uma versão
  sai da janela de suporte, apague o arquivo dela no mesmo pull request que deixa de suportá-la, e a
  pasta continua sendo uma lista verdadeira.
