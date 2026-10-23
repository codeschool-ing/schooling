---
title: Componentes assíncronos, de quatro jeitos
version: 1
---

**Um componente assíncrono é um que precisa esperar alguma coisa antes de poder renderizar, e um
framework deixa o resto da página seguir sem ele.** É o `stream.ts` escrito como componente: o
framework manda um marcador onde o componente vai e o preenche quando os dados dele chegam. Dois dos
quatro meta-frameworks da aula 2 o preenchem mais tarde na mesma resposta, e fazem isso de dois jeitos
diferentes.

## Next.js: o `<Suspense>` manda o HTML em streaming

Envolva um componente que espera num `<Suspense>`, dê a ele um `fallback`, e o Next.js manda o
fallback com o resto da página e o HTML do componente depois. No projeto Next.js, salve isto como
`app/slow/page.tsx`; a espera de um segundo faz o papel de uma consulta lenta, como no `stream.ts`:

```tsx
// app/slow/page.tsx: a page with one part that takes a second to arrive.
import { Suspense } from "react";

async function Sessions() {
  await new Promise((done) => setTimeout(done, 1000)); // stands for a slow query
  return <ul><li>Sat 2026-10-24 · 25 min</li><li>Tue 2026-10-27 · 40 min</li></ul>;
}

export default function Slow() {
  return (
    <>
      <h1>Git</h1>
      <Suspense fallback={<p>Loading sessions…</p>}>
        <Sessions />
      </Suspense>
    </>
  );
}
```

Faça o build, ligue-o na porta 3001, e veja os pedaços:

```
ana@dev:~/planner$ node tools/chunks.ts http://localhost:3001/slow
87 ms  status 200
122 ms  1302 bytes  <!DOCTYPE html><html lang="en"><head><meta charSet="utf-8"/>
132 ms  4127 bytes  <script>(self.__next_f=self.__next_f||[]).push([0])</script>
133 ms  4030 bytes  <script>self.__next_f.push([1,"1a:o1,~1a:o40d,2:\"$Sreact.fr
1101 ms  211 bytes  <script>self.__next_f.push([1,"a:[\"$\",\"ul\",null,{\"child
1101 ms  73 bytes  <script src="/_next/static/chunks/0cz1d0mv5g_q7.js" noModule
1103 ms  964 bytes  <div hidden id="S:0"><ul><li>Sat 2026-10-24 · 25 min</li><li
1104 ms  14 bytes  </body></html>
```

Os primeiros pedaços chegaram juntos, a página e o fallback, e as sessões vieram um segundo depois
como HTML num `<div>` escondido, com o payload do React para elas logo antes. O build listou `/slow`
com um `◐`: a sua casca é pré-renderizada, e a parte dentro do `<Suspense>` é renderizada por
requisição.

## SvelteKit: uma promise manda os dados em streaming

No SvelteKit, uma função `load` no servidor pode devolver uma promise **sem esperar por ela**. A
página renderiza na hora com a promise ainda pendente, e o SvelteKit manda o valor dela depois, na
mesma resposta. A própria página decide o que mostrar enquanto isso, com `{#await}`. Dois arquivos
novos no projeto SvelteKit; o primeiro desliga o prerender da aula 3 para esta rota, porque uma página
construída antes não consegue esperar nada:

```typescript
// src/routes/slow/+page.server.ts: a page with one part that takes a second to arrive.
export const prerender = false;

export function load() {
  const sessions = new Promise<string[]>((done) =>
    setTimeout(() => done(["Sat 2026-10-24 · 25 min", "Tue 2026-10-27 · 40 min"]), 1000)); // stands for a slow query
  return { sessions };
}
```

```html
<!-- src/routes/slow/+page.svelte: the title at once, the sessions when they come. -->
<script lang="ts">
  let { data } = $props();
</script>

<h1>Git</h1>
{#await data.sessions}
  <p>Loading sessions…</p>
{:then sessions}
  <ul>
    {#each sessions as s}<li>{s}</li>{/each}
  </ul>
{/await}
```

```
ana@dev:~/planner$ node tools/chunks.ts http://localhost:3003/slow
69 ms  status 200
70 ms  4519 bytes  <!doctype html> <html lang="en"> <head> <meta charset="utf-8
1054 ms  113 bytes  <script>__sveltekit_1k3z5ml.resolve(1, () => [["Sat 2026-10-
```

**O segundo pedaço não é HTML, e sim dados**: uma chamada a uma função que o SvelteKit pôs na página,
com as duas sessões como argumento. O script as renderiza na página. Então no SvelteKit as sessões só
aparecem com JavaScript, enquanto no Next.js elas chegam como HTML e só precisam de JavaScript para
serem movidas para o lugar.

## Nuxt e Angular

**No servidor, o Nuxt renderiza uma página quando os dados dela chegaram**, e a sua opção `lazy` para
o `useFetch` muda o que acontece nas navegações no navegador, onde a página nova pode aparecer antes
dos seus dados. O bloco `@defer` do Angular renderiza o seu marcador no servidor, e o bloco em si é
carregado e renderizado no navegador. Nenhum dos dois manda uma parte lenta mais tarde na mesma
resposta, nas versões desta aula. Os dois ainda impedem uma parte lenta de segurar o resto da página;
a diferença é onde a parte lenta acaba sendo desenhada, e se um crawler chega a vê-la.

| | a parte lenta chega como | na primeira resposta? | sem JavaScript |
|---|---|---|---|
| `stream.ts` | HTML, num template | sim, mais tarde nela | o marcador fica |
| `<Suspense>` do Next.js | HTML, num elemento escondido | sim, mais tarde nela | o marcador fica |
| promise em streaming do SvelteKit | dados, renderizados pelo script | sim, mais tarde nela | o marcador fica |
| `lazy` do Nuxt | dados, buscados na navegação no navegador | o servidor esperou por eles | na primeira página, sim |
| `@defer` do Angular | um componente, carregado no navegador | só o marcador | o marcador fica |
