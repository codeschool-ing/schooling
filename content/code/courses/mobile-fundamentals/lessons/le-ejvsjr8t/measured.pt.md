---
title: A mesma ordenação, no caminho dos quadros e ao lado deles
version: 1
---

**Esta seção roda a regra em vez de enunciá-la: a mesma ordenação, uma vez na thread que mantém os
quadros e outra num worker ao lado, com os quadros perdidos contados.** O programa é Node.js, não
um celular. O Node roda JavaScript numa thread só, com um laço de eventos, o formato que a primeira
seção desta aula descreveu, e o módulo `worker_threads` dele inicia uma segunda thread com um laço
próprio. Um timer que dispara a cada 16,67 ms faz o papel da tela. Nada se move na tela, mas a
contagem de quadros que o timer perdeu é exatamente o que teria se movido.

O trabalho é o do planner: ordenar um mês de sessões de estudo por data e depois por duração, a
ordem em que a visão da semana as mostra. Trezentas mil sessões são muito mais do que um aluno
planeja, e isso é de propósito. Elas fazem o papel do documento JSON grande e da lista longa da
seção anterior, e deixam o custo grande o bastante para medir em qualquer computador.

## O programa

Salve isto como `frames.ts` em `~/planner`, ao lado do `planner.ts` da aula 1, cujo tipo `Session`
ele importa:

```schooling-example
{"language": "typescript", "file": "frames.ts", "parts": [{"code": "// frames.ts: a 60 Hz frame clock, and a sort that runs in its way or beside it\nimport { Worker, isMainThread, parentPort } from \"node:worker_threads\";\nimport type { Session } from \"./planner.ts\";\n\nconst mode = process.argv[2] ?? \"idle\"; // idle, main or worker\nconst N = Number(process.argv[3] ?? 300000);\n", "note": "O programa recebe dois argumentos: onde a ordenação roda e quantas sessões ela ordena. `Session` é o tipo da aula 1, importado de `planner.ts`; o `import type` some quando o `node` remove os tipos."}, {"code": "// N sessions from a fixed seed, so every run sorts the same data\nfunction makeSessions(n: number): Session[] {\n  let seed = 42;\n  const next = () => (seed = (seed * 16807) % 2147483647);\n  const out: Session[] = [];\n  for (let i = 0; i < n; i++) {\n    const day = String(1 + (next() % 28)).padStart(2, \"0\");\n    out.push({\n      id: \"s\" + i,\n      courseId: next() % 2 === 0 ? \"sql\" : \"mobile\",\n      date: `2026-10-${day}`,\n      minutes: 15 + (next() % 90),\n      done: false,\n    });\n  }\n  return out;\n}\n\n// By date, then by length; returns how long the sort took, in ms\nfunction sortSessions(list: Session[]): number {\n  const t0 = performance.now();\n  list.sort((a, b) => (a.date < b.date ? -1 : a.date > b.date ? 1 : a.minutes - b.minutes));\n  return performance.now() - t0;\n}\n", "note": "Os dados são um mês de sessões inventadas. Os números vêm de uma semente fixa em vez de `Math.random`, então toda execução ordena a mesma lista. A ordenação é a visão da semana do planner em miniatura, e `performance.now()` mede o tempo dela em frações de milissegundo."}, {"code": "if (!isMainThread) {\n  // In the worker: make the same data, say ready, sort on \"go\", send the time back\n  const list = makeSessions(N);\n  parentPort!.postMessage(\"ready\");\n  parentPort!.once(\"message\", () => parentPort!.postMessage(sortSessions(list)));\n}\n", "note": "Esta parte roda só dentro do worker. O mesmo arquivo é carregado uma segunda vez em outra thread, onde `isMainThread` é falso. O worker cria a própria cópia dos dados, então nada grande precisa atravessar, e devolve um número só."}, {"code": "// The frame clock: one slot every 16.67 ms, counted from `start`\nconst period = 1000 / 60;\nlet start = 0, last = -1, drawn = 0, dropped = 0, longest = 0, prev = 0, running = true;\n\nfunction frame() {\n  const now = performance.now();\n  const k = Math.floor((now - start) / period); // the slot we are in\n  if (k > last) {\n    dropped += k - last - 1; // slots that passed with no frame\n    drawn += 1;\n    if (last >= 0) longest = Math.max(longest, now - prev);\n    last = k;\n    prev = now;\n  }\n  if (running) setTimeout(frame, start + (k + 1) * period - now);\n}\n", "note": "O relógio faz o papel da tela. Ele pede para rodar no começo de cada espaço de 16,67 ms e, quando roda, calcula em que espaço está. Todo espaço que ele pulou é um quadro perdido, a regra da seção sobre o orçamento: um quadro que perde o seu espaço não sai atrasado, não sai. `longest` guarda a maior distância entre dois quadros."}, {"code": "// Start the clock, run the work 200 ms in, stop 200 ms after it ends, print\nfunction measure(work: (done: (sortMs?: number) => void) => void) {\n  start = prev = performance.now();\n  frame();\n  setTimeout(() => work((sortMs) => setTimeout(() => {\n    running = false;\n    console.log(`${mode}: ${N} sessions, a frame due every ${period.toFixed(2)} ms`);\n    if (sortMs !== undefined) console.log(`  sort took      ${sortMs.toFixed(0)} ms`);\n    console.log(`  frames drawn   ${drawn}`);\n    console.log(`  frames dropped ${dropped}`);\n    console.log(`  longest gap    ${longest.toFixed(1)} ms`);\n  }, 200)), 200);\n}\n", "note": "Toda execução tem o mesmo formato: 200 ms de calma, o trabalho, mais 200 ms de calma, e então as contagens."}, {"code": "if (isMainThread && mode === \"idle\") measure((done) => done());\n\nif (isMainThread && mode === \"main\") {\n  const list = makeSessions(N); // made before the clock starts\n  measure((done) => done(sortSessions(list)));\n}\n\nif (isMainThread && mode === \"worker\") {\n  const w = new Worker(new URL(import.meta.url), { argv: [mode, String(N)] });\n  w.once(\"message\", () =>\n    measure((done) => {\n      w.postMessage(\"go\");\n      w.once(\"message\", (ms: number) => {\n        done(ms);\n        w.terminate();\n      });\n    }),\n  );\n}", "note": "As três execuções. `idle` não faz trabalho nenhum, então mostra o que o relógio faz sozinho. `main` ordena na thread que roda o relógio. `worker` inicia um `Worker` a partir deste mesmo arquivo, espera que ele fique pronto, dá a partida e continua rodando o relógio enquanto o worker ordena."}]}
```

Rode de três jeitos. `node frames.ts idle` roda só o relógio, `main` ordena na thread do relógio e
`worker` ordena num worker.

## Três execuções

Primeiro o relógio sozinho, sem trabalho nenhum, para ver o que ele faz numa máquina tranquila:

```
ana@dev:~/planner$ node frames.ts idle
idle: 300000 sessions, a frame due every 16.67 ms
  frames drawn   24
  frames dropped 0
  longest gap    17.8 ms
```

**24 quadros desenhados e nenhum perdido**: 400 ms de calma são 24 espaços de 16,67 ms. A maior
distância entre dois quadros foi de 17,8 ms, e não exatamente 16,67, porque um timer dispara quando
o laço de eventos chega até ele e nunca exatamente na hora; essa oscilação fica dentro de um
espaço, então nenhum quadro se perde.

Agora a ordenação na mesma thread do relógio:

```
ana@dev:~/planner$ node frames.ts main
main: 300000 sessions, a frame due every 16.67 ms
  sort took      554 ms
  frames drawn   25
  frames dropped 33
  longest gap    570.4 ms
```

**A ordenação levou 554 ms, e durante todo esse tempo o relógio não pôde rodar.** 33 quadros se
perderam, e a maior distância entre dois quadros foi de 570,4 ms: mais de meio segundo em que um
app de verdade não teria desenhado nada nem respondido a nenhum toque. Pelos nomes do Android isso é
um quadro muito lento, abaixo dos 700 ms que o tornariam congelado, e uma rolagem começada nesse
meio segundo teria esperado por ele inteiro.

A mesma ordenação, num worker:

```
ana@dev:~/planner$ node frames.ts worker
worker: 300000 sessions, a frame due every 16.67 ms
  sort took      470 ms
  frames drawn   53
  frames dropped 0
  longest gap    21.9 ms
```

**Nenhum quadro perdido.** O relógio desenhou 53 quadros, um em cada espaço, e a maior distância
foi de 21,9 ms, ainda dentro do espaço seguinte. A ordenação levou 470 ms no worker, o que não é
mais rápido de nenhum jeito que importe: o trabalho é o mesmo, e foi feito. Foi feito em outra
thread, e essa é toda a diferença.

## O que os números são, e o que não são

**Eles são uma execução numa máquina**, com quatro núcleos de processador, capturada uma vez para
esta aula. Rode você mesmo e todo número, menos o da primeira linha, vai sair diferente, de uma
execução para outra e de uma máquina para outra; a ordenação pode levar o dobro num notebook mais
lento, ou menos num mais rápido. O que não muda é o formato: algumas centenas de milissegundos de
ordenação na thread do relógio custam algumas dezenas de quadros, e a mesma ordenação num worker
não custa nenhum.

**E o Node.js é um modelo de celular, não um celular.** A thread principal de um celular também
posiciona e desenha, o sistema decide quanto tempo de processador o app recebe, e um celular
quente ou com pouca bateria roda mais devagar. Duas coisas valem exatamente, e são o motivo de o
modelo valer a pena: o relógio de um laço de uma thread só não bate enquanto uma função ainda está
rodando, e o trabalho levado para outra thread deixa esse laço livre. O worker do `frames.ts` cria
a própria cópia dos dados e devolve um número. Um app de verdade precisa devolver a própria lista
ordenada, e copiar um resultado grande entre duas threads leva tempo nas duas, então vale medir
essa cópia também em vez de supor que ela é de graça.
