---
title: Children, and the content between the tags
version: 1
---

**A component can receive markup as well as values.** Whatever you write between a component's
opening and closing tags is passed to it as a prop called `children`, and the component decides where
it goes with `{@render children()}`. That is how a component wraps content it did not write: a panel
around a course's sessions, a dialog around a form, a layout around a page.

The planner's course section has grown a heading, a list, a total and a form, and it would read better
as a panel, a bordered region with a title. Save this as `src/lib/Panel.svelte`:

```schooling-example
{"language": "html", "file": "src/lib/Panel.svelte", "parts": [
 {"code": "<script>\n\tlet { title, children } = $props();\n\tconst id = $props.id();\n</script>", "note": "`children` is the content between the tags. `$props.id()` gives an id unique to this panel, the same on the server and in the browser."},
 {"code": "<section aria-labelledby={id}>\n\t<h2 {id}>{title}</h2>\n\t{@render children()}\n</section>\n\n<style>\n\tsection {\n\t\tborder: 1px solid #767676;\n\t\tborder-radius: 0.5rem;\n\t\tpadding: 0 1rem 1rem;\n\t\tmargin: 1rem 0;\n\t}\n</style>", "note": "`aria-labelledby` names the region by its heading, so a screen reader announces \"Linear algebra, region\". `{@render children()}` is where the content goes."}
]}
```

In the page, the heading moves into the panel's `title`, and everything that was under it goes between
the tags:

```schooling-example
{"language": "html", "file": "src/routes/+page.svelte", "parts": [
 {"code": "<script>\n\timport data from '#lib/planner.json';\n\timport { mondayOf, inWeek, format } from '#lib/week.js';\n\timport WeekTotal from '#lib/WeekTotal.svelte';\n\timport WeekNav from '#lib/WeekNav.svelte';\n\timport CourseList from '#lib/CourseList.svelte';\n\timport AddSession from '#lib/AddSession.svelte';\n\timport Panel from '#lib/Panel.svelte';\n\n\tlet sessions = $state(data.sessions);\n\tlet week = $state(mondayOf(sessions.at(-1).date));\n\tlet selected = $state(data.courses[0].id);\n\n\tlet thisWeek = $derived(sessions.filter((s) => inWeek(s.date, week)));\n\tlet total = $derived(thisWeek.reduce((sum, s) => sum + s.minutes, 0));\n\tlet byCourse = $derived.by(() => {\n\t\tconst minutes = {};\n\t\tfor (const s of thisWeek) minutes[s.course] = (minutes[s.course] ?? 0) + s.minutes;\n\t\treturn minutes;\n\t});\n\tlet course = $derived(data.courses.find((c) => c.id === selected));\n\tlet ofCourse = $derived(sessions.filter((s) => s.course === selected));\n\n\tfunction add({ date, minutes }) {\n\t\tsessions.push({ id: sessions.length + 1, course: selected, date, minutes, done: false });\n\t}\n\n\t$effect(() => {\n\t\tdocument.title = `${total} min this week · Study planner`;\n\t});\n</script>\n\n<main>\n\t<h1>Study planner</h1>\n\t<WeekNav {week} onchange={(next) => (week = next)} />\n\t<CourseList courses={data.courses} minutes={byCourse} bind:selected />\n\t<WeekTotal minutes={total} />", "note": "`Panel` joins the imports."},
 {"code": "\t<Panel title={course.name}>\n\t\t<ul>\n\t\t\t{#each ofCourse as session}\n\t\t\t\t<li>\n\t\t\t\t\t<label class:done={session.done}>\n\t\t\t\t\t\t<input type=\"checkbox\" bind:checked={session.done} />\n\t\t\t\t\t\t{format(session.date)}, {session.minutes} min\n\t\t\t\t\t</label>\n\t\t\t\t</li>\n\t\t\t{/each}\n\t\t</ul>\n\t\t<WeekTotal minutes={byCourse[selected] ?? 0} label=\"for {course.name} this week\" />\n\t\t<AddSession onadd={add} />\n\t</Panel>\n</main>\n\n<style>\n\tmain {\n\t\tmax-width: 40rem;\n\t\tmargin: 2rem auto;\n\t\tfont-family: system-ui, sans-serif;\n\t}\n\n\t.done {\n\t\ttext-decoration: line-through;\n\t}\n</style>", "note": "Everything between `<Panel>` and `</Panel>` is the panel's `children`. It is still the page's markup: it reads the page's variables, and the page's styles apply to it."}
]}
```

```
ana@dev:~/planner$ look http://localhost:5173/ --click 'Spanish'
-- click Spanish
at /
title: 225 min this week · Study planner
- main:
  - heading "Study planner" [level=1]
  - paragraph:
    - button "Previous week"
    - text: Week of 19 Oct 2026
    - button "Next week"
  - list:
    - listitem:
      - button "Linear algebra"
      - text: 150 min
    - listitem:
      - button "Spanish" [pressed]
      - text: 30 min
    - listitem:
      - button "Guitar"
      - text: 45 min
  - paragraph: 225 minutes this week (3 h 45 min)
  - region "Spanish":
    - heading "Spanish" [level=2]
    - list:
      - listitem:
        - checkbox "15 Oct 2026, 30 min" [checked]
        - text: 15 Oct 2026, 30 min
      - listitem:
        - checkbox "22 Oct 2026, 30 min"
        - text: 22 Oct 2026, 30 min
    - paragraph: 30 minutes for Spanish this week (0 h 30 min)
    - paragraph:
      - text: Date
      - textbox "Date"
      - text: Minutes
      - spinbutton "Minutes": "30"
      - button "Add session" [disabled]
```

The course section is a `region` now, named "Spanish" by its heading, and everything inside it is
indented under it. That is the accessible version of a box drawn round something: a screen reader
user can jump from region to region the way a sighted user scans the boxes on a page.

## Whose markup is it

**The content passed as `children` still belongs to the component that wrote it.** The list, the
checkbox bound to `session.done` and the `.done` class are all the page's: they read the page's
variables, and the page's scoped style applies to them, even though `Panel` decides where they appear.
`Panel` knows nothing about sessions; it only knows it has been given something to render.

That is the property that makes wrapping components reusable. A panel that had to know what was in it
would need a prop for every kind of content; a panel that renders `children` works for anything.
