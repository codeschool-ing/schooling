---
title: Modo de renderização, por rota
version: 1
---

**Cada um dos quatro deixa uma rota ser construída antes, outra ser renderizada por requisição e
uma terceira ficar com o navegador, no mesmo app.** A seção "Escolhendo, uma página de cada vez" da
aula 1 argumentou que essa é a escolha que importa; aqui está como cada um a escreve. A aula 3
constrói antes as páginas do planner nos quatro e vê os arquivos aparecerem, então esta seção só
mostra onde fica a chave.

| | construída antes | renderizada a cada requisição | deixada para o navegador |
|---|---|---|---|
| **Next.js 16** | o padrão para uma página cujos dados estão em cache (`"use cache"`), com `generateStaticParams` listando os valores de um parâmetro | tudo o que lê `cookies()`, `headers()`, `connection()` ou dados fora de cache, dentro de `<Suspense>` | um componente `"use client"` que busca os seus próprios dados no navegador |
| **Nuxt 4** | `routeRules: { "/": { prerender: true } }` no `nuxt.config.ts` | o padrão | `routeRules: { "/settings/**": { ssr: false } }` |
| **SvelteKit 3** | `export const prerender = true;` no `+page.ts`, no `+page.server.ts` ou num layout da rota | o padrão | `export const ssr = false;` |
| **Angular 21** | `RenderMode.Prerender` no `app.routes.server.ts`, com `getPrerenderParams` para um parâmetro | `RenderMode.Server` | `RenderMode.Client` |

Três deles renderizam a cada requisição se ninguém disser o contrário, e **o Next.js decide pelo que
a página lê**. Essa diferença é a que mais tende a surpreender quem passa de um para o outro: no
Next.js 16 as páginas de curso desta aula foram construídas no build sem uma linha dizendo isso,
porque tudo o que elas liam estava em cache, e acrescentar uma leitura fora de cache a uma página
muda como ela é renderizada sem mudança nenhuma na configuração da página.

## Onde a decisão fica

No Nuxt e no Angular a decisão fica em **um arquivo para o app inteiro**, uma lista de padrões de
endereço com um modo cada. Dá para ler a renderização do site num lugar só, e o arquivo de uma
página não diz como ela é renderizada. No SvelteKit a decisão fica **na própria rota**, um `export`
ao lado do seu `load`, e o valor de um layout vale para toda rota abaixo dele. No Next.js ela **sai
do código**, o que mantém a página e a sua renderização juntas e faz da tabela de rotas do build, a
que o `next build` imprimiu, o lugar para ler o resultado.

As route rules do Nuxt também guardam o que a aula 3 precisa: `isr` e `swr` regeneram uma página em
segundo plano depois de um número dado de segundos, e a aula 3 os roda. O SvelteKit e o Angular
deixam a regeneração com o que quer que guarde a página em cache na frente do servidor; o Next.js a
tem embutida, como o `cacheLife` já mostrou.

## Dois modos fáceis de confundir

**"Deixada para o navegador" não é o mesmo que "não pré-renderizada".** Uma rota deixada para o
navegador manda a casca vazia da aula 1, e tudo é desenhado pelo script. Uma rota renderizada a cada
requisição manda a página pronta. As duas "não são construídas antes", e ficam nas duas pontas da
tabela da primeira seção da aula 1.

**E pré-renderizada não quer dizer sem JavaScript.** Uma página pré-renderizada ainda manda o
framework e hidrata, exatamente como uma renderizada no servidor; só o momento em que o HTML foi
feito mudou. O SvelteKit consegue tirar o JavaScript de uma página inteiramente, com
`export const csr = false;`. Os outros três conseguem fazer menos de uma página hidratar, de jeitos a
que a aula 4 chega, mas cada um ainda manda o seu runtime: as páginas desta aula em Next.js são
feitas só de server components, e rodaram o maior volume de JavaScript dos quatro na seção "A mesma
página, de quatro jeitos".
