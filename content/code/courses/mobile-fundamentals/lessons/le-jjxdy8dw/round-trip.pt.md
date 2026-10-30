---
title: Uma ida e volta pela morte do processo, no seu computador
version: 1
---

**Um programa consegue encenar as duas metades da ida e volta: salvar o estado de UI da tela, ser
morto sem aviso, e na execução seguinte ler o estado de volta e desenhar a mesma tela.** Num
celular, quem mata é o sistema. Aqui o programa faz isso consigo mesmo, com o único sinal que nenhum
processo consegue capturar, para que sobreviva só o que foi anotado antes.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" data-fig=\"l05-round-trip\" aria-label=\"Uma ida e volta pela morte do processo. Processo 1, node restore.ts use: Ana abre um curso, rola e digita 45; na saída o programa grava o estado de UI. Então a morte: SIGKILL, e nada mais roda. O estado de UI está em saved-state.json: id do curso, posição de rolagem e rascunho. Processo 2, node restore.ts open, começa do nada, como um app no onCreate, lê o estado salvo e desenha a mesma tela.\"><defs><marker id=\"l05-round-trip-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"40\" width=\"290\" height=\"78\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"165.0\" y=\"66.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">processo 1: restore.ts use</text><text x=\"165.0\" y=\"79.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Ana abre um curso, rola, digita \"45\"</text><text x=\"165.0\" y=\"91.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">na saída: grava o estado de UI</text><rect x=\"410\" y=\"40\" width=\"290\" height=\"78\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"555.0\" y=\"66.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">processo 2: restore.ts open</text><text x=\"555.0\" y=\"79.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">começa do nada, como no onCreate</text><text x=\"555.0\" y=\"91.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">lê o estado de UI, desenha a tela</text><path d=\"M360 32 L360 140\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" stroke-dasharray=\"5 4\"></path><text x=\"360\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--amber)\">a morte: SIGKILL, e nada mais roda</text><rect x=\"250\" y=\"166\" width=\"220\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"181.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">saved-state.json</text><text x=\"360.0\" y=\"194.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">id do curso · rolagem · rascunho</text><path d=\"M165 118 L165 188 L248 188\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l05-round-trip-ah-paper-dim)\"></path><path d=\"M472 188 L555 188 L555 120\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l05-round-trip-ah-paper-dim)\"></path></svg>", "caption": "O que atravessa a morte é o que foi gravado antes dela. O processo, a memória dele e o handler de saída não atravessam.", "same": ["saved-state.json"]}
```

## restore.ts

Ele tem três modos: `use` encena Ana usando o app até o sistema matá-lo, `open` é o lançamento
seguinte, e `sizes` é para a próxima etapa. Salve em `~/planner` como `restore.ts`:

```schooling-example
{"language": "typescript", "file": "restore.ts", "parts": [{"code": "// restore.ts: the screen's state, saved on the way out and put back after a kill\nimport { existsSync, readFileSync, writeFileSync } from \"node:fs\";\nimport { weekTotal, type Plan, type Session } from \"./planner.ts\";\n\n// The data. In the app it lives in a database on the device (lesson 16).\nconst plan: Plan = {\n  courses: [\n    { id: \"sql\", title: \"SQL Databases\" },\n    { id: \"mobile\", title: \"Mobile Fundamentals\" },\n  ],\n  sessions: [\n    { id: \"s1\", courseId: \"sql\", date: \"2026-10-19\", minutes: 50, done: true },\n    { id: \"s2\", courseId: \"mobile\", date: \"2026-10-20\", minutes: 40, done: true },\n    { id: \"s3\", courseId: \"sql\", date: \"2026-10-23\", minutes: 60, done: false },\n    { id: \"s5\", courseId: \"mobile\", date: \"2026-10-22\", minutes: 30, done: false },\n  ],\n};\n", "note": "Os dados, como uma constante no lugar do banco. Eles sobrevivem à morte porque nunca estiveram só na memória, então nada aqui os salva."}, {"code": "// The UI state: where the user was and what they had half typed. Ids, not objects.\ntype UiState = {\n  courseId: string;\n  scrollY: number;\n  draft: { date: string; minutes: string } | null;\n};\nconst FILE = \"saved-state.json\";\nconst TODAY = \"2026-10-21\";\n\nfunction draw(ui: UiState) {\n  const course = plan.courses.find((c) => c.id === ui.courseId);\n  if (!course) throw new Error(`saved state names a course that does not exist: ${ui.courseId}`);\n  const own = { ...plan, sessions: plan.sessions.filter((s) => s.courseId === course.id) };\n  const t = weekTotal(own, TODAY);\n  console.log(`  ${course.title}, week of ${t.monday}: ${t.done} of ${t.planned} minutes done`);\n  console.log(`  scrolled to ${ui.scrollY} px`);\n  console.log(ui.draft ? `  new session, not saved yet: ${ui.draft.date}, \"${ui.draft.minutes}\" minutes` : \"  no session being written\");\n}\n", "note": "O estado de UI nomeia o curso pelo id e guarda os minutos digitados como string. `draw` é a tela: procura o curso nos dados e calcula de novo os números da semana em vez de confiar numa cópia salva."}, {"code": "const mode = process.argv[2] ?? \"open\";\n\nif (mode === \"use\") {\n  // Ana opens a course, scrolls, starts typing a session...\n  const ui: UiState = { courseId: \"mobile\", scrollY: 640, draft: { date: \"2026-10-22\", minutes: \"45\" } };\n  console.log(\"on screen:\");\n  draw(ui);\n  process.on(\"exit\", () => console.log(\"goodbye\")); // never printed\n  // ...the app goes to the background, and saves while it is still being told things.\n  const text = JSON.stringify(ui);\n  writeFileSync(FILE, text);\n  console.log(`saved ${Buffer.byteLength(text)} bytes to ${FILE}`);\n  // The system kills the suspended process: no callback, no exit handler.\n  process.kill(process.pid, \"SIGKILL\");\n", "note": "`use` desenha a tela, salva o estado de UI na saída e depois mata o próprio processo com `SIGKILL`, o sinal que nenhum handler consegue capturar. O handler de `exit` está ali para mostrar que ele não roda."}, {"code": "} else if (mode === \"open\") {\n  if (existsSync(FILE)) {\n    console.log(`restored from ${FILE}:`);\n    draw(JSON.parse(readFileSync(FILE, \"utf8\")) as UiState);\n  } else {\n    console.log(\"nothing saved, a fresh start:\");\n    draw({ courseId: plan.courses[0].id, scrollY: 0, draft: null });\n  }\n", "note": "`open` é o próximo lançamento: um processo novo que não sabe nada, lê o estado salvo se houver, e senão abre na tela padrão."}, {"code": "} else if (mode === \"sizes\") {\n  // The same screen, saved two ways, for a plan of 2,000 sessions.\n  const sessions: Session[] = [];\n  for (let i = 1; i <= 2000; i++) {\n    const day = String(1 + (i % 28)).padStart(2, \"0\");\n    sessions.push({ id: `s${i}`, courseId: i % 2 ? \"sql\" : \"mobile\", date: `2026-11-${day}`, minutes: 30 + (i % 4) * 15, done: i % 3 === 0 });\n  }\n  const big = { ...plan, sessions };\n  const ui: UiState = { courseId: \"mobile\", scrollY: 640, draft: { date: \"2026-10-22\", minutes: \"45\" } };\n  const ids = Buffer.byteLength(JSON.stringify(ui));\n  const whole = Buffer.byteLength(JSON.stringify({ ...ui, course: big.courses[1], plan: big }));\n  console.log(`ids only:       ${ids} bytes`);\n  console.log(`the whole plan: ${whole} bytes, ${(whole / 1024).toFixed(1)} KiB, ${Math.round(whole / ids)} times as much`);\n} else {\n  console.error(`unknown mode \"${mode}\": use, open or sizes`);\n  process.exit(1);\n}", "note": "`sizes` monta um plano de 2.000 sessões geradas e mede a mesma tela salva de dois jeitos: por ids, e com o curso e o plano inteiro dentro. Qualquer outro modo é recusado pelo nome."}]}
```

## Primeiro lançamento, sem nada salvo

```
ana@dev:~/planner$ node restore.ts open
nothing saved, a fresh start:
  SQL Databases, week of 2026-10-19: 50 of 110 minutes done
  scrolled to 0 px
  no session being written
```

**Sem estado salvo o app abre no padrão**, o primeiro curso, no topo, sem formulário aberto. Esse é o
primeiro lançamento correto, e é também o que o usuário veria depois de uma morte se o app não
tivesse salvado nada: o plano continua lá, porque é dado, e tudo sobre onde ele estava se perdeu.

## Usando, e sendo morto

```
ana@dev:~/planner$ node restore.ts use; echo "exit status $?"
on screen:
  Mobile Fundamentals, week of 2026-10-19: 40 of 70 minutes done
  scrolled to 640 px
  new session, not saved yet: 2026-10-22, "45" minutes
saved 80 bytes to saved-state.json
bash: line 1:     5 Killed                  node restore.ts use
exit status 137
```

**Leia as duas últimas linhas juntas.** O estado foi gravado enquanto o programa ainda rodava, o
equivalente de `onStop` ou `.background`. Então o processo recebeu `SIGKILL`, o sinal que encerra um
processo sem rodar mais nada do código dele, e o shell informou: `Killed`, e um status de saída 137,
que é 128 mais o número do sinal, 9. O handler de `exit` registrado algumas linhas antes nunca
imprimiu o `goodbye`, porque nada roda num processo morto, que é a regra da aula 4 vista por dentro.

O que foi gravado é pequeno o bastante para ler inteiro:

```
ana@dev:~/planner$ cat saved-state.json; echo
{"courseId":"mobile","scrollY":640,"draft":{"date":"2026-10-22","minutes":"45"}}
```

## O lançamento seguinte

```
ana@dev:~/planner$ node restore.ts open
restored from saved-state.json:
  Mobile Fundamentals, week of 2026-10-19: 40 of 70 minutes done
  scrolled to 640 px
  new session, not saved yet: 2026-10-22, "45" minutes
```

**A mesma tela, de um processo novo.** O curso, a posição de rolagem e o "45" meio digitado voltaram,
e os números da semana nem foram salvos: foram calculados de novo a partir do plano, porque derivam
dos dados e uma cópia salva poderia ter ficado velha. O estado salvo nomeou o curso pelo id,
`mobile`, e o título veio dos dados, então um curso renomeado enquanto o app estava morto voltaria
com o nome novo.

**Este é o caminho de restauração que uma rotação não prova.** O modelo da aula 4 disse que um app
morto só pode ser lançado de novo; este é esse lançamento, com a única coisa que o faz parecer uma
volta.

Faça o commit do arquivo, e deixe o estado salvo fora do repositório, já que ele pertence a uma
execução e não ao programa:

```
ana@dev:~/planner$ echo saved-state.json >> .gitignore
ana@dev:~/planner$ git add .gitignore restore.ts
ana@dev:~/planner$ git commit -q -m "Saved UI state, restored after a kill"
ana@dev:~/planner$ git status --short
```
