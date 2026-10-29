---
title: Where to cut a page into components
version: 1
---

**A component is a file, and a file is worth making when a piece of the page has a name, a job of its
own, and a small number of things it needs to know.** The planner's page has three such pieces after
lesson 4: the week navigation, already `WeekNav`; the list of courses with their minutes; and the
selected course's sessions with the button that adds one. This lesson takes out the second and the
third, and the way each one talks to the page is what the lesson is about.

## What a good boundary looks like

The test is the list of props. **If a piece needs three or four values to do its job, it is a good
component. If it needs ten, or needs to reach into the page's variables, the cut is in the wrong
place.** The course list needs the courses, the minutes for each, which one is selected, and a way to
say that a different one was chosen. That is four, and none of them is the page's business beyond
handing it over.

Save this as `src/lib/CourseList.svelte`:

```schooling-example
{"language": "html", "file": "src/lib/CourseList.svelte", "parts": [
 {"code": "<script>\n\tlet { courses, minutes, selected, onselect } = $props();\n</script>", "note": "Four props. `minutes` is the page's `byCourse`, an object from course id to minutes; `onselect` is a function, like `WeekNav`'s `onchange`."},
 {"code": "<ul>\n\t{#each courses as c}\n\t\t<li>\n\t\t\t<button aria-pressed={c.id === selected} onclick={() => onselect(c.id)}>{c.name}</button>\n\t\t\t{minutes[c.id] ?? 0} min\n\t\t</li>\n\t{/each}\n</ul>", "note": "The markup is the page's, moved. `c.id === selected` compares two strings, so it works whatever the page's state is wrapped in."}
]}
```

And the page uses it, in place of the list it had:

```schooling-example
{"language": "html", "file": "src/routes/+page.svelte", "parts": [
 {"code": "<script>\n\timport data from '#lib/planner.json';\n\timport { mondayOf, inWeek, format } from '#lib/week.js';\n\timport WeekTotal from '#lib/WeekTotal.svelte';\n\timport WeekNav from '#lib/WeekNav.svelte';\n\timport CourseList from '#lib/CourseList.svelte';\n\n\tlet sessions = $state(data.sessions);\n\tlet week = $state(mondayOf(sessions.at(-1).date));\n\tlet selected = $state(data.courses[0].id);\n\n\tlet thisWeek = $derived(sessions.filter((s) => inWeek(s.date, week)));\n\tlet total = $derived(thisWeek.reduce((sum, s) => sum + s.minutes, 0));\n\tlet byCourse = $derived.by(() => {\n\t\tconst minutes = {};\n\t\tfor (const s of thisWeek) minutes[s.course] = (minutes[s.course] ?? 0) + s.minutes;\n\t\treturn minutes;\n\t});\n\tlet course = $derived(data.courses.find((c) => c.id === selected));\n\tlet ofCourse = $derived(sessions.filter((s) => s.course === selected));\n\n\tfunction add() {\n\t\tsessions.push({ id: sessions.length + 1, course: selected, date: week, minutes: 30, done: false });\n\t}\n\n\t$effect(() => {\n\t\tdocument.title = `${total} min this week · Study planner`;\n\t});\n</script>", "note": "`addDays` and `format` are no longer used in the page's script, so they leave the import; `CourseList` joins."},
 {"code": "<main>\n\t<h1>Study planner</h1>\n\t<WeekNav {week} onchange={(next) => (week = next)} />\n\t<CourseList courses={data.courses} minutes={byCourse} {selected} onselect={(id) => (selected = id)} />\n\t<WeekTotal minutes={total} />\n\n\t<h2>{course.name}</h2>\n\t<ul>\n\t\t{#each ofCourse as session}\n\t\t\t<li>\n\t\t\t\t<button aria-pressed={session.done} onclick={() => (session.done = !session.done)}>\n\t\t\t\t\t{format(session.date)}, {session.minutes} min\n\t\t\t\t</button>\n\t\t\t</li>\n\t\t{/each}\n\t</ul>\n\t<WeekTotal minutes={byCourse[selected] ?? 0} label=\"for {course.name} this week\" />\n\t<button onclick={add}>Add 30 minutes on {format(week)}</button>\n</main>", "note": "One line where there were nine. The page still owns `selected`; the list only reports a choice."}
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
  - heading "Spanish" [level=2]
  - list:
    - listitem:
      - button "15 Oct 2026, 30 min" [pressed]
    - listitem:
      - button "22 Oct 2026, 30 min"
  - paragraph: 30 minutes for Spanish this week (0 h 30 min)
  - button "Add 30 minutes on 19 Oct 2026"
```

Nothing a visitor sees changed, which is the point of a refactoring. What changed is that the page's
markup now reads as a list of named parts, and `CourseList` can be read, and later tested, without
the rest.

## Data down, choices up

Every component in the planner now follows the same shape. **Values travel down as props, and a child
that wants something to change calls a function the parent gave it.** `WeekNav` calls `onchange`,
`CourseList` calls `onselect`, and in both cases the page decides what happens. Neither child can put
the page in a state the page did not agree to, and when something is wrong you know which file to
open: the one that owns the state.

That shape is the default, and two-way binding is the exception the rest of this lesson is about. It
is a good exception: for a form field, or for a component whose whole job is to edit one value,
writing the callback every time is ceremony. The sections after the next show where binding pays and
where it does damage.
