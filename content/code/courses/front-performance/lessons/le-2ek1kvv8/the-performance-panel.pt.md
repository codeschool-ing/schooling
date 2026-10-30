---
title: O painel de desempenho
version: 1
---

**O Lighthouse diz que a thread principal estava ocupada; o painel de desempenho a mostra ocupada.**
Ele grava tudo o que o navegador fez enquanto você usava uma página, as requisições de rede, os quadros
e cada tarefa da thread principal com o que rodou dentro dela, e desenha tudo ao longo do tempo.

## Gravando no navegador

No Chrome, ou em qualquer navegador feito sobre o Chromium, abra as ferramentas de desenvolvedor e a aba
**Performance**:

- **o botão de gravar** começa uma gravação; use a página como uma pessoa usaria e depois pare;
- **gravar e recarregar** recarrega a página e grava a carga dela, que é o que o Lighthouse mede;
- **as configurações** do painel, a engrenagem na barra dele, deixam o processador e a rede mais lentos,
  como o `--cpu` e o `--slow` fizeram neste curso.

O que ele desenha, de cima para baixo:

- **Network**: cada requisição como uma barra ao longo do tempo, que é a cascata da seção "Cascatas";
- **Frames**: cada quadro que o navegador pintou, e os buracos onde não pintou nenhum;
- **Main**: as tarefas da thread principal, com o que cada uma chamou empilhado embaixo dela, o gráfico
  chamado **flame chart**. Uma tarefa de 50 milissegundos ou mais é uma **tarefa longa** e é desenhada
  com um canto vermelho.

Clique em qualquer bloco e o painel de baixo diz o que ele foi: um script, um cálculo de estilo, um
layout, uma pintura, e quanto tempo levou. O painel também lista **insights** ao lado da gravação, os
mesmos que o Lighthouse aponta, porque desde a versão 13 o Lighthouse e o painel os compartilham.

## A mesma gravação, feita por um programa

**Uma gravação é um arquivo**, um *trace*, e o painel abre um: o botão Load profile na barra dele, uma
seta para cima. Então um trace pode ser gravado por um programa, em condições que ele repete
exatamente, e aberto por uma pessoa. O Playwright grava traces no mesmo formato.

O `tools/trace.ts` grava um enquanto carrega uma página e, se pedido, clica em algo, como o
`tools/vitals.ts` faz. Ele salva o `trace.json` para o painel, e depois lê o arquivo ele mesmo e lista as
tarefas longas da thread principal da página, com as maiores coisas dentro de cada uma. Salve-o em
`tools/`:

```schooling-example
{"language": "typescript", "file": "tools/trace.ts", "parts": [
 {"code": "// tools/trace.ts: record what the browser's main thread did while a page loaded\n// and was clicked, save it for the performance panel, and list the long tasks.\n//\n//   node tools/trace.ts URL [--cpu N] [--click SELECTOR]\n//\n// trace.json is the file the panel opens with its Load profile button.\nimport { chromium } from \"playwright\";\nimport { readFile } from \"node:fs/promises\";\n\nconst [url, ...rest] = process.argv.slice(2);\nconst option = (name: string) => (rest.includes(name) ? rest[rest.indexOf(name) + 1] : null);\nconst browser = await chromium.launch();\nconst page = await browser.newPage();\nconst cdp = await page.context().newCDPSession(page);\nif (option(\"--cpu\")) await cdp.send(\"Emulation.setCPUThrottlingRate\", { rate: Number(option(\"--cpu\")) });", "note": "Para que serve e como rodar. O arquivo que ele salva é o que o painel abre."},
 {"code": "await browser.startTracing(page, { path: \"trace.json\", screenshots: true });\nawait page.goto(url, { waitUntil: \"networkidle\" });\nawait page.waitForTimeout(500);\nif (option(\"--click\")) {\n  await page.click(option(\"--click\")!);\n  await page.waitForTimeout(500);\n}\nawait browser.stopTracing();\nawait browser.close();", "note": "O startTracing e o stopTracing delimitam a gravação. O screenshots acrescenta a tira de filme que o painel mostra acima das trilhas."},
 {"code": "type Event = { name: string; ph: string; ts: number; dur?: number; pid: number; tid: number; args?: any };\nconst events: Event[] = JSON.parse(await readFile(\"trace.json\", \"utf8\")).traceEvents;\nconst main = events.find((e) => e.name === \"thread_name\" && e.args.name === \"CrRendererMain\"\n  && events.some((n) => n.name === \"navigationStart\" && n.pid === e.pid && n.tid === e.tid))!;\nconst start = events.find((e) => e.name === \"navigationStart\" && e.pid === main.pid && e.tid === main.tid)!.ts;\nconst mine = events.filter((e) => e.pid === main.pid && e.tid === main.tid && e.ph === \"X\" && e.dur);\nconst ms = (us: number) => Math.round(us / 1000);", "note": "Um trace é uma lista longa de eventos de todo processo e thread do navegador. Aqui só a thread principal da página importa, e o relógio dela começa no navigationStart."},
 {"code": "const names: Record<string, string> = {\n  ParseHTML: \"Parse HTML\", EvaluateScript: \"Evaluate script\", \"v8.evaluateModule\": \"Evaluate module\",\n  EventDispatch: \"Event\", FunctionCall: \"Function call\", TimerFire: \"Timer fired\",\n  UpdateLayoutTree: \"Recalculate style\", Layout: \"Layout\", Paint: \"Paint\", MinorGC: \"Minor GC\", MajorGC: \"Major GC\",\n};\nconst within = (e: Event, o: Event) => o.ts <= e.ts && o.ts + o.dur! >= e.ts + e.dur!;", "note": "Os eventos que o painel nomeia dentro de uma tarefa, com os nomes que ele lhes dá. Tempos num trace são em microssegundos."},
 {"code": "for (const task of mine.filter((e) => e.name === \"RunTask\" && e.dur! >= 50_000)) {\n  const named = mine.filter((e) => e.name in names && within(e, task));\n  const outer = named.filter((e) => !named.some((o) => o !== e && within(e, o) && o.dur! > e.dur!));\n  const parts = outer.filter((e) => e.dur! >= 5_000).sort((a, b) => b.dur! - a.dur!).map((e) =>\n    `${names[e.name]}${e.name === \"EventDispatch\" ? ` (${e.args.data.type})` : \"\"} ${ms(e.dur!)}`);\n  const other = task.dur! - outer.reduce((sum, e) => sum + e.dur!, 0);\n  console.log(`long task at ${ms(task.ts - start)} ms, ${ms(task.dur!)} ms: ${[...parts, `other ${ms(other)}`].join(\", \")}`);\n}", "note": "Uma tarefa é longa a partir de 50 ms. Dentro dela, só contam os eventos com nome mais externos, porque uma função chamada por um clique faz parte do clique; o que nenhum nome cobre é \"other\"."}
]}
```

A próxima seção o roda.
