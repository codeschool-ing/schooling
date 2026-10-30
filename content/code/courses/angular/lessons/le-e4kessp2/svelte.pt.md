---
title: Svelte
version: 1
---

**O Svelte é um compilador: um componente é escrito numa linguagem pequena própria, e o build o
transforma em JavaScript simples que atualiza a página direto.** Há menos Svelte na página do que de
qualquer um dos outros, porque muito do que os outros fazem enquanto rodam, o Svelte fez enquanto
compilava. O projeto dele sai do mesmo gerador:

```
ana@dev:~/compare$ npm create vite@9.3.1 -- svelte --template svelte-ts --no-immediate

> npx
> cva svelte --template svelte-ts --no-immediate


create-vite v9.3.1

│
◇  Scaffolding project in /home/ana/compare/svelte...
│
└  Done. Now run:

  cd svelte
  npm install
  npm run dev
```

```
ana@dev:~/compare/svelte$ npm install

added 49 packages, and audited 50 packages in 4s

2 low severity vulnerabilities

Some issues need review, and may require choosing
a different dependency.

Run `npm audit` for details.
```

```
ana@dev:~/compare/svelte$ npm install --save-exact svelte@5.57.3 @sveltejs/vite-plugin-svelte@7.3.1 @tsconfig/svelte@5.0.8 @types/node@22.20.5 svelte-check@4.7.7 typescript@6.0.3 vite@8.3.5

added 2 packages, changed 2 packages, and audited 52 packages in 2s

2 low severity vulnerabilities

Some issues need review, and may require choosing
a different dependency.

Run `npm audit` for details.
```

Duas baixas, nas duas instalações. A auditoria diz o que são:

```
ana@dev:~/compare/svelte$ npm audit 2>&1 | head -9
# npm audit report

deepmerge  >=4.2.0
deepmerge mergeObject() allows prototype poisoning of returned objects - https://github.com/advisories/GHSA-gcqx-w48m-w2h4
No fix available
node_modules/deepmerge
  @sveltejs/vite-plugin-svelte  *
  Depends on vulnerable versions of deepmerge
  node_modules/@sveltejs/vite-plugin-svelte
```

O `deepmerge`, uma pequena biblioteca que o plugin do Svelte para o Vite usa no build, tem um aviso e
nenhuma versão corrigida. Ele roda na sua máquina durante um build e não está na página. Para um
cartão apagado no fim desta aula, isso encerra o assunto; num projeto de verdade, é uma entrada para
anotar, e para ler de novo quando o plugin for atualizado.

```
ana@dev:~/compare/svelte$ rm -r src/App.svelte src/lib src/app.css
```

O cartão:

```schooling-example
{"language": "html", "file": "src/WeekCard.svelte", "parts": [
 {"code": "<!-- src/WeekCard.svelte: one course's week, the Svelte way -->\n<script lang=\"ts\">\n  console.log('Svelte: the script runs');", "note": "Um componente é um arquivo `.svelte`: um script, depois a marcação."},
 {"code": "  let sessions = $state([\n    { id: 3, date: 'Tue 20 Oct', minutes: 60, done: true },\n    { id: 5, date: 'Sat 24 Oct', minutes: 50, done: false },\n  ]);\n  const planned = $derived(sessions.reduce((sum, s) => sum + s.minutes, 0));\n  const done = $derived(sessions.filter((s) => s.done).reduce((sum, s) => sum + s.minutes, 0));\n</script>\n", "note": "`$state` e `$derived` são runes: palavras que o compilador do Svelte lê e transforma no próprio código de atualização. O estado é um array simples para o código que o usa, escrito direto."},
 {"code": "<section>\n  <h2>JavaScript</h2>\n  <ul>\n    {#each sessions as s (s.id)}\n      <li>\n        <label><input type=\"checkbox\" bind:checked={s.done} /> {s.date}, {s.minutes} minutes</label>\n      </li>\n    {/each}\n  </ul>\n  <p>{done} of {planned} minutes done</p>\n</section>", "note": "O `{#each}` é o laço, com a chave entre parênteses, e o `bind:checked` escreve a caixa de volta em `s.done`."}
]}
```

```typescript
// src/main.ts: the card, and nothing else, in the page's #app
import { mount } from 'svelte';
import WeekCard from './WeekCard.svelte';

mount(WeekCard, { target: document.getElementById('app')! });
```

```
ana@dev:~/compare/svelte$ look http://localhost:5173/ --do 'check Sat 24 Oct, 50 minutes' --text body
[vite] connecting...
Svelte: the script runs
[vite] connected.
-- check Sat 24 Oct, 50 minutes
JavaScript
 Tue 20 Oct, 60 minutes
 Sat 24 Oct, 50 minutes

110 of 110 minutes done
```

**Uma vez** de novo. O script rodou quando o cartão foi criado, e a marcação chegou aos dois `$derived`
e ao parágrafo por código que o compilador escreveu exatamente para eles, sem um framework decidindo
em tempo de execução para onde olhar. Pare o dev server.
