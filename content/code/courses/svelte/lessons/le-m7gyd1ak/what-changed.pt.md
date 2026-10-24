---
title: O que o Svelte 5 mudou
version: 1
---

**O Svelte 5, lançado em outubro de 2024, trocou o jeito de escrever reatividade, e quase todo o
resto de um componente veio junto.** O Svelte 4 tornava reativo um JavaScript de aparência comum por
convenção: um `let` no topo de um componente era estado, `export let` era uma prop, e um rótulo `$:`
marcava uma linha para rodar de novo. O Svelte 5 diz as mesmas coisas com runes, que são explícitas,
funcionam fora de componentes e são rastreadas em tempo de execução em vez de adivinhadas em tempo de
compilação.

A sintaxe antiga não desapareceu. **O Svelte 5 ainda compila componentes Svelte 4**, no que ele chama
de modo legado, então um projeto pode atualizar primeiro o compilador e depois os componentes, um de
cada vez. É por isso que há tanto código Svelte 4 ainda rodando, e ainda sendo escrito: tutoriais,
respostas na internet, bibliotecas de componentes, e código sugerido por ferramentas treinadas em
tudo isso.

## As mesmas ideias, duas grafias

| a ideia | Svelte 4 | Svelte 5 |
|---|---|---|
| um valor do qual a página depende | `let count = 0;` no topo do script | `let count = $state(0);` |
| um valor calculado a partir de outros | `$: double = count * 2;` | `let double = $derived(count * 2);` |
| código que roda de novo quando valores mudam | `$: console.log(count);` | `$effect(() => console.log(count));` |
| uma prop | `export let minutes;` | `let { minutes } = $props();` |
| todas as props, e o resto | `$$props`, `$$restProps` | `let { a, ...rest } = $props();` |
| uma prop que o filho pode escrever de volta | `export let value;` e `bind:value` | `let { value = $bindable() } = $props();` e `bind:value` |
| um evento do DOM | `on:click={handler}` | `onclick={handler}` |
| um modificador de evento | `on:click|preventDefault` | `event.preventDefault()` no handler |
| um evento de componente | `createEventDispatcher()`, `dispatch('change')`, `on:change` | uma prop de callback: `onchange` |
| conteúdo passado para dentro de um componente | `<slot />`, `<slot name="x" />`, `let:item` | `{@render children()}`, snippets |
| um componente escolhido em tempo de execução | `<svelte:component this={C} />` | `<C />`, já que componentes são dinâmicos |
| criar um componente a partir de JavaScript | `new Component({ target })` | `mount(Component, { target })` |

**As stores não mudaram.** `writable`, `readable`, `derived` e o atalho `$store` funcionam no Svelte 5
exatamente como no Svelte 4; o que mudou é que runes num módulo `.svelte.js` agora cobrem muitos dos
casos para os quais se usavam stores. A aula 10 trata de escolher.

## O que os dois modos não fazem juntos

Um componente está num modo ou no outro, decidido arquivo por arquivo. **No modo runes a sintaxe
legada é um erro**: `export let` é recusado, `$:` é recusado, e um `let` comum é só uma variável. No
modo legado as runes não estão disponíveis. Componentes nos dois modos podem usar uns aos outros
livremente, e é isso que torna possível a atualização aos poucos.

O `vite.config.js` do planner foi escrito pelo `sv` para forçar o modo runes em todo componente do
projeto, com uma exceção para os pacotes em `node_modules`, que podem ser mais antigos. Um componente
legado no projeto precisa dizer isso por conta própria, e a próxima seção mostra como.

## O SvelteKit também mudou

Código escrito para o SvelteKit 1 ou 2 traz os seus próprios sinais de idade, e o SvelteKit 3 recusa
alguns deles:

| você vai ler | o SvelteKit 3 escreve | |
|---|---|---|
| `import { page } from '$app/stores'` e `$page.url` | `import { page } from '$app/state'` e `page.url` | `$app/stores` foi removido na 3.0 |
| `import x from '$lib/x.js'` | `import x from '#lib/x.js'` | `$lib` foi trocado pelos subpath imports do próprio Node |
| `export let data;` no `+page.svelte` | `let { data } = $props();` | a mudança do Svelte 4 para o 5, numa rota |
| `throw error(404, …)` | `error(404, …)` | desde o SvelteKit 2 eles lançam sozinhos |

A última seção desta aula mostra o que acontece quando os dois primeiros encontram um projeto
SvelteKit 3.
