---
title: Styles that stay in their component
version: 1
---

**A `<style>` block in a component applies to that component's markup and nowhere else.** The compiler
gives each component a class of its own, adds it to every element the component writes, and rewrites
each selector to require it. A rule for `ul` in `CourseList` styles the course list and leaves the
session list, two components away, untouched. That makes CSS safe to write without a naming
convention, which is most of what naming conventions were for.

Give `CourseList` a style. The selected course is marked by `aria-pressed`, so the rule selects on that
attribute: the visual state and the state a screen reader announces are the same attribute, and cannot
disagree.

```schooling-example
{"language": "html", "file": "src/lib/CourseList.svelte", "parts": [
 {"code": "<script>\n\tlet { courses, minutes, selected = $bindable() } = $props();\n</script>\n\n<ul>\n\t{#each courses as c}\n\t\t<li>\n\t\t\t<button aria-pressed={c.id === selected} onclick={() => (selected = c.id)}>{c.name}</button>\n\t\t\t{minutes[c.id] ?? 0} min\n\t\t</li>\n\t{/each}\n</ul>"},
 {"code": "<style>\n\tul {\n\t\tlist-style: none;\n\t\tpadding: 0;\n\t}\n\n\tli {\n\t\tdisplay: flex;\n\t\tjustify-content: space-between;\n\t\tmax-width: 20rem;\n\t}", "note": "These selectors only match elements this component wrote, so `ul` here is not every `ul` on the page."},
 {"code": "\tbutton[aria-pressed='true'] {\n\t\tfont-weight: bold;\n\t\ttext-decoration: underline;\n\t}\n</style>", "note": "Styling by the ARIA attribute keeps what is seen and what is announced in step."}
]}
```

And give the page two: a readable column, and a line through a session that is done. `class:done=` adds
the class `done` to the label when the expression is true and removes it when it is false:

```schooling-example
{"language": "html", "file": "src/routes/+page.svelte", "parts": [
 {"code": "<script>\n\timport data from '#lib/planner.json';\n\timport { mondayOf, inWeek, format } from '#lib/week.js';\n\timport WeekTotal from '#lib/WeekTotal.svelte';\n\timport WeekNav from '#lib/WeekNav.svelte';\n\timport CourseList from '#lib/CourseList.svelte';\n\timport AddSession from '#lib/AddSession.svelte';\n\n\tlet sessions = $state(data.sessions);\n\tlet week = $state(mondayOf(sessions.at(-1).date));\n\tlet selected = $state(data.courses[0].id);\n\n\tlet thisWeek = $derived(sessions.filter((s) => inWeek(s.date, week)));\n\tlet total = $derived(thisWeek.reduce((sum, s) => sum + s.minutes, 0));\n\tlet byCourse = $derived.by(() => {\n\t\tconst minutes = {};\n\t\tfor (const s of thisWeek) minutes[s.course] = (minutes[s.course] ?? 0) + s.minutes;\n\t\treturn minutes;\n\t});\n\tlet course = $derived(data.courses.find((c) => c.id === selected));\n\tlet ofCourse = $derived(sessions.filter((s) => s.course === selected));\n\n\tfunction add({ date, minutes }) {\n\t\tsessions.push({ id: sessions.length + 1, course: selected, date, minutes, done: false });\n\t}\n\n\t$effect(() => {\n\t\tdocument.title = `${total} min this week · Study planner`;\n\t});\n</script>\n\n<main>\n\t<h1>Study planner</h1>\n\t<WeekNav {week} onchange={(next) => (week = next)} />\n\t<CourseList courses={data.courses} minutes={byCourse} bind:selected />\n\t<WeekTotal minutes={total} />\n\n\t<h2>{course.name}</h2>\n\t<ul>\n\t\t{#each ofCourse as session}\n\t\t\t<li>"},
 {"code": "\t\t\t\t<label class:done={session.done}>\n\t\t\t\t\t<input type=\"checkbox\" bind:checked={session.done} />\n\t\t\t\t\t{format(session.date)}, {session.minutes} min\n\t\t\t\t</label>\n\t\t\t</li>\n\t\t{/each}\n\t</ul>\n\t<WeekTotal minutes={byCourse[selected] ?? 0} label=\"for {course.name} this week\" />\n\t<AddSession onadd={add} />\n</main>", "note": "`class:done` is a directive: the class is on the label exactly while `session.done` is true."},
 {"code": "<style>\n\tmain {\n\t\tmax-width: 40rem;\n\t\tmargin: 2rem auto;\n\t\tfont-family: system-ui, sans-serif;\n\t}\n\n\t.done {\n\t\ttext-decoration: line-through;\n\t}\n</style>", "note": "A line through is not the only signal: the checkbox still says `checked`, so the state does not depend on seeing the style."}
]}
```

## What the compiler did with them

Ask the development server for the page and pick out the classes it wrote:

```
ana@dev:~/planner$ curl -s http://localhost:5173/ | grep -o 'class="[^"]*"' | sort | uniq -c
      2 class="svelte-1uha8ag done"
     11 class="svelte-1uha8ag"
      7 class="svelte-it4bum"
```

Every element of the page carries one generated class, and every element of `CourseList` another.
The sessions on the 13th and 19th, which are done, also carry `done`. The generated names are a hash
of each component's styles, so they stay the same until the styles change; you never write them, and
you should never select on them.

## A rule that matches nothing

The compiler also knows which elements a component can produce, so it can tell when a selector will
never match. Add a rule for `.selected`, say `.selected { font-style: italic; }`, to `CourseList`'s style, a class nothing in its markup uses,
and look at the development server's terminal:

```
ana@dev:~/planner$ npm run dev

> planner@0.0.1 dev
> vite dev

8:03:17 PM [vite] (ssr) connected.

  VITE v8.3.5  ready in 560 ms

  ➜  Local:   http://localhost:5173/
  ➜  Network: use --host to expose
8:03:18 PM [vite-plugin-svelte] src/lib/CourseList.svelte:29:1 Unused CSS selector ".selected"
https://svelte.dev/e/css_unused_selector
200 GET /
8:03:19 PM [vite-plugin-svelte] src/lib/CourseList.svelte:29:1 Unused CSS selector ".selected"
https://svelte.dev/e/css_unused_selector
```

**`css_unused_selector` is a warning about dead CSS**, and the compiler removes the rule from what it
ships. In a stylesheet shared by a whole site, a dead rule stays for years because nobody can prove
it is unused; here the proof is free. Take the rule out again.

When you do need a selector to reach outside the component, `:global(...)` marks it as meant to,
and lesson 12 uses it once, in the layout, for the whole application's base styles. And a `class` attribute can also be
given an object or an array, `class={{ done: session.done }}`, which is the same as `class:done` and
easier to read when there are several.
