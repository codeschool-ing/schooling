---
title: Where other frameworks put slots
version: 1
---

**Every component framework has a way to pass markup into a component, and they differ more in name
than in idea.** Snippets replaced Svelte 4's slots, and if you read Svelte 4 code, or come from Vue or
Angular, the old words are the ones you know. This section lines them up, so that the idea is
recognisable under any of its names.

## Svelte 4's slots

The `List` of this lesson, written for Svelte 4, would have looked like this. It is here to be read;
lesson 4 showed how such a file runs in a Svelte 5 project when you need it to.

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

and the page passed the row with an element carrying `slot="row"` and a `let:` directive to receive
the item:

```html
<List items={ofCourse}>
	<label slot="row" let:item={session}>
		<input type="checkbox" bind:checked={session.done} />
		{format(session.date)}, {session.minutes} min
	</label>
	<p slot="empty">Nothing planned this week.</p>
</List>
```

Three things were awkward about it, and snippets fix each one. The content of a named slot had to be a
single element, so a row of two elements needed a wrapper, `<svelte:fragment>`. Data coming back into the slot travelled by
`let:`, a directive that existed only for this. And a slot could not be passed on as a value: a
component could not give one of its slots to a child, or keep it in a variable. **A snippet is a value
with parameters**, so all three stop being special cases.

## The same idea elsewhere

| | markup passed in | with data from the component |
|---|---|---|
| Svelte 5 | `children`, or a snippet prop | `{#snippet row(item)}` and `{@render row(item)}` |
| Svelte 4 | `<slot />`, `<slot name="x" />` | `<slot name="x" {item} />` and `let:item` |
| React | `children`, or any prop holding JSX | a function prop, `row={(item) => <…/>}`, called "render props" |
| Vue | `<slot />`, named slots | scoped slots, `<template #row="{ item }">` |
| Angular | `<ng-content>`, with `select` for named parts | `<ng-template>` passed in and rendered with `ngTemplateOutlet` |

**React's render prop is the closest relative of a snippet**: a function the parent writes, the child
calls with data, and whose result is markup. The difference is the one lesson 2 described: React calls
that function again on every render, while a Svelte snippet is set up once and its parameters are read
live. Lesson 20 shows the planner's list in each of the other three.
