---
title: Svelte, um compilador
version: 1
---

**O Svelte é mais um compilador que uma biblioteca.** Um arquivo `.svelte` vira, no build, JavaScript que
cria a página e a atualiza diretamente, sem passo de comparação no navegador. O projeto:

```
ana@dev:~$ npm create vite@9.3.1 sessions-svelte -- --template svelte-ts --no-interactive > /dev/null && cd sessions-svelte && npm config set save-exact true --location=project && npm install --silent --save-dev svelte@5.57.2 @sveltejs/vite-plugin-svelte@7.3.1 @tsconfig/svelte@5.0.8 @types/node@22.20.5 svelte-check@4.7.7 typescript@6.0.3 vite@8.3.5 && rm src/lib/Counter.svelte && grep -A 9 "\"devDependencies\"" package.json
  "devDependencies": {
    "@sveltejs/vite-plugin-svelte": "7.3.1",
    "@tsconfig/svelte": "5.0.8",
    "@types/node": "22.20.5",
    "svelte": "5.57.2",
    "svelte-check": "4.7.7",
    "typescript": "6.0.3",
    "vite": "8.3.5"
  }
}
```

**Tudo está em `devDependencies`**, o `svelte` incluído, porque o Svelte é sobretudo uma ferramenta que
roda enquanto você faz o build. A pequena parte dele de que o código compilado precisa em tempo de
execução é copiada para o bundle pelo build, como qualquer outro import. `src/lib/Sessions.svelte`:

```html
<script lang="ts">
  type Session = { id: string; course: string; minutes: number; done: boolean }

  let sessions = $state<Session[]>([
    { id: 's1', course: 'Statistics', minutes: 40, done: true },
    { id: 's2', course: 'Python', minutes: 35, done: false },
    { id: 's3', course: 'Statistics', minutes: 45, done: false },
  ])
  const done = $derived(sessions.filter((s) => s.done).reduce((sum, s) => sum + s.minutes, 0))
  const total = $derived(sessions.reduce((sum, s) => sum + s.minutes, 0))
  console.log('Sessions ran')
</script>

<section>
  <h1>This week</h1>
  <p>{done} of {total} minutes done</p>
  <ul>
    {#each sessions as s (s.id)}
      <li>
        <button aria-pressed={s.done} onclick={() => (s.done = !s.done)}>
          {s.course} · {s.minutes} min
        </button>
      </li>
    {/each}
  </ul>
</section>
```

- O **`<script>`** roda uma vez, quando o componente é criado, como o do Vue.
- O **`$state`** cria um valor reativo, e o **`$derived`** um calculado a partir de outros. O Svelte os
  chama de **runas**: parecem funções, mas o compilador as lê e escreve o código que as acompanha. Não há
  `.value` aqui; `sessions` é lido e escrito como qualquer variável.
- O handler do clique escreve **`s.done = !s.done`** direto no array, como o do Vue, pelo mesmo motivo: o
  `$state` o envolveu num proxy.
- O markup vem depois do script, sem `return`. **`{#each sessions as s (s.id)}`** o repete, com a chave
  entre parênteses; **`onclick`** é o atributo que todo navegador já conhece, recebendo uma função.

`src/App.svelte`:

```html
<script lang="ts">
  import Sessions from './lib/Sessions.svelte'
</script>

<Sessions />
```

Build, servir, clicar:

```
ana@dev:~/sessions-svelte$ npm run build

> sessions-svelte@0.0.0 build
> vite build

vite v8.3.5 building client environment for production...
transforming...
✓ 112 modules transformed.
rendering chunks...
computing gzip size...
dist/index.html                  0.46 kB │ gzip:  0.29 kB
dist/assets/index-CsUDhMuy.css   4.10 kB │ gzip:  1.46 kB
dist/assets/index-zq9nADzc.js   33.37 kB │ gzip: 13.22 kB

✓ built in 234ms
ana@dev:~/sessions-svelte$ look http://localhost:4173/ --do 'click button Python · 35 min' --do 'click button Statistics · 45 min'
Sessions ran
-- click button Python · 35 min
-- click button Statistics · 45 min
- heading "This week" [level=1]
- paragraph: 120 of 120 minutes done
- list:
  - listitem:
    - button "Statistics · 40 min" [pressed]
  - listitem:
    - button "Python · 35 min" [pressed]
  - listitem:
    - button "Statistics · 45 min" [pressed]
```

**`Sessions ran` uma vez de novo**, e desta vez nem o template roda de novo de nenhuma forma que você
reconheceria. O compilador escreveu, para cada lugar que lê `done`, `total` ou `s.done`, um pedaço pequeno
de código que atualiza aquele texto ou atributo, e um clique roda esses pedaços e nada mais.

`112 modules transformed`, contra os 17 do React, é o compilador trabalhando: as partes do runtime do
Svelte de que este componente precisa, cada uma um módulo pequeno, juntadas. O script `build` do Svelte não
confere tipos, como o do Vue confere; isso é o `npm run check` separado, que roda o `svelte-check`.
