"""Lesson 14: hang.ts."""
P = [
    ("// hang.ts: a main thread that stops answering, and a watchdog thread that notices\nimport { Worker, isMainThread, workerData } from \"node:worker_threads\";\nimport { writeFileSync, writeSync } from \"node:fs\";\n\nconst LIMIT_MS = 5000;",
     "One file runs as both threads: `isMainThread` says which one it is. The limit is Android's five seconds for an input event.",
     "Um arquivo roda como as duas threads: o `isMainThread` diz qual ele é. O limite são os cinco segundos do Android para um evento de entrada."),
    ("if (isMainThread) {\n  const beat = new Int32Array(new SharedArrayBuffer(8));\n  const started = Date.now();\n  const tick = () => Atomics.store(beat, 0, Date.now() - started);\n  const watchdog = new Worker(new URL(import.meta.url), { workerData: { beat, started } });\n  setInterval(tick, 100).unref();\n  tick();",
     "The heartbeat is a number in memory both threads share. The main thread rewrites it every 100 ms, but only when it is free to run a timer.",
     "O batimento é um número numa memória que as duas threads compartilham. A thread principal o reescreve a cada 100 ms, mas só quando está livre para rodar um timer."),
    ("  const mode = process.argv[2] ?? \"blocking\";\n  console.log(`open the week (${mode})`);\n  setTimeout(async () => {\n    if (mode === \"blocking\") {\n      const until = Date.now() + 6000;\n      while (Date.now() < until) {} // stands in for parsing a year of sessions on the main thread\n    } else {\n      await new Promise((done) => setTimeout(done, 6000)); // the same wait, with the main thread free\n    }\n    console.log(`week ready after ${Math.round((Date.now() - started) / 1000)} s`);\n    watchdog.terminate();\n  }, 200);",
     "Six seconds of work, done two ways: a loop that holds the main thread, or a wait that leaves it free.",
     "Seis segundos de trabalho, feitos de dois jeitos: um laço que prende a thread principal, ou uma espera que a deixa livre."),
    ("} else {\n  const { beat, started } = workerData as { beat: Int32Array; started: number };\n  let reported = false;\n  setInterval(() => {\n    const silent = Date.now() - started - Atomics.load(beat, 0);\n    if (silent >= LIMIT_MS && !reported) {\n      reported = true;\n      writeFileSync(\"hang-report.txt\", `main thread silent for ${silent} ms\\n`);\n      writeSync(1, `watchdog: main thread silent for ${Math.floor(silent / 1000)} s, hang report written\\n`);\n    }\n  }, 250);\n}",
     "The watchdog thread reads the heartbeat four times a second. Past the limit it writes a report, and prints straight to the terminal, without asking the main thread.",
     "A thread vigia lê o batimento quatro vezes por segundo. Passado o limite ela grava um relatório, e imprime direto no terminal, sem pedir nada à thread principal."),
]
EXAMPLES = {"a-watchdog-you-can-watch": [{"language": "typescript", "file": "hang.ts", "parts": P}]}
