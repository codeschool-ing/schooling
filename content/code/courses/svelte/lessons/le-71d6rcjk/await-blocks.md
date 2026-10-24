---
title: "{#await}: a page that waits for its data"
version: 1
---

**`{#await promise}…{:then value}…{:catch error}…{/await}` shows one thing while a promise is
pending, another when it resolves, and a third if it rejects.** It is the template's way of handling
anything that arrives later, and the most common thing that arrives later is data from the network.
So far the planner has imported its data as a module, built into the JavaScript the browser downloads.
This section moves it to where a real application keeps it, behind an address, and asks for it.

## The data behind an address

Files in `static` are served exactly as they are, so moving the data there gives it an address,
`/planner.json`:

```
ana@dev:~/planner$ git mv src/lib/planner.json static/planner.json
```

The page cannot hold the planner's state any more, because the state is made from data the page does
not have yet. So the planner moves into a component of its own, which receives the data as a prop once
it exists. Save this as `src/lib/Planner.svelte`; it is the page as the previous section left it, with
the changes marked:

```schooling-example
{"language": "html", "file": "src/lib/Planner.svelte", "parts": [
 {"code": "<script>\n\timport { untrack } from 'svelte';\n\timport { mondayOf, addDays, inWeek, format } from '#lib/week.js';\n\timport WeekTotal from '#lib/WeekTotal.svelte';\n\timport WeekNav from '#lib/WeekNav.svelte';\n\timport CourseList from '#lib/CourseList.svelte';\n\timport AddSession from '#lib/AddSession.svelte';\n\timport Panel from '#lib/Panel.svelte';\n\timport List from '#lib/List.svelte';", "note": "The page's script and markup move here almost unchanged. The imports lose `planner.json`, which this component no longer reads, and gain `untrack`."},
 {"code": "\tlet { data } = $props();\n\n\tlet sessions = $state(untrack(() => data.sessions));\n\tlet week = $state(mondayOf(sessions.at(-1).date));\n\tlet selected = $state(untrack(() => data.courses[0].id));", "note": "The data arrives as a prop. The planner edits its own copy of it, taken once; `untrack` says that is intended, and keeps the compiler from warning that only the initial value is read."},
 {"code": "\tlet thisWeek = $derived(sessions.filter((s) => inWeek(s.date, week)));\n\tlet total = $derived(thisWeek.reduce((sum, s) => sum + s.minutes, 0));\n\tlet doneMinutes = $derived(thisWeek.filter((s) => s.done).reduce((sum, s) => sum + s.minutes, 0));\n\tlet byDay = $derived.by(() => {\n\t\tconst minutes = {};\n\t\tfor (const s of thisWeek) minutes[s.date] = (minutes[s.date] ?? 0) + s.minutes;\n\t\treturn minutes;\n\t});\n\tlet byCourse = $derived.by(() => {\n\t\tconst minutes = {};\n\t\tfor (const s of thisWeek) minutes[s.course] = (minutes[s.course] ?? 0) + s.minutes;\n\t\treturn minutes;\n\t});\n\tlet course = $derived(data.courses.find((c) => c.id === selected));\n\tlet ofCourse = $derived(thisWeek.filter((s) => s.course === selected));\n\n\tfunction add({ date, minutes }) {\n\t\tsessions.push({ id: sessions.length + 1, course: selected, date, minutes, done: false });\n\t}\n\tfunction shortcut(event) {\n\t\tif (event.target.closest('input, textarea, select')) return;\n\t\tif (event.key === 'ArrowLeft') week = addDays(week, -7);\n\t\tif (event.key === 'ArrowRight') week = addDays(week, 7);\n\t}\n\n\t$effect(() => {\n\t\tdocument.title = `${total} min this week · Study planner`;\n\t});\n</script>", "note": "Everything else is the page's script as the previous section left it."},
 {"code": "<svelte:window onkeydown={shortcut} />\n\n<p>Left and right arrows move the week.</p>\n<WeekNav {week} onchange={(next) => (week = next)} />\n<CourseList courses={data.courses} minutes={byCourse} bind:selected />\n<WeekTotal minutes={total} />\n{#if total === 0}\n\t<p>Nothing planned this week.</p>\n{:else if doneMinutes === total}\n\t<p>Every session this week is done.</p>\n{:else}\n\t<p>{doneMinutes} of {total} minutes done.</p>\n{/if}\n<ol aria-label=\"Minutes per day\">\n\t{#each { length: 7 }, i}\n\t\t{const day = $derived(addDays(week, i))}\n\t\t<li>{format(day)}: {byDay[day] ?? 0} min</li>\n\t{/each}\n</ol>\n\n<Panel title={course.name}>\n\t<List items={ofCourse}>\n\t\t{#snippet row(session)}\n\t\t\t<label class:done={session.done}>\n\t\t\t\t<input type=\"checkbox\" bind:checked={session.done} />\n\t\t\t\t{format(session.date)}, {session.minutes} min\n\t\t\t</label>\n\t\t{/snippet}\n\t\t{#snippet empty()}\n\t\t\t<p>Nothing planned for {course.name} this week.</p>\n\t\t{/snippet}\n\t</List>\n\t<WeekTotal minutes={byCourse[selected] ?? 0} label=\"for {course.name} this week\" />\n\t<AddSession onadd={add} />\n</Panel>\n\n<style>\n\t.done {\n\t\ttext-decoration: line-through;\n\t}\n</style>", "note": "The markup is the page's, without the `<main>` and the heading, which stay in the page."}
]}
```

## Asking for it

The page's job is now to ask for the data and show the right thing while it waits. A first version:

```html
<!-- src/routes/+page.svelte -->
<script>
	import Planner from '#lib/Planner.svelte';

	function load() {
		return fetch('/planner.json').then((response) => {
			if (!response.ok) throw new Error(`${response.status} ${response.statusText}`);
			return response.json();
		});
	}

	const loading = load();
</script>

<main>
	<h1>Study planner</h1>
	{#await loading}
		<p>Loading the planner…</p>
	{:then data}
		<Planner {data} />
	{:catch error}
		<p role="alert">The planner could not be loaded: {error.message}</p>
	{/await}
</main>

<style>
	main {
		max-width: 40rem;
		margin: 2rem auto;
		font-family: system-ui, sans-serif;
	}
</style>
```

```
ana@dev:~/planner$ look http://localhost:5173/
at /
- heading "500" [level=1]
- paragraph: Internal Error
```

An error page, and the development server's terminal says what went wrong:

```
ana@dev:~/planner$ npm run dev

> planner@0.0.1 dev
> vite dev

8:29:03 PM [vite] (ssr) connected.

  VITE v8.3.5  ready in 565 ms

  ➜  Local:   http://localhost:5173/
  ➜  Network: use --host to expose
SvelteKit error: ssr_fetch_relative_url
Cannot call `fetch` eagerly during server-side rendering with relative URL (`/planner.json`) — put your `fetch` calls inside `onMount` or a `load` function instead
https://svelte.dev/e/kit/ssr_fetch_relative_url
    at load (src/routes/+page.svelte:6:10)
    at eval (src/routes/+page.svelte:12:18)
    at eval (node_modules/svelte/src/internal/server/renderer.js:413:11)
    at Renderer.child (node_modules/svelte/src/internal/server/renderer.js:302:18)
    at Renderer.component (node_modules/svelte/src/internal/server/renderer.js:411:8)
    at _page (src/routes/+page.svelte:3:2)
500 GET /
```

**The script runs on the server too.** Lesson 2 saw `console.log` print in the server's terminal; this
is the same fact with consequences. While rendering the page into HTML, the server ran `load()`, and on
the server `fetch('/planner.json')` has no page for the address to be relative to. SvelteKit refuses
it with an error that names the two proper fixes: a `load` function, which is lesson 13, or doing the
request only in the browser. For now, the second:

```html
<!-- src/routes/+page.svelte -->
<script>
	import { browser } from '$app/env';
	import Planner from '#lib/Planner.svelte';

	function load() {
		return fetch('/planner.json').then((response) => {
			if (!response.ok) throw new Error(`${response.status} ${response.statusText}`);
			return response.json();
		});
	}

	// In the browser, ask for the data. On the server, a promise that never
	// settles, so the server's HTML is the loading message.
	const loading = browser ? load() : new Promise(() => {});
</script>

<main>
	<h1>Study planner</h1>
	{#await loading}
		<p>Loading the planner…</p>
	{:then data}
		<Planner {data} />
	{:catch error}
		<p role="alert">The planner could not be loaded: {error.message}</p>
	{/await}
</main>

<style>
	main {
		max-width: 40rem;
		margin: 2rem auto;
		font-family: system-ui, sans-serif;
	}
</style>
```

`browser` is `true` in the browser and `false` on the server. Look at the page twice, once as the
server sends it and once as a browser shows it:

```
ana@dev:~/planner$ curl -s http://localhost:5173/ | grep -o '<main.*</main>'
<main class="svelte-1uha8ag"><h1 class="svelte-1uha8ag">Study planner</h1> <!--[--><p class="svelte-1uha8ag">Loading the planner…</p><!--]--></main>
```

```
ana@dev:~/planner$ look http://localhost:5173/
at /
title: 225 min this week · Study planner
- main:
  - heading "Study planner" [level=1]
  - paragraph: Left and right arrows move the week.
  - paragraph:
    - button "Previous week"
    - text: Week of 19 Oct 2026
    - button "Next week"
  - list:
    - listitem:
      - button "Linear algebra" [pressed]
      - text: 150 min
    - listitem:
      - button "Spanish"
      - text: 30 min
    - listitem:
      - button "Guitar"
      - text: 45 min
  - paragraph: 225 minutes this week (3 h 45 min)
  - paragraph: 90 of 225 minutes done.
  - list "Minutes per day":
    - listitem: "19 Oct 2026: 90 min"
    - listitem: "20 Oct 2026: 45 min"
    - listitem: "21 Oct 2026: 0 min"
    - listitem: "22 Oct 2026: 30 min"
    - listitem: "23 Oct 2026: 0 min"
    - listitem: "24 Oct 2026: 60 min"
    - listitem: "25 Oct 2026: 0 min"
  - region "Linear algebra":
    - heading "Linear algebra" [level=2]
    - list:
      - listitem:
        - checkbox "19 Oct 2026, 90 min" [checked]
        - text: 19 Oct 2026, 90 min
      - listitem:
        - checkbox "24 Oct 2026, 60 min"
        - text: 24 Oct 2026, 60 min
    - paragraph: 150 minutes for Linear algebra this week (2 h 30 min)
    - text: Date
    - textbox "Date"
    - text: Minutes
    - spinbutton "Minutes": "30"
    - button "Add session"
```

**The HTML the server sends says "Loading the planner…" and nothing else.** The planner appears only
after the browser has run the page's JavaScript, made the request and received the answer. A visitor
on a slow connection sees the loading message first, a search engine that does not run JavaScript sees
only that, and so does anybody with JavaScript off. That is the cost of loading data in the browser,
and the reason lesson 13 moves it to the server, where the first HTML already has the planner in it.

## When the request fails

Change the address in `load()` to `'/planer.json'`, one letter short, and look again:

```
ana@dev:~/planner$ look http://localhost:5173/
at /
- main:
  - heading "Study planner" [level=1]
  - alert: "The planner could not be loaded: 404 Not Found"
```

**The `{:catch}` branch, with the error `load()` threw.** `fetch` itself does not fail on a 404, it
resolves with a response whose `ok` is false, which is why `load()` checks and throws; without that
line, `response.json()` would fail on the error page's HTML with a far less useful message. The
paragraph has `role="alert"`, so a screen reader announces it as soon as it appears instead of waiting
for somebody to find it. Put the address back.
