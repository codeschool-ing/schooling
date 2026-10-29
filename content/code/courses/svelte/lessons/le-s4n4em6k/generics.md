---
title: A generic component
version: 1
---

**The last error was in the course page, in the snippet that draws a session's row**, and its cause is
in `List.svelte`. `List` takes `items` and a `row` snippet that draws one of them, and nothing says the
two are of the same kind, so inside `{#snippet row(session)}` the checker has no idea what `session` is.
The list does not care what its items are, as long as each has an `id` for the keyed `{#each}`. That is
what a **generic** says: the component works for any type of item, and whichever type it is given, the
snippet gets the same one.

Replace `src/lib/List.svelte`:

```schooling-example
{"language": "html", "file": "src/lib/List.svelte", "parts": [
 {"code": "<script lang=\"ts\" generics=\"Item extends { id: number }\">\n\timport type { Snippet } from 'svelte';\n\timport { slide } from 'svelte/transition';\n\timport { flip } from 'svelte/animate';\n\timport { prefersReducedMotion } from 'svelte/motion';", "note": "`generics` declares a type parameter for the whole component, as `<T>` does for a function. `Item` can be any type that has a numeric `id`."},
 {"code": "\tlet { items, row, empty }: { items: Item[]; row: Snippet<[Item]>; empty?: Snippet } = $props();\n\n\tlet duration = $derived(prefersReducedMotion.current ? 0 : 300);\n</script>", "note": "`Snippet<[Item]>` is a snippet that takes one argument, an `Item`. Given sessions as `items`, `row` receives a session."},
 {"code": "{#if items.length}\n\t<ul>\n\t\t{#each items as item (item.id)}\n\t\t\t<li transition:slide={{ duration }} animate:flip={{ duration }}>{@render row(item)}</li>\n\t\t{/each}\n\t</ul>\n{:else}\n\t{@render empty?.()}\n{/if}"}
]}
```

```
ana@dev:~/planner$ npm run check 2>&1 | tail -1
svelte-check found 0 errors and 0 warnings
```

**Zero.** Nothing in the course page changed: its `items={sessions}` was always a list of sessions, and
now the checker can carry that type through `List` into the snippet. The page can stay JavaScript or
become TypeScript; with `List` generic, the snippet's `session` is a `Session` either way.

## What the zero is worth

Make the mistake the first section imagined, on purpose: a typo in a property name, in the course page.

```
ana@dev:~/planner$ sed -i 's/{session.minutes} min/{session.minuts} min/' 'src/routes/(planner)/courses/[id=slug]/+page.svelte'
```

```
ana@dev:~/planner$ npm run check 2>&1 | grep -A4 Error
Error: Property 'minuts' does not exist on type 'Session'. Did you mean 'minutes'? (js)
			<input type="hidden" name="done" value={session.done ? 'no' : 'yes'} />
			<span class:done={session.done}>{format(session.date)}, {session.minuts} min</span>
			<button aria-label="{session.done ? 'Mark not done' : 'Mark done'}: {format(session.date)}">
```

**Caught, with a suggestion**, in a file that is still JavaScript. Without the check the page would have
drawn `undefined min` beside every session, and the first to notice would have been a student. Put it
back:

```
ana@dev:~/planner$ sed -i 's/{session.minuts} min/{session.minutes} min/' 'src/routes/(planner)/courses/[id=slug]/+page.svelte'
```

A count of zero is useful precisely because it is zero: a new error stands out, where one more among
sixty-six would not. Keeping it there is a matter of running `npm run check` before every commit, and
lesson 19 adds the tests to run beside it.
