---
title: Svelte
version: 1
---

**O Svelte é um compilador: um arquivo `.svelte` é transformado, na hora do build, em JavaScript puro
que atualiza a página diretamente, e boa parte do que os outros frameworks fazem enquanto a página roda
é feita antes de ela ser enviada.** Desde o Svelte 5, as partes reativas são *runes*, `$state` e
`$derived`, marcas que o compilador lê. O projeto, feito pelo `create-vite` como os do Vue e do React:

```
ana@dev:~/vue/compare$ npm create vite@9.3.1 -- svelte --template svelte-ts --no-immediate

> npx
> cva svelte --template svelte-ts --no-immediate


create-vite v9.3.1

│
◇  Scaffolding project in /home/ana/vue/compare/svelte...
│
└  Done. Now run:

  cd svelte
  npm install
  npm run dev
```

```
ana@dev:~/vue/compare/svelte$ npm install

added 49 packages, and audited 50 packages in 5s

11 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
ana@dev:~/vue/compare/svelte$ npm install --save-dev --save-exact svelte@5.57.2

added 2 packages, and audited 52 packages in 660ms

12 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
ana@dev:~/vue/compare/svelte$ rm -r src/App.svelte src/app.css src/lib
```

O card:

```html
<!-- src/WeekCard.svelte: one course's week, the Svelte way -->
<script lang="ts">
  console.log('Svelte: the script runs')
  let sessions = $state([
    { id: 's3', date: '19 October', minutes: 30, done: true },
    { id: 's6', date: '23 October', minutes: 40, done: false },
  ])
  const planned = $derived(sessions.reduce((sum, s) => sum + s.minutes, 0))
  const done = $derived(sessions.filter((s) => s.done).reduce((sum, s) => sum + s.minutes, 0))
</script>

<section>
  <h2>Spanish</h2>
  <ul>
    {#each sessions as s (s.id)}
      <li>
        <label><input type="checkbox" bind:checked={s.done} /> {s.date}, {s.minutes} minutes</label>
      </li>
    {/each}
  </ul>
  <p>{done} of {planned} minutes done</p>
</section>
```

e a entrada:

```typescript
// src/main.ts: the card, and nothing else, in the page's #app.
import { mount } from 'svelte'
import WeekCard from './WeekCard.svelte'

mount(WeekCard, { target: document.getElementById('app')! })
```

Dos quatro, é o mais próximo dos componentes de arquivo único do Vue, um `<script>` e a marcação num
arquivo só, com três diferenças de natureza:

- **`$state` torna reativa uma variável comum**, e mudá-la, ou um campo dentro dela, é uma atribuição
  comum: `bind:checked` escreve `s.done` direto na lista, como fazia o objeto reativo do Vue. Sem
  `.value`, sem setter, sem chamada de função para ler.
- **`$derived(...)`** é o `computed`.
- **A marcação não fica dentro de um `<template>`**, e o controle de fluxo dela são blocos,
  `{#each sessions as s (s.id)}`, com a chave entre parênteses.

`npm run dev`, e a marcação:

```
ana@dev:~/vue/compare/svelte$ look http://localhost:5173/ --do 'check text=23 October' --text body
[vite] connecting...
Svelte: the script runs
[vite] connected.
-- check text=23 October
== the text of body
Spanish
 19 October, 30 minutes
 23 October, 40 minutes

70 of 70 minutes done
```

O script rodou uma vez, como o setup do Vue e o construtor do Angular. O que aconteceu na marcação foram
algumas linhas de JavaScript gerado, que atualizaram o texto que mostra os totais e nada mais.
