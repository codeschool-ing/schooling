---
title: A lógica viaja, a tela não
version: 1
---

**O núcleo do planner da aula 1 é TypeScript puro, sem tela nenhuma, e é exatamente por isso que ele
pode ir a qualquer lugar onde JavaScript roda.** Um app React Native, um app Capacitor, uma página
web e um terminal podem todos importar `planner.ts` sem mudança. Uma tela não viaja do mesmo jeito,
porque uma tela é escrita contra uma coisa que desenha, e essa coisa não está em todo lugar. Dá para
ver as duas metades dessa frase no seu próprio computador.

## O núcleo, sem mudança

Em `~/planner`, rode de novo o `week.ts` da aula 1. Nada nele nem em `planner.ts` mudou:

```
ana@dev:~/planner$ node week.ts
{ monday: '2026-10-19', planned: 180, done: 120 }
```

**Os mesmos números, numa máquina que não tem celular nem navegador.** O Node.js é mais um hospedeiro
para o núcleo, ao lado do motor JavaScript do celular num app React Native e da WebView num
embrulho.

## Uma tela escrita para o navegador

Agora escreva a linha da semana do jeito que uma página web a desenharia, com o DOM: criar um
parágrafo, pôr o texto nele, acrescentá-lo à página. Salve como `screen-web.ts`:

```typescript
// screen-web.ts: the week's line, drawn with the browser's DOM
import { weekTotal, type Plan } from "./planner.ts";

export function drawWeek(plan: Plan, today: string) {
  const t = weekTotal(plan, today);
  const line = document.createElement("p");
  line.textContent = `${t.done} of ${t.planned} minutes done`;
  document.body.append(line);
}

drawWeek({ courses: [], sessions: [] }, "2026-10-21");
```

Rode:

```
ana@dev:~/planner$ node screen-web.ts
file:///home/ana/planner/screen-web.ts:6
  const line = document.createElement("p");
               ^

ReferenceError: document is not defined
    at drawWeek (file:///home/ana/planner/screen-web.ts:6:16)
    at file:///home/ana/planner/screen-web.ts:11:1
    at ModuleJob.run (node:internal/modules/esm/module_job:343:25)
    at async onImport.tracePromise.__proto__ (node:internal/modules/esm/loader:665:26)
    at async asyncRunEntryPointWithESMLoader (node:internal/modules/run_main:117:5)

Node.js v22.22.0
```

**Leia onde ele parou.** O `import` da linha 2 funcionou, e o `weekTotal` também: o erro aponta a
linha 6, coluna 16, o primeiro uso de `document`. `document` é a página, e só existe onde um motor de
navegador criou uma. O Node.js não tem página, e nem um app React Native, cuja tela são as views da
plataforma, nem um app Flutter, cuja tela é a superfície do próprio motor. Este arquivo roda num
navegador e na WebView de um embrulho, e em nenhum outro lugar.

## A mesma linha, para uma tela que existe aqui

A correção não é levar o navegador junto. É escrever a tela de novo para o que desenha naquele lugar,
e continuar chamando o mesmo núcleo. Num terminal, uma tela são linhas de texto. Salve isto como
`screen-term.ts`:

```typescript
// screen-term.ts: the same line and button, drawn as text in a terminal
import { markDone, weekTotal, type Plan } from "./planner.ts";

function draw(plan: Plan, today: string) {
  const t = weekTotal(plan, today);
  console.log(`Week of ${t.monday}: ${t.done} of ${t.planned} minutes done   [ Mark done ]`);
}

let plan: Plan = {
  courses: [{ id: "sql", title: "SQL Databases" }],
  sessions: [
    { id: "s1", courseId: "sql", date: "2026-10-19", minutes: 50, done: true },
    { id: "s3", courseId: "sql", date: "2026-10-23", minutes: 60, done: false },
  ],
};

draw(plan, "2026-10-21");
plan = markDone(plan, "s3"); // what pressing the button does
draw(plan, "2026-10-21");
```

```
ana@dev:~/planner$ node screen-term.ts
Week of 2026-10-19: 50 of 110 minutes done   [ Mark done ]
Week of 2026-10-19: 110 of 110 minutes done   [ Mark done ]
```

Antes do toque, só `s1` está concluída: 50 dos 110 minutos planejados para aquela semana. Depois do
`markDone`, os 60 minutos de `s3` se juntam a eles, e a linha mostra 110 de 110. As somas vieram do
mesmo `weekTotal` que a tela do navegador chamou um momento antes.

**Duas telas, um núcleo, e só a tela foi escrita duas vezes.** Essa é a troca que toda abordagem desta
aula faz em algum ponto. O React Native escreve a tela uma vez contra os componentes dele e deixa a
plataforma desenhá-la. Uma equipe nativa a escreve duas vezes, em Compose e em SwiftUI. O núcleo vai
com a linguagem que o app roda: como está, para o React Native ou um embrulho; reescrito em Kotlin e
em Swift, para dois apps nativos; ou escrito uma vez em Kotlin, para o Kotlin Multiplatform levar aos
dois.

Apague a tela de navegador, que não tem hospedeiro neste computador, e fique com a do terminal:

```
ana@dev:~/planner$ rm screen-web.ts
ana@dev:~/planner$ git add screen-term.ts
ana@dev:~/planner$ git commit -q -m "A terminal screen over the same core"
ana@dev:~/planner$ git log --oneline
4027da0 A terminal screen over the same core
87ae50d The planner core, as lesson 1 gives it
```
