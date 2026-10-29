---
title: Os frameworks de aplicação, e o formulário com JavaScript desligado
version: 1
---

**Cada um dos quatro tem um framework de aplicação em volta, e eles se parecem mais entre si do que as
bibliotecas.** O SvelteKit, o Next.js para o React, o Nuxt para o Vue e o próprio router do Angular com a
sua renderização no servidor fazem todos o roteamento por arquivo ou por configuração, carregam dados no
servidor, renderizam a primeira página lá e assumem no navegador. As aulas 12 a 17 deste curso se
encaixam neles de perto:

| SvelteKit | Next.js | Nuxt | Angular |
|---|---|---|---|
| uma pasta com `+page.svelte` | uma pasta com `page.tsx` | um arquivo em `pages/` | uma rota na configuração do router |
| `+layout.svelte` | `layout.tsx` | um layout em `layouts/` | uma rota pai com um `<router-outlet>` |
| `load` em `+page.server.js` | um Server Component assíncrono | `useFetch`, `useAsyncData` | um resolver, ou um service chamado pelo componente |
| form actions | Server Actions | rotas de servidor em `server/` chamadas com `$fetch` | `HttpClient` para uma API |
| `+server.js` | `route.ts` | `server/api/` | um back end separado |
| `ssr`, `csr`, `prerender` | renderização estática, dinâmica e em streaming | `ssr`, `routeRules` | SSR e pré-renderização com hidratação |

O curso de React trata de Server Components na aula 15, de Actions na aula 16 e do Next.js na aula 18; o
de Vue trata do Nuxt nas aulas 18 a 20; o de Angular trata do router nas aulas 17 e 18 e da renderização
no servidor na aula 23.

## A linha que difere

**A linha dos formulários é onde o SvelteKit se destaca**, e é por isso que a aula 14 foi a mais longa
deste curso. Uma form action do SvelteKit é um `<form>` que o navegador envia sozinho, então funciona com
JavaScript desligado, e o `use:enhance` a melhora quando há JavaScript. Dos outros, o React foi o que
chegou mais perto: as Server Actions do Next.js aceitam um formulário do mesmo jeito, um
`<form action={…}>` que o servidor trata, e o Next.js as renderiza de modo que possam ser enviadas antes
de o JavaScript da página ter carregado. O Nuxt e o Angular levam dados ao servidor com JavaScript, a
partir de código na página: nos dois, um formulário que funciona com JavaScript desligado é possível, e é
algo que você constrói, e não o que você ganha.

É uma diferença de padrão, não de capacidade. Qualquer um dos quatro consegue construir um planner que
funciona sem JavaScript, e qualquer um consegue construir um que não funciona. O padrão decide com qual
deles a maioria dos projetos termina, e o planner da aula 14 é o que o padrão do SvelteKit produz.
