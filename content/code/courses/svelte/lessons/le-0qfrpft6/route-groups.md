---
title: Route groups, for pages that share a layout
version: 1
---

**A folder whose name is in brackets, like `(planner)`, groups routes without adding anything to their
address.** `src/routes/(planner)/+page.svelte` is still `/`. What the group adds is a place for a
layout that applies to the pages inside it and to no others. The planner needs exactly that: the
planner's own pages, the week and each course, need the data and the `Planner` in context; the About
page needs neither, and should not wait for a request it does not use.

So the routes become two groups. Move the files:

```
ana@dev:~/planner$ mkdir 'src/routes/(planner)' 'src/routes/(info)'
ana@dev:~/planner$ mv src/routes/about 'src/routes/(info)/about'
ana@dev:~/planner$ mv src/routes/+page.svelte 'src/routes/(planner)/+page.svelte'
ana@dev:~/planner$ mv src/lib/Planner.svelte src/lib/PlannerProvider.svelte
ana@dev:~/planner$ find src/routes -name '*.svelte' | sort
src/routes/(info)/about/+page.svelte
src/routes/(planner)/+page.svelte
src/routes/+layout.svelte
```

The quotes are there because a shell reads parentheses as part of its own syntax. The home page and About are where
they were as far as any address is concerned, and `Planner.svelte` has a new name, because it is about
to have a new job.

## A layout that provides the planner

Lesson 11 made `Planner.svelte` create the planner and put it in context, and render the page's
content as well. In a layout, the content is the pages, so the component keeps only the first half of
the job and renders whatever is inside it. Replace `src/lib/PlannerProvider.svelte`:

```schooling-example
{"language": "html", "file": "src/lib/PlannerProvider.svelte", "parts": [
 {"code": "<script>\n\timport { untrack } from 'svelte';\n\timport { Planner } from '#lib/planner.svelte.js';\n\timport { setPlanner } from '#lib/context.js';\n\n\tlet { data, children } = $props();\n\n\tconst planner = setPlanner(new Planner(untrack(() => data)));", "note": "It creates the planner and sets it in context, exactly as before. Its content is now `children`: the pages, through the layout."},
 {"code": "\tfunction shortcut(event) {\n\t\tif (event.target.closest('input, textarea, select')) return;\n\t\tif (event.key === 'ArrowLeft') planner.move(-7);\n\t\tif (event.key === 'ArrowRight') planner.move(7);\n\t}\n</script>\n\n<svelte:window onkeydown={shortcut} />\n\n{@render children()}", "note": "The week shortcut stays here, since it works on every page of the planner. The title effect has gone: each page sets its own title now."}
]}
```

The group's layout does what the home page used to: it asks for the data, waits, and then puts the
pages inside a provider. Save it as `src/routes/(planner)/+layout.svelte`:

```schooling-example
{"language": "html", "file": "src/routes/(planner)/+layout.svelte", "parts": [
 {"code": "<script>\n\timport { browser } from '$app/environment';\n\timport PlannerProvider from '#lib/PlannerProvider.svelte';\n\n\tlet { children } = $props();\n\n\tfunction load() {\n\t\treturn fetch('/planner.json').then((response) => {\n\t\t\tif (!response.ok) throw new Error(`${response.status} ${response.statusText}`);\n\t\t\treturn response.json();\n\t\t});\n\t}\n\n\t// In the browser, ask for the data. On the server, a promise that never\n\t// settles, so the server's HTML is the loading message.\n\tconst loading = browser ? load() : new Promise(() => {});\n</script>", "note": "The loading code moves here from the home page, unchanged."},
 {"code": "{#await loading}\n\t<p>Loading the planner…</p>\n{:then data}\n\t<PlannerProvider {data}>\n\t\t{@render children()}\n\t</PlannerProvider>\n{:catch error}\n\t<p role=\"alert\">The planner could not be loaded: {error.message}</p>\n{/await}", "note": "Every page of the group renders inside the provider, so every page can get the planner from context."}
]}
```

## The home page, as the week

The home page becomes the week at a glance: the navigation, the courses with their minutes, the totals
and the days. The course's own sessions move to a page of their own in the next section, so the course
list stops selecting and starts linking. Replace `src/lib/CourseList.svelte`:

```schooling-example
{"language": "html", "file": "src/lib/CourseList.svelte", "parts": [
 {"code": "<script>\n\tlet { courses, minutes } = $props();\n</script>\n\n<ul>\n\t{#each courses as c}\n\t\t<li><a href=\"/courses/{c.id}\">{c.name}</a> {minutes[c.id] ?? 0} min</li>\n\t{/each}\n</ul>\n\n<style>\n\tul {\n\t\tlist-style: none;\n\t\tpadding: 0;\n\t}\n\n\tli {\n\t\tdisplay: flex;\n\t\tjustify-content: space-between;\n\t\tmax-width: 20rem;\n\t}\n</style>", "note": "Two props now. The selection lives in the address, `/courses/algebra`, so there is nothing to bind."}
]}
```

and replace `src/routes/(planner)/+page.svelte` with the week:

```schooling-example
{"language": "html", "file": "src/routes/(planner)/+page.svelte", "parts": [
 {"code": "<script>\n\timport { getPlanner } from '#lib/context.js';\n\timport WeekNav from '#lib/WeekNav.svelte';\n\timport CourseList from '#lib/CourseList.svelte';\n\timport WeekTotal from '#lib/WeekTotal.svelte';\n\timport Status from '#lib/Status.svelte';\n\timport Days from '#lib/Days.svelte';\n\n\tconst planner = getPlanner();\n</script>", "note": "The page gets the planner the layout provided. It knows nothing about loading."},
 {"code": "<svelte:head>\n\t<title>{planner.total} min this week · Study planner</title>\n</svelte:head>\n\n<h1>Study planner</h1>\n<p>Left and right arrows move the week.</p>\n<WeekNav week={planner.week} onchange={(next) => (planner.week = next)} />\n<CourseList courses={planner.courses} minutes={planner.byCourse} />\n<WeekTotal minutes={planner.total} />\n<Status />\n<Days />", "note": "The title moves from an effect to `<svelte:head>`, which also works on the server."}
]}
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
      - link "Linear algebra":
        - /url: /courses/algebra
      - text: 150 min
    - listitem:
      - link "Spanish":
        - /url: /courses/spanish
      - text: 30 min
    - listitem:
      - link "Guitar":
        - /url: /courses/guitar
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
```

The week, with three links. They lead to pages that do not exist yet, which is the next section.
