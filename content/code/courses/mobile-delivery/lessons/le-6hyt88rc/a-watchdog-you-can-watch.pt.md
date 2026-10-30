---
title: Um watchdog que você consegue ver
version: 1
---

**Um travamento só pode ser percebido de fora da thread que travou.** Os detectores de travamento do
Sentry, do Crashlytics e das bibliotecas Android que relatam ANRs funcionam todos do mesmo jeito: a
thread principal atualiza um **batimento**, um horário, várias vezes por segundo, e uma segunda
thread o confere. Quando o batimento para de mudar por mais tempo que um limite, a segunda thread
registra o que consegue, enquanto a principal ainda está presa.

O Node também tem uma thread principal, e threads de trabalho ao lado, então o mesmo arranjo roda
aqui. Salve isto como `hang.ts` em `~/planner`:

```schooling-example
{"language": "typescript", "file": "hang.ts", "parts": [{"code": "// hang.ts: a main thread that stops answering, and a watchdog thread that notices\nimport { Worker, isMainThread, workerData } from \"node:worker_threads\";\nimport { writeFileSync, writeSync } from \"node:fs\";\n\nconst LIMIT_MS = 5000;", "note": "Um arquivo roda como as duas threads: o `isMainThread` diz qual ele é. O limite são os cinco segundos do Android para um evento de entrada."}, {"code": "if (isMainThread) {\n  const beat = new Int32Array(new SharedArrayBuffer(8));\n  const started = Date.now();\n  const tick = () => Atomics.store(beat, 0, Date.now() - started);\n  const watchdog = new Worker(new URL(import.meta.url), { workerData: { beat, started } });\n  setInterval(tick, 100).unref();\n  tick();", "note": "O batimento é um número numa memória que as duas threads compartilham. A thread principal o reescreve a cada 100 ms, mas só quando está livre para rodar um timer."}, {"code": "  const mode = process.argv[2] ?? \"blocking\";\n  console.log(`open the week (${mode})`);\n  setTimeout(async () => {\n    if (mode === \"blocking\") {\n      const until = Date.now() + 6000;\n      while (Date.now() < until) {} // stands in for parsing a year of sessions on the main thread\n    } else {\n      await new Promise((done) => setTimeout(done, 6000)); // the same wait, with the main thread free\n    }\n    console.log(`week ready after ${Math.round((Date.now() - started) / 1000)} s`);\n    watchdog.terminate();\n  }, 200);", "note": "Seis segundos de trabalho, feitos de dois jeitos: um laço que prende a thread principal, ou uma espera que a deixa livre."}, {"code": "} else {\n  const { beat, started } = workerData as { beat: Int32Array; started: number };\n  let reported = false;\n  setInterval(() => {\n    const silent = Date.now() - started - Atomics.load(beat, 0);\n    if (silent >= LIMIT_MS && !reported) {\n      reported = true;\n      writeFileSync(\"hang-report.txt\", `main thread silent for ${silent} ms\\n`);\n      writeSync(1, `watchdog: main thread silent for ${Math.floor(silent / 1000)} s, hang report written\\n`);\n    }\n  }, 250);\n}", "note": "A thread vigia lê o batimento quatro vezes por segundo. Passado o limite ela grava um relatório, e imprime direto no terminal, sem pedir nada à thread principal."}]}
```

Rode do jeito que bloqueia, depois do outro jeito:

```
ana@dev:~/planner$ node hang.ts blocking
open the week (blocking)
watchdog: main thread silent for 5 s, hang report written
week ready after 6 s
ana@dev:~/planner$ node hang.ts free
open the week (free)
week ready after 6 s
ana@dev:~/planner$ cat hang-report.txt
main thread silent for 5108 ms
```

## O que a transcrição mostra

**Na execução que bloqueia, a linha do watchdog aparece antes de a semana ficar pronta**, enquanto a
thread principal ainda está presa no laço dela. Esse é todo o sentido de uma segunda thread: a
principal não conseguiria relatar nada até ficar livre, e a essa altura, num celular, o sistema
talvez já a tivesse matado.

O watchdog escreve a linha dele com `writeSync` direto no terminal, e não com `console.log`, e esse
detalhe é a lição em miniatura. Numa worker, o `console.log` entrega o texto à thread principal para
imprimir, e a thread principal é a que está presa; a mensagem chegaria depois do travamento que ela
descreve. **Um detector de travamento não pode pedir ajuda nenhuma à thread travada.**

Na segunda execução, os mesmos seis segundos são gastos esperando um timer, que faz o papel de
trabalho feito em outra thread, e o batimento nunca para. Nenhum relatório: o app foi lento, e nunca
travou.

## O limite é uma escolha

O script relata aos 5 segundos, o limite do Android para um evento de entrada. Detectores de verdade
relatam antes, muitas vezes aos 2 segundos, porque um travamento de dois segundos já é um que a
pessoa percebe, e um relatório de ANR aos cinco só chega para os travamentos que duraram o bastante
para o sistema contar. O Sentry chama os mais curtos de **app hangs**, e os relata à parte dos ANRs.
