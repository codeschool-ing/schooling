---
title: The keyboard, and the elements that answer it
version: 1
---

**Everything a mouse can do in the planner, a keyboard must be able to do as well**, and most of that
comes free from choosing the right element. A `<button>` is focusable with Tab and pressed with Enter
or Space; a checkbox is toggled with Space; a form is submitted with Enter. The planner has used those
elements from the start, so it was operable from the keyboard before this section existed.

## The compiler checks the wrong element

Try the shortcut everybody takes once: make the course's list item itself clickable, rather than the
button inside it. In `CourseList.svelte`, the line becomes:

```html
<li onclick={() => (selected = c.id)}>{c.name} {minutes[c.id] ?? 0} min</li>
```

and the terminal running `npm run dev` answers:

```
ana@dev:~/planner$ npm run dev

> planner@0.0.1 dev
> vite dev

8:19:54 PM [vite] (ssr) connected.

  VITE v8.3.5  ready in 518 ms

  ➜  Local:   http://localhost:5173/
  ➜  Network: use --host to expose
8:19:56 PM [vite-plugin-svelte] src/lib/CourseList.svelte:7:2 Visible, non-interactive element `<li>` with a click event must be accompanied by a keyboard event handler. Consider whether an interactive element such as `<button type="button">` or `<a>` might be more appropriate
https://svelte.dev/e/a11y_click_events_have_key_events
8:19:56 PM [vite-plugin-svelte] src/lib/CourseList.svelte:7:2 Non-interactive element `<li>` should not be assigned mouse or keyboard event listeners
https://svelte.dev/e/a11y_no_noninteractive_element_interactions
8:19:56 PM [vite-plugin-svelte] src/lib/CourseList.svelte:21:1 Unused CSS selector "button[aria-pressed='true']"
https://svelte.dev/e/css_unused_selector
200 GET /
8:19:57 PM [vite-plugin-svelte] src/lib/CourseList.svelte:7:2 Visible, non-interactive element `<li>` with a click event must be accompanied by a keyboard event handler. Consider whether an interactive element such as `<button type="button">` or `<a>` might be more appropriate
https://svelte.dev/e/a11y_click_events_have_key_events
8:19:57 PM [vite-plugin-svelte] src/lib/CourseList.svelte:7:2 Non-interactive element `<li>` should not be assigned mouse or keyboard event listeners
https://svelte.dev/e/a11y_no_noninteractive_element_interactions
8:19:57 PM [vite-plugin-svelte] src/lib/CourseList.svelte:21:1 Unused CSS selector "button[aria-pressed='true']"
https://svelte.dev/e/css_unused_selector
```

**Two accessibility warnings, from the compiler, about one line**, and a third about the style, whose
`button[aria-pressed='true']` rule now matches nothing because the button is gone. `a11y_click_events_have_key_events`
says that a click handler on an element with no keyboard handler is a control only a mouse can use.
`a11y_no_noninteractive_element_interactions` says that an `<li>` is not something assistive
technology treats as interactive at all, so a screen reader will not announce it as a control. The
fix the compiler is steering you towards is the one the planner already had: a `<button>` inside the
`<li>`. Put the line back.

The compiler can only check what it can see in one file, so these warnings are a floor rather than a
guarantee. Lesson 19 runs axe over the rendered pages, which sees the whole page as a browser does.

## A shortcut for the week

Moving through weeks is the thing a student does most, and two buttons several Tab presses away are
slow. **A shortcut on the window** answers wherever focus is. `<svelte:window>` is a special element
that puts attributes on the browser's `window`, and Svelte removes the listener when the component
goes away. Add it to the page, just under the script:

```schooling-example
{"language": "html", "file": "src/routes/+page.svelte", "parts": [
 {"code": "<script>\n\timport data from '#lib/planner.json';\n\timport { mondayOf, addDays, inWeek, format } from '#lib/week.js';\n\timport WeekTotal from '#lib/WeekTotal.svelte';\n\timport WeekNav from '#lib/WeekNav.svelte';\n\timport CourseList from '#lib/CourseList.svelte';\n\timport AddSession from '#lib/AddSession.svelte';\n\timport Panel from '#lib/Panel.svelte';\n\timport List from '#lib/List.svelte';\n\n\tlet sessions = $state(data.sessions);\n\tlet week = $state(mondayOf(sessions.at(-1).date));\n\tlet selected = $state(data.courses[0].id);\n\n\tlet thisWeek = $derived(sessions.filter((s) => inWeek(s.date, week)));\n\tlet total = $derived(thisWeek.reduce((sum, s) => sum + s.minutes, 0));\n\tlet byCourse = $derived.by(() => {\n\t\tconst minutes = {};\n\t\tfor (const s of thisWeek) minutes[s.course] = (minutes[s.course] ?? 0) + s.minutes;\n\t\treturn minutes;\n\t});\n\tlet course = $derived(data.courses.find((c) => c.id === selected));\n\tlet ofCourse = $derived(thisWeek.filter((s) => s.course === selected));\n\n\tfunction add({ date, minutes }) {\n\t\tsessions.push({ id: sessions.length + 1, course: selected, date, minutes, done: false });\n\t}"},
 {"code": "\tfunction shortcut(event) {\n\t\tif (event.target.closest('input, textarea, select')) return;\n\t\tif (event.key === 'ArrowLeft') week = addDays(week, -7);\n\t\tif (event.key === 'ArrowRight') week = addDays(week, 7);\n\t}\n\n\t$effect(() => {\n\t\tdocument.title = `${total} min this week · Study planner`;\n\t});\n</script>", "note": "Arrow keys move the week, except while the student is typing in a field, where they move the cursor."},
 {"code": "<svelte:window onkeydown={shortcut} />\n\n<main>\n\t<h1>Study planner</h1>", "note": "`onkeydown` on `<svelte:window>` listens on the whole window. It must be at the top level of the component, outside any element."},
 {"code": "\t<p>Left and right arrows move the week.</p>\n\t<WeekNav {week} onchange={(next) => (week = next)} />\n\t<CourseList courses={data.courses} minutes={byCourse} bind:selected />\n\t<WeekTotal minutes={total} />\n\n\t<Panel title={course.name}>\n\t\t<List items={ofCourse}>\n\t\t\t{#snippet row(session)}\n\t\t\t\t<label class:done={session.done}>\n\t\t\t\t\t<input type=\"checkbox\" bind:checked={session.done} />\n\t\t\t\t\t{format(session.date)}, {session.minutes} min\n\t\t\t\t</label>\n\t\t\t{/snippet}\n\t\t\t{#snippet empty()}\n\t\t\t\t<p>Nothing planned for {course.name} this week.</p>\n\t\t\t{/snippet}\n\t\t</List>\n\t\t<WeekTotal minutes={byCourse[selected] ?? 0} label=\"for {course.name} this week\" />\n\t\t<AddSession onadd={add} />\n\t</Panel>\n</main>\n\n<style>\n\tmain {\n\t\tmax-width: 40rem;\n\t\tmargin: 2rem auto;\n\t\tfont-family: system-ui, sans-serif;\n\t}\n\n\t.done {\n\t\ttext-decoration: line-through;\n\t}\n</style>", "note": "A shortcut nobody knows about helps nobody. The hint is visible text, so every student, and every screen reader, gets it."}
]}
```

```
ana@dev:~/planner$ look http://localhost:5173/ --press ArrowLeft
-- press ArrowLeft
at /
title: 90 min this week · Study planner
- main:
  - heading "Study planner" [level=1]
  - paragraph: Left and right arrows move the week.
  - paragraph:
    - button "Previous week"
    - text: Week of 12 Oct 2026
    - button "Next week"
  - list:
    - listitem:
      - button "Linear algebra" [pressed]
      - text: 60 min
    - listitem:
      - button "Spanish"
      - text: 30 min
    - listitem:
      - button "Guitar"
      - text: 0 min
  - paragraph: 90 minutes this week (1 h 30 min)
  - region "Linear algebra":
    - heading "Linear algebra" [level=2]
    - list:
      - listitem:
        - checkbox "13 Oct 2026, 60 min" [checked]
        - text: 13 Oct 2026, 60 min
    - paragraph: 60 minutes for Linear algebra this week (1 h 0 min)
    - text: Date
    - textbox "Date"
    - text: Minutes
    - spinbutton "Minutes": "30"
    - button "Add session"
```

And the guard, with the focus in the minutes field, where the arrow keys belong to the field:

```
ana@dev:~/planner$ look http://localhost:5173/ --fill 'Minutes=45' --press ArrowLeft
-- fill Minutes=45
-- press ArrowLeft
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
    - spinbutton "Minutes": "45"
    - button "Add session"
```

The week did not move. **A shortcut that steals a key from a text field is a bug**, and the
`closest(...)` check is what prevents it. The arrows are a safe choice for a second reason: they are not
character keys, so they cannot fire by accident while somebody dictates or types into a field that the
check missed. WCAG 2.2 asks that shortcuts made of single letters can be turned off or remapped, and
choosing keys that are not letters keeps the planner out of that requirement altogether.
