---
title: Keys, and the row that keeps the wrong input
version: 1
---

**When a list changes, Svelte has to decide which existing element becomes which item.** Without a key
it decides by position: the first element shows the first item, the second the second, and when the
order changes, each element is given different data. Most of the time that is invisible, because the
element shows whatever data it is given. It stops being invisible as soon as an element holds
something of its own that is not data: text typed into a field that is not bound, focus, a running
animation, a component's internal state.

To see it without disturbing the planner, use a page of its own, as lesson 4 did for old code. This
one is the course panel cut down to two sessions, a button that sorts them, and a field beside each
for a note that is not bound to anything:

```html
<!-- src/routes/keys/+page.svelte -->
<script>
	let sessions = $state([
		{ id: 3, date: '19 Oct', minutes: 90 },
		{ id: 6, date: '24 Oct', minutes: 60 }
	]);
	let shortestFirst = $state(false);
	let shown = $derived(shortestFirst ? sessions.toSorted((a, b) => a.minutes - b.minutes) : sessions);
</script>

<main>
	<button aria-pressed={shortestFirst} onclick={() => (shortestFirst = !shortestFirst)}>
		Shortest first
	</button>
	<ul>
		{#each shown as session}
			<li>
				{session.date}, {session.minutes} min
				<input aria-label="Note for {session.date}" />
			</li>
		{/each}
	</ul>
</main>
```

Type a note for the 19th, then sort:

```
ana@dev:~/planner$ look http://localhost:5173/keys --fill 'Note for 19 Oct=read chapter 3' --click 'Shortest first'
-- fill Note for 19 Oct=read chapter 3
-- click Shortest first
at /keys
- main:
  - button "Shortest first" [pressed]
  - list:
    - listitem:
      - text: 24 Oct, 60 min
      - textbox "Note for 24 Oct": read chapter 3
    - listitem:
      - text: 19 Oct, 90 min
      - textbox "Note for 19 Oct"
```

**The note is now beside the 24th.** The first `<li>` was given the 24th's data, so its text and its
field's label changed, and the text typed into the field, which belongs to the element and not to the
data, stayed where it was. The field is now labelled "Note for 24 Oct" and says "read chapter 3", which
was a note about the 19th.

A key tells Svelte which item an element belongs to, so that a change of order **moves** elements
instead of giving them new data. It goes in brackets after the item, and it has to be something that
identifies the item and never changes, which is exactly what an id is:

```html
<!-- src/routes/keys/+page.svelte -->
<script>
	let sessions = $state([
		{ id: 3, date: '19 Oct', minutes: 90 },
		{ id: 6, date: '24 Oct', minutes: 60 }
	]);
	let shortestFirst = $state(false);
	let shown = $derived(shortestFirst ? sessions.toSorted((a, b) => a.minutes - b.minutes) : sessions);
</script>

<main>
	<button aria-pressed={shortestFirst} onclick={() => (shortestFirst = !shortestFirst)}>
		Shortest first
	</button>
	<ul>
		{#each shown as session (session.id)}
			<li>
				{session.date}, {session.minutes} min
				<input aria-label="Note for {session.date}" />
			</li>
		{/each}
	</ul>
</main>
```

```
ana@dev:~/planner$ look http://localhost:5173/keys --fill 'Note for 19 Oct=read chapter 3' --click 'Shortest first'
-- fill Note for 19 Oct=read chapter 3
-- click Shortest first
at /keys
- main:
  - button "Shortest first" [pressed]
  - list:
    - listitem:
      - text: 24 Oct, 60 min
      - textbox "Note for 24 Oct"
    - listitem:
      - text: 19 Oct, 90 min
      - textbox "Note for 19 Oct": read chapter 3
```

The 24th moved up, the 19th moved down, and the note went with the 19th, because its element went
with it. Delete the folder, `rm -r src/routes/keys`, when you are done.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"The same sort, with and without a key. On the left, without a key: the two list elements stay where they are and are given new data, so the first element, which holds the note read chapter 3, now shows the 24th. On the right, with a key: the elements move with their sessions, so the element holding the note moves down with the 19th.\"><text x=\"180\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--amber)\">without a key</text><text x=\"80\" y=\"44\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">before</text><text x=\"270\" y=\"44\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">after the sort</text><rect x=\"20\" y=\"60\" width=\"130\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"85\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">19 Oct, 90 min</text><rect x=\"30\" y=\"94\" width=\"110\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"36\" y=\"106\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">read chapter 3</text><rect x=\"20\" y=\"150\" width=\"130\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"85\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">24 Oct, 60 min</text><rect x=\"30\" y=\"184\" width=\"110\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"36\" y=\"196\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\"></text><rect x=\"210\" y=\"60\" width=\"130\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"275\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">24 Oct, 60 min</text><rect x=\"220\" y=\"94\" width=\"110\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"226\" y=\"106\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--amber)\">read chapter 3</text><rect x=\"210\" y=\"150\" width=\"130\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"275\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">19 Oct, 90 min</text><rect x=\"220\" y=\"184\" width=\"110\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"226\" y=\"196\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\"></text><line x1=\"152\" y1=\"95\" x2=\"208\" y2=\"95\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"208.0,95.0 200.6,98.1 200.6,91.9\" fill=\"var(--amber)\"></polygon><line x1=\"152\" y1=\"185\" x2=\"208\" y2=\"185\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"208.0,185.0 200.6,188.1 200.6,181.9\" fill=\"var(--amber)\"></polygon><text x=\"540\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--phosphor)\">with (session.id)</text><text x=\"440\" y=\"44\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">before</text><text x=\"630\" y=\"44\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">after the sort</text><rect x=\"380\" y=\"60\" width=\"130\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"445\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">19 Oct, 90 min</text><rect x=\"390\" y=\"94\" width=\"110\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"396\" y=\"106\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">read chapter 3</text><rect x=\"380\" y=\"150\" width=\"130\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"445\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">24 Oct, 60 min</text><rect x=\"390\" y=\"184\" width=\"110\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"396\" y=\"196\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\"></text><rect x=\"570\" y=\"60\" width=\"130\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"635\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">24 Oct, 60 min</text><rect x=\"580\" y=\"94\" width=\"110\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"586\" y=\"106\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\"></text><rect x=\"570\" y=\"150\" width=\"130\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"635\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">19 Oct, 90 min</text><rect x=\"580\" y=\"184\" width=\"110\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"586\" y=\"196\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">read chapter 3</text><line x1=\"512\" y1=\"95\" x2=\"568\" y2=\"180\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"568.0,180.0 561.3,175.6 566.5,172.1\" fill=\"var(--phosphor)\"></polygon><line x1=\"512\" y1=\"185\" x2=\"568\" y2=\"100\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"568.0,100.0 566.5,107.9 561.3,104.4\" fill=\"var(--phosphor)\"></polygon><text x=\"180\" y=\"255\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">elements stay; data moves</text><text x=\"540\" y=\"255\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">elements move with their data</text></svg>", "caption": "Without a key the note belongs to a position; with one it belongs to a session."}
```

## What makes a good key

**An id, and nothing else.** The index is the position, which is exactly what changes when the order
does, so `(i)` is the same as no key at all. The item itself, `(session)`, works only while the same
objects are kept, and fails the moment a list is reloaded from the server as new objects with the same
contents. A field like the date or the name is not unique, and the day two sessions share a date, two
elements claim the same key and Svelte stops with an error. The planner's sessions have had an `id` since
lesson 3 gave the data its shape, for this reason.

