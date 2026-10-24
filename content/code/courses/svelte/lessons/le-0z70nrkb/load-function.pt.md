---
title: Uma função load, e os dados que ela devolve
version: 1
---

**Uma função `load` é como uma página do SvelteKit recebe seus dados antes de renderizar.** Ela mora
num arquivo ao lado da página ou do layout, `+page.js` ou `+layout.js`, e tudo o que devolve chega ao
componente numa prop chamada `data`. O SvelteKit a chama, espera por ela e só então renderiza, então o
componente nunca vê um instante sem os seus dados.

Desde a aula 8 o planner faz o contrário: o layout `(planner)` renderiza primeiro, começa um `fetch`
no navegador e mostra uma mensagem de carregamento até a resposta chegar. O servidor não roda esse
fetch, então o que ele manda é a mensagem de carregamento e nada mais. Pergunte a ele:

```
ana@dev:~/planner$ curl -s http://localhost:5173/ | grep -c '<title>'
0
```

**Nenhum título.** A página da semana define o título, e a página da semana está dentro do `{#await}`
que nunca resolve no servidor, então nunca foi renderizada lá. Um buscador, uma prévia de link ou um
navegador com o JavaScript desligado vê uma página que diz "Loading the planner…" para sempre.

## Movendo a requisição para dentro do `load`

A requisição sai do componente e vai para uma função load. Salve isto como
`src/routes/(planner)/+layout.js`, ao lado do layout do grupo:

```schooling-example
{"language": "javascript", "file": "src/routes/(planner)/+layout.js", "parts": [
 {"code": "// +layout.js: the data every page of the planner needs, loaded before any of them renders.\nimport { error } from '@sveltejs/kit';"},
 {"code": "export async function load({ fetch }) {\n\tconst response = await fetch('/planner.json');", "note": "O `load` recebe um objeto que descreve a requisição. O `fetch` dele é o do próprio SvelteKit, que consegue pedir um endereço relativo até no servidor."},
 {"code": "\tif (!response.ok) error(response.status, 'The planner could not be loaded.');", "note": "O `error()` interrompe o load e mostra a página de erro com aquele status, a que a aula 12 escreveu."},
 {"code": "\treturn response.json();\n}", "note": "O que ele devolve vira o `data` do layout."}
]}
```

O layout perde o seu código de carregamento. Não há mais nada por que esperar, porque quando o
componente roda, os dados já estão lá. Substitua o `src/routes/(planner)/+layout.svelte`:

```schooling-example
{"language": "html", "file": "src/routes/(planner)/+layout.svelte", "parts": [
 {"code": "<script>\n\timport PlannerProvider from '#lib/PlannerProvider.svelte';"},
 {"code": "\tlet { data, children } = $props();\n</script>", "note": "O `data` é o que o `load` devolveu. O `children` ainda é a página."},
 {"code": "<PlannerProvider {data}>\n\t{@render children()}\n</PlannerProvider>"}
]}
```

```
ana@dev:~/planner$ curl -s http://localhost:5173/ | grep -o '<title>.*</title>'
<title>225 min this week · Study planner</title>
```

**Desta vez o servidor renderizou a página inteira**, título incluído: ele rodou o `load`, esperou o
arquivo e renderizou a semana com os dados dentro. O `{#await}` e seus três ramos sumiram, e junto foi
o `browser` do `$app/env`, a defesa de que a aula 8 precisou porque o componente não sabia onde
estava rodando. Uma função load também não precisa saber.

## Roda duas vezes, busca uma

Uma função load num `+layout.js` ou `+page.js` é **universal**: roda no servidor para renderizar a
primeira página, e de novo no navegador, quando a página ganha vida. A segunda vez não repete a
requisição. Durante a vez do servidor, o `fetch` do SvelteKit guardou a resposta e a escreveu no HTML;
no navegador, o mesmo `fetch('/planner.json')` a encontra ali e responde na hora:

```
ana@dev:~/planner$ curl -s http://localhost:5173/ | grep -o '<script type="application/json" data-sveltekit-fetched[^>]*>'
<script type="application/json" data-sveltekit-fetched data-url="/planner.json">
```

Essa é a razão de usar o `fetch` que o `load` recebe em vez do global. O `fetch` global no servidor não
aceita um endereço relativo, como a aula 8 descobriu, e no navegador pediria de novo o que a página já
tem.
