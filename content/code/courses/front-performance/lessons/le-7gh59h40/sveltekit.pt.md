---
title: SvelteKit
version: 1
---

**No SvelteKit uma pasta em `src/routes/` é um endereço, e os arquivos dentro dela dividem a página
pelo lugar onde rodam.** `+page.svelte` é o componente, que roda no servidor e de novo no navegador.
`+page.server.ts` ao lado dele guarda uma função `load` que roda **só no servidor**, e o que ela
devolve vira o `data` do componente. `src/routes/courses/[slug]/` atende `/courses/` seguido de
qualquer coisa.

Os dados são lidos num lugar só. Salve como `src/lib/plan.ts`, e apague o `src/lib/index.ts` que o
criador deixou lá e que nada usa:

```typescript
// src/lib/plan.ts: the planner's data, read on the server.
import { readFile } from "node:fs/promises";

export interface Plan {
  courses: { slug: string; title: string }[];
  sessions: { id: number; course: string; date: string; minutes: number; done: boolean }[];
}

export async function getPlan(): Promise<Plan> {
  return JSON.parse(await readFile("courses.json", "utf8"));
}
```

Os dados da página inicial, em `src/routes/+page.server.ts`. O import diz `#lib/plan.ts`: o
SvelteKit 3 chega a `src/lib` pela entrada `#lib` que o criador escreveu no `package.json`, e o
`$lib` de um tutorial mais antigo é recusado no build com uma mensagem que diz isso.

```typescript
// src/routes/+page.server.ts: the data for the address /, loaded on the server.
import { getPlan } from "#lib/plan.ts";

export async function load() {
  return { plan: await getPlan() };
}
```

A página inicial em si substitui `src/routes/+page.svelte`. `$props()` entrega a ela o que o `load`
devolveu:

```html
<!-- src/routes/+page.svelte: the address /. -->
<script lang="ts">
  let { data } = $props();
</script>

<svelte:head><title>Study planner</title></svelte:head>
<h1>Study planner</h1>
<ul>
  {#each data.plan.courses as c (c.slug)}
    <li>
      <a href="/courses/{c.slug}">{c.title}</a> ·
      {data.plan.sessions.filter((s) => s.course === c.slug).length} sessions
    </li>
  {/each}
</ul>
```

**Um `<a>` comum basta.** O SvelteKit pega os cliques em links para as suas próprias rotas e navega
no navegador, como o `mount` fazia na aula 1, sem um componente próprio para links. Os dados de um
curso, em `src/routes/courses/[slug]/+page.server.ts`, onde `error(404)` responde a um slug
desconhecido:

```typescript
// src/routes/courses/[slug]/+page.server.ts: the data for /courses/<slug>.
import { error } from "@sveltejs/kit";
import { getPlan } from "#lib/plan.ts";

export async function load({ params }) {
  const plan = await getPlan();
  const course = plan.courses.find((c) => c.slug === params.slug);
  if (!course) error(404);
  return { course, sessions: plan.sessions.filter((s) => s.course === params.slug) };
}
```

E a sua página, `src/routes/courses/[slug]/+page.svelte`. **Este `load` devolve só o curso e as suas
sessões**, então são só esses os dados que o navegador recebe com esta página. A seção "O que cada
um manda além do HTML" compara isso com os outros três:

```html
<!-- src/routes/courses/[slug]/+page.svelte: the address /courses/<slug>. -->
<script lang="ts">
  let { data } = $props();
</script>

<svelte:head><title>Study planner</title></svelte:head>
<p><a href="/">All courses</a></p>
<h1>{data.course.title}</h1>
<ul>
  {#each data.sessions as s (s.id)}
    <li>{s.date} · {s.minutes} min{s.done ? " · done" : ""}</li>
  {/each}
</ul>
```

`params` e `data` ficam tipados sem uma linha sua: o SvelteKit escreve os tipos de cada rota
enquanto faz o build, e `npm run check` os escreve primeiro e depois confere cada arquivo contra
eles.

## Build e servidor

Um projeto SvelteKit vira algo que uma hospedagem consegue rodar por meio de um **adapter**. O
`--add sveltekit-adapter="adapter:node"` do criador escolheu o que escreve um servidor Node em
`build/`, e o pôs no `vite.config.ts`. O build é o do Vite, e imprime a lista de arquivos do Vite;
as quatro últimas linhas são do adapter:

```
ana@dev:~/meta/svelte$ npm run check 2>&1 | tail -1
svelte-check found 0 errors and 0 warnings
ana@dev:~/meta/svelte$ npm run build 2>&1 | tail -4
> Using @sveltejs/adapter-node
Copying assets
Compressing and hashing assets
✔ done
ana@dev:~/meta/svelte$ ls build build/client
build:
adapter-node.js
client
handler.js
index.js
server

build/client:
_app
robots.txt
robots.txt.br
robots.txt.gz
```

O adapter também escreveu cada arquivo de novo, comprimido, como `.br` e `.gz`, para que o servidor
possa mandar uma cópia comprimida sem comprimir a cada requisição. Ligue-o no segundo terminal:

```sh
PORT=3003 node build
```
