---
title: Binding a value to a form field
version: 1
---

**`bind:value` connects a form field to a variable in both directions**: the field shows the
variable, and typing in the field changes the variable. Without it, a field needs a `value=` to show
the variable and an `oninput` handler to copy what was typed back, and the two have to agree. With
it, one attribute does both.

The planner's "Add 30 minutes" button was always a placeholder. A session needs a date and a number
of minutes that the student chooses, which is a small form. Save it as `src/lib/AddSession.svelte`:

```schooling-example
{"language": "html", "file": "src/lib/AddSession.svelte", "parts": [
 {"code": "<script>\n\tlet { onadd } = $props();\n\n\tlet date = $state('');\n\tlet minutes = $state(30);\n</script>", "note": "The form's own fields are this component's state. Nobody else needs them until the button is pressed."},
 {"code": "<p>\n\t<label>Date <input type=\"date\" bind:value={date} /></label>", "note": "Each field is inside its `<label>`, which gives it an accessible name: `look` will call them `Date` and `Minutes`."},
 {"code": "\t<label>Minutes <input type=\"number\" min=\"5\" step=\"5\" bind:value={minutes} /></label>", "note": "On a number field, `bind:value` gives a number, not the string the browser holds. `minutes + 15` adds; it does not append."},
 {"code": "\t<button disabled={!date} onclick={() => onadd({ date, minutes })}>Add session</button>\n</p>", "note": "The button is disabled until there is a date, so an empty session cannot be added. The page receives a plain object and decides what to do with it."}
]}
```

The page swaps its button for the form, changes `add` to take what the form sends, and turns each
session's toggle button into a checkbox bound to `session.done`:

```schooling-example
{"language": "html", "file": "src/routes/+page.svelte", "parts": [
 {"code": "<script>\n\timport data from '#lib/planner.json';\n\timport { mondayOf, inWeek, format } from '#lib/week.js';\n\timport WeekTotal from '#lib/WeekTotal.svelte';\n\timport WeekNav from '#lib/WeekNav.svelte';\n\timport CourseList from '#lib/CourseList.svelte';\n\timport AddSession from '#lib/AddSession.svelte';\n\n\tlet sessions = $state(data.sessions);\n\tlet week = $state(mondayOf(sessions.at(-1).date));\n\tlet selected = $state(data.courses[0].id);\n\n\tlet thisWeek = $derived(sessions.filter((s) => inWeek(s.date, week)));\n\tlet total = $derived(thisWeek.reduce((sum, s) => sum + s.minutes, 0));\n\tlet byCourse = $derived.by(() => {\n\t\tconst minutes = {};\n\t\tfor (const s of thisWeek) minutes[s.course] = (minutes[s.course] ?? 0) + s.minutes;\n\t\treturn minutes;\n\t});\n\tlet course = $derived(data.courses.find((c) => c.id === selected));\n\tlet ofCourse = $derived(sessions.filter((s) => s.course === selected));", "note": "`AddSession` joins the imports."},
 {"code": "\tfunction add({ date, minutes }) {\n\t\tsessions.push({ id: sessions.length + 1, course: selected, date, minutes, done: false });\n\t}\n\n\t$effect(() => {\n\t\tdocument.title = `${total} min this week · Study planner`;\n\t});\n</script>\n\n<main>\n\t<h1>Study planner</h1>\n\t<WeekNav {week} onchange={(next) => (week = next)} />\n\t<CourseList courses={data.courses} minutes={byCourse} {selected} onselect={(id) => (selected = id)} />\n\t<WeekTotal minutes={total} />", "note": "`add` receives the date and minutes the form chose. The page still decides the id, the course and that a new session is not done."},
 {"code": "\t<h2>{course.name}</h2>\n\t<ul>\n\t\t{#each ofCourse as session}\n\t\t\t<li>\n\t\t\t\t<label>\n\t\t\t\t\t<input type=\"checkbox\" bind:checked={session.done} />\n\t\t\t\t\t{format(session.date)}, {session.minutes} min\n\t\t\t\t</label>\n\t\t\t</li>\n\t\t{/each}\n\t</ul>\n\t<WeekTotal minutes={byCourse[selected] ?? 0} label=\"for {course.name} this week\" />\n\t<AddSession onadd={add} />\n</main>", "note": "A checkbox bound to `session.done`. Ticking it assigns to the property, through the same proxy as before."}
]}
```

Fill in the form, add the session, and tick the one on the 24th:

```
ana@dev:~/planner$ look http://localhost:5173/ --fill 'Date=2026-10-21' --fill 'Minutes=45' --click 'Add session' --check '24 Oct 2026, 60 min'
-- fill Date=2026-10-21
-- fill Minutes=45
-- click Add session
-- check 24 Oct 2026, 60 min
at /
title: 270 min this week · Study planner
- main:
  - heading "Study planner" [level=1]
  - paragraph:
    - button "Previous week"
    - text: Week of 19 Oct 2026
    - button "Next week"
  - list:
    - listitem:
      - button "Linear algebra" [pressed]
      - text: 195 min
    - listitem:
      - button "Spanish"
      - text: 30 min
    - listitem:
      - button "Guitar"
      - text: 45 min
  - paragraph: 270 minutes this week (4 h 30 min)
  - heading "Linear algebra" [level=2]
  - list:
    - listitem:
      - checkbox "13 Oct 2026, 60 min" [checked]
      - text: 13 Oct 2026, 60 min
    - listitem:
      - checkbox "19 Oct 2026, 90 min" [checked]
      - text: 19 Oct 2026, 90 min
    - listitem:
      - checkbox "24 Oct 2026, 60 min" [checked]
      - text: 24 Oct 2026, 60 min
    - listitem:
      - checkbox "21 Oct 2026, 45 min"
      - text: 21 Oct 2026, 45 min
  - paragraph: 195 minutes for Linear algebra this week (3 h 15 min)
  - paragraph:
    - text: Date
    - textbox "Date": 2026-10-21
    - text: Minutes
    - spinbutton "Minutes": "45"
    - button "Add session"
```

Linear algebra has 195 minutes this week now, the 45 the form sent added to 150, and the session on
the 24th reads `[checked]`. The fields kept what was typed, because nothing cleared them: the form's
state is the form's, and the page only ever received a copy.

## The bindings you will use

| binding | on | the variable holds |
|---|---|---|
| `bind:value` | text, date, `<textarea>`, `<select>` | a string, the field's text |
| `bind:value` | `type="number"`, `type="range"` | a number, or `null` when the field is empty |
| `bind:checked` | `type="checkbox"` | `true` or `false` |
| `bind:group` | several radio buttons or checkboxes sharing one variable | the chosen value, or an array of them |
| `bind:this` | any element | the DOM element itself, once it exists |

**`bind:checked={session.done}` binds to a property of an object in the page's state**, which is
allowed because the page owns that state: the checkbox and the variable live in the same component.
The next section is about what happens when they do not.
