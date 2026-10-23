---
title: Quando a preparação falha
version: 1
---

**Cada falha abaixo foi provocada de propósito na máquina onde este curso foi gravado, e cada mensagem
diz o que está errado quando você sabe onde olhar.** Elas estão na ordem em que você as encontraria:
construir, servir e depois olhar a página. Leia a seção uma vez agora e volte a ela quando algo não
funcionar.

## O build para com `error TS`

```
ana@dev:~/planner$ npm run build

> planner@0.0.0 build
> tsc && vite build

src/planner.ts(11,32): error TS2322: Type 'Session | { id: number; course: string; date: string; minutes: number; done: false; }' is not assignable to type 'Session'.
  Type '{ id: number; course: string; date: string; minutes: number; done: false; }' is not assignable to type 'Session'.
    Types of property 'id' are incompatible.
      Type 'number' is not assignable to type 'string'.
src/planner.ts(11,52): error TS2322: Type 'string | number' is not assignable to type 'string'.
  Type 'number' is not assignable to type 'string'.
```

**O TypeScript recusou o código antes que o Vite construísse qualquer coisa**, que é para isso que
serve o `tsc &&` na frente do `vite build`. A primeira linha nomeia o arquivo, a linha e a coluna,
`src/planner.ts(11,32)`, e o resto diz por quê: o `id` de uma sessão tem que ser `string` e o código
deu a ele um número. Aqui uma linha de `src/planner.ts` foi trocada por
`const id = plan.sessions.length + 1;` para mostrar a mensagem. Se você copiou os arquivos e vê isto,
compare a linha que ela nomeia com a da aula; um par de crases faltando é a causa de sempre.

Um build que falha deixa a `dist/` anterior onde estava, então uma aula seguinte que copia a `dist/`
copia um app antigo sem avisar. **Rode `npm run build` de novo depois de cada mudança, e leia a última
linha.**

## `Port 5173 is in use`

```
ana@dev:~/planner$ timeout 5 npm run dev 2>&1 | head -n 6

> planner@0.0.0 dev
> vite

Port 5173 is in use, trying another one...
7:40:17 PM [vite] (client) Re-optimizing dependencies because lockfile has changed
```

`npm run dev` já estava rodando em outro terminal, segurando a porta 5173, então o segundo passou para a
porta seguinte, e disse isso. O `timeout 5` o parou depois de cinco segundos, e o `head -n 6`
guardou as linhas que importam aqui. **Nada está quebrado**, mas as transcrições deste curso abrem a 5173, e
essa ainda é o primeiro servidor. Feche o segundo com `q` e Enter, ou ache o terminal onde o primeiro
está rodando e use aquele.

## `net::ERR_CONNECTION_REFUSED`

```
ana@dev:~/planner$ node look.mjs 'http://localhost:5173/?today=2026-10-21' 2>&1 | head -n 8
node:internal/modules/run_main:123
    triggerUncaughtException(
    ^

page.goto: net::ERR_CONNECTION_REFUSED at http://localhost:5173/?today=2026-10-21
Call log:
  - navigating to "http://localhost:5173/?today=2026-10-21", waiting until "load"
```

**Nada estava escutando no endereço que o `look.mjs` abriu.** O servidor de desenvolvimento não está
rodando, ou está rodando em outra porta, como na falha acima. Inicie `npm run dev` num terminal só
dele, confira o endereço que ele imprime e abra esse.

## `Executable doesn't exist`

```
ana@dev:~/planner$ node look.mjs 'http://localhost:5173/?today=2026-10-21' 2>&1 | head -n 5
node:internal/modules/run_main:123
    triggerUncaughtException(
    ^

browserType.launch: Executable doesn't exist at /home/ana/.cache/ms-playwright/chromium_headless_shell-1243/chrome-headless-shell-linux64/chrome-headless-shell
```

O `npm install` buscou a biblioteca do Playwright e não o navegador que ela controla. A linha comprida
é o caminho onde o Playwright procurou um; embaixo dela, cortada aqui, o Playwright desenha uma caixa
sugerindo um comando. **Rode `npx playwright install chromium` dentro de `~/planner`**, que baixa o
build que esta versão do Playwright espera. Uma versão diferente do Playwright espera um build
diferente, e é por isso que ela está fixada com `-E`.

## Quando é outra coisa

Leia a primeira linha que diz `error` ou `Error`, não a última; a última muitas vezes resume a
primeira. Pesquise essa linha entre aspas. E confira as duas coisas que causam a maioria das falhas
neste curso: **`node --version` diz `v22`**, e **você está na pasta onde acha que está**, o que `pwd`
responde.
