---
title: Onde os outros frameworks põem slots
version: 1
---

**Todo framework de componentes tem um jeito de passar marcação para dentro de um componente, e eles
diferem mais no nome do que na ideia.** Os snippets substituíram os slots do Svelte 4, e se você lê
código Svelte 4, ou vem do Vue ou do Angular, as palavras antigas são as que você conhece. Esta seção
as alinha, para que a ideia seja reconhecível sob qualquer um dos nomes.

## Os slots do Svelte 4

O `List` desta aula, escrito para o Svelte 4, teria ficado assim. Ele está aqui para ser lido; a aula
4 mostrou como um arquivo desses roda num projeto Svelte 5 quando você precisa.

```html
<!-- List.svelte, in Svelte 4 -->
<script>
	export let items;
</script>

{#if items.length}
	<ul>
		{#each items as item (item.id)}
			<li><slot name="row" {item} /></li>
		{/each}
	</ul>
{:else}
	<slot name="empty" />
{/if}
```

e a página passava a linha com um elemento que tinha `slot="row"` e uma diretiva `let:` para receber o
item:

```html
<List items={ofCourse}>
	<label slot="row" let:item={session}>
		<input type="checkbox" bind:checked={session.done} />
		{format(session.date)}, {session.minutes} min
	</label>
	<p slot="empty">Nothing planned this week.</p>
</List>
```

Três coisas eram desajeitadas nisso, e os snippets resolvem cada uma. O conteúdo de um slot com nome
tinha de ser um único elemento, então uma linha de dois elementos precisava de um embrulho,
`<svelte:fragment>`. Os dados que voltavam para o slot viajavam por `let:`, uma diretiva que só
existia para isso. E um slot não podia ser passado adiante como valor: um componente não conseguia
dar um dos seus slots a um filho, nem guardá-lo numa variável. **Um snippet é um valor com
parâmetros**, então os três deixam de ser casos especiais.

## A mesma ideia em outros lugares

| | marcação passada para dentro | com dados vindos do componente |
|---|---|---|
| Svelte 5 | `children`, ou uma prop de snippet | `{#snippet row(item)}` e `{@render row(item)}` |
| Svelte 4 | `<slot />`, `<slot name="x" />` | `<slot name="x" {item} />` e `let:item` |
| React | `children`, ou qualquer prop com JSX | uma prop de função, `row={(item) => <…/>}`, chamada de "render props" |
| Vue | `<slot />`, slots com nome | scoped slots, `<template #row="{ item }">` |
| Angular | `<ng-content>`, com `select` para partes com nome | um `<ng-template>` passado para dentro e renderizado com `ngTemplateOutlet` |

**A render prop do React é o parente mais próximo de um snippet**: uma função que o pai escreve, o
filho chama com dados, e cujo resultado é marcação. A diferença é a que a aula 2 descreveu: o React
chama essa função de novo a cada renderização, enquanto um snippet do Svelte é preparado uma vez e os
seus parâmetros são lidos ao vivo. A aula 20 mostra a lista do planner em cada um dos outros três.
