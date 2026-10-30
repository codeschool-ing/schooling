---
title: Última escrita vence, e o que ela joga fora
version: 1
---

**Na regra da última escrita vence, fica a escrita com o carimbo mais novo, e a outra é descartada
inteira.** É o padrão de muitas camadas de sincronização e da maioria das escritas à mão, porque é
uma comparação só e sempre dá uma resposta. O problema está na palavra *inteira*: o registro é
substituído, não mesclado, então tudo o que a escrita perdedora mudou vai junto com ela.

O programa abaixo encena a manhã da seção anterior. Um servidor guarda `s3`, cada aparelho guarda
uma cópia, e quatro eventos acontecem na ordem em que aconteceram: duas edições offline, depois duas
sincronizações. Cada edição carimba a cópia com o relógio do aparelho, e cada sincronização só
mantém a cópia se o carimbo dela for mais novo que o do servidor. Crie a pasta `~/planner/lww` e
salve-o nela como `lww.ts`:

```schooling-example
{"language": "typescript", "file": "lww.ts", "parts": [{"code": "// lww.ts: two devices edit one session offline, and the server keeps the last write.\ntype Session = { id: string; course: string; date: string; minutes: number; done: boolean };\ntype Change = Partial<Pick<Session, \"minutes\" | \"done\">>;\n\nconst [policy = \"device-clock\", ...args] = process.argv.slice(2);\nconst skew: Record<string, number> = {}; // minutes a device's clock is ahead\nfor (const a of args) {\n  const [device, by] = a.split(\"=\");\n  skew[device] = Number(by);\n}\n", "note": "Uma sessão, os campos que uma edição pode mudar e os argumentos: qual relógio carimba uma escrita, e quantos minutos o relógio de um aparelho está adiantado."}, {"code": "function at(hhmm: string, plus = 0): string {\n  const [h, m] = hhmm.split(\":\").map(Number);\n  const t = h * 60 + m + plus;\n  return `${String(Math.floor(t / 60)).padStart(2, \"0\")}:${String(t % 60).padStart(2, \"0\")}`;\n}\n", "note": "Uma hora do dia como HH:MM, adiantada alguns minutos. Strings nesse formato se ordenam no tempo, então o `>` as compara."}, {"code": "let server = { session: { id: \"s3\", course: \"guitar\", date: \"2026-10-21\", minutes: 20, done: false }, stamp: \"09:00\" };\nconst copies: Record<string, { session: Session; stamp: string }> = {\n  phone: structuredClone(server),\n  tablet: structuredClone(server),\n};\n", "note": "A linha do servidor, carimbada 09:00, e uma cópia dela em cada aparelho, que é o que os dois tinham antes de a manhã começar."}, {"code": "// What happened, at the true time it happened. Both devices are offline until they sync.\nconst events: { time: string; device: string; change?: Change }[] = [\n  { time: \"10:05\", device: \"phone\", change: { minutes: 30 } },\n  { time: \"10:20\", device: \"tablet\", change: { done: true } },\n  { time: \"10:40\", device: \"tablet\" },\n  { time: \"11:00\", device: \"phone\" },\n];\n", "note": "A manhã, na ordem em que aconteceu: duas edições feitas offline, depois a sincronização de cada aparelho quando achou rede."}, {"code": "console.log(`policy: ${policy}` + (args.length ? `, ${args.join(\" \")}` : \"\"));\nfor (const e of events) {\n  const copy = copies[e.device];\n  const who = `${e.time} ${e.device.padEnd(7)}`;\n  if (e.change) {\n    const [field, value] = Object.entries(e.change)[0];\n    const before = copy.session[field as keyof Change];\n    copy.session = { ...copy.session, ...e.change };\n    copy.stamp = at(e.time, skew[e.device] ?? 0);\n    console.log(`${who} edits s3: ${field} ${before} -> ${value}, stamped ${copy.stamp}`);\n    continue;\n  }", "note": "Uma edição muda a cópia local e a carimba com o relógio do aparelho, com o adiantamento. A mudança é dobrada numa sessão inteira aqui, e daqui em diante nada registra qual campo foi mexido."}, {"code": "  // Last write wins: the newer stamp replaces the whole row; the older one is dropped.\n  const stamp = policy === \"server-clock\" ? e.time : copy.stamp;\n  if (stamp > server.stamp) {\n    server = { session: copy.session, stamp };\n    console.log(`${who} syncs: ${stamp} is newer than the server's row, kept`);\n  } else {\n    console.log(`${who} syncs: ${stamp} is older than the server's ${server.stamp}, dropped`);\n  }\n}", "note": "A regra em si. Uma sincronização mantém a cópia se o carimbo for mais novo que o do servidor, e a descarta se não for. Com `server-clock`, o carimbo é a hora em que a escrita chegou."}, {"code": "console.log(`server s3: minutes ${server.session.minutes}, done ${server.session.done}`);", "note": "O que o servidor guarda no fim."}]}
```

Rode com os relógios dos aparelhos como carimbo, que é o que um app faz quando grava
`updated_at = now()` no aparelho:

```
ana@dev:~/planner/lww$ node lww.ts device-clock
policy: device-clock
10:05 phone   edits s3: minutes 20 -> 30, stamped 10:05
10:20 tablet  edits s3: done false -> true, stamped 10:20
10:40 tablet  syncs: 10:20 is newer than the server's row, kept
11:00 phone   syncs: 10:05 is older than the server's 10:20, dropped
server s3: minutes 20, done true
```

O servidor termina com 20 minutos, feita. **A mudança da Ana para 30 minutos sumiu, e nada avisou.**
A sincronização do celular às 11:00 foi respondida, a caixa de saída do celular esvaziou, e a
próxima puxada vai pôr de volta, em silêncio, 20 minutos no celular dela. Se ela chegar a perceber,
vai achar que esqueceu de salvar.

## Por que foi a linha, e não o campo

A escrita perdedora não mexeu em `done`, e a vencedora não mexeu em `minutes`. Elas mudaram campos
diferentes, e uma regra que olhasse campos teria guardado as duas. A última escrita vence olha
linhas, porque o carimbo está na linha: `copy.session = { ...copy.session, ...e.change }` dobra a
mudança numa sessão completa, e dali em diante o programa não sabe mais quais campos a Ana de fato
mexeu. É essa informação que a aula 14 guarda, com uma mescla campo a campo contra a versão de que
os dois aparelhos partiram.

**Escreva o que a última escrita vence custa antes de escolhê-la**, numa frase por tabela: "se dois
aparelhos mudam uma sessão enquanto estão offline, a carimbada mais tarde substitui a outra,
inclusive nos campos que não mudou". Uma equipe que consegue ler essa frase em voz alta e aceitá-la
tomou uma decisão. Uma que não consegue tem um bug que nenhum teste com um aparelho só vai mostrar.
