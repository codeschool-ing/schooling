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
@@
```

Faça o build, ligue-o na porta 3001, e veja os pedaços:

```
@@
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
@@
```

```html
@@
```

```
@@
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
