---
title: A route with a parameter
version: 1
---

**A folder whose name is in square brackets is a parameter**: `src/routes/(planner)/courses/[id]/+page.svelte`
answers `/courses/algebra`, `/courses/spanish` and `/courses/anything`, and gives the page the part of the
address that matched, as `params.id`. One file makes a page for every course, including the ones nobody
has created yet.

## The planner, without a selection

Since lesson 3 the planner has kept a `selected` course in its state, because the page showed one course
at a time. With a page per course, the address says which course it is, and a selected course in the
state would be a second answer to the same question, one that could disagree with the first. So the
class loses `selected` and the two values derived from it, and gains two methods that take the course as
an argument. Replace `src/lib/planner.svelte.js`:

```schooling-example
{"language": "javascript", "file": "src/lib/planner.svelte.js", "parts": [
 {"code": "// planner.svelte.js: the planner's state and its rules, outside any component.\nimport { mondayOf, addDays, inWeek } from '#lib/week.js';\n\nexport class Planner {\n\tcourses;\n\tsessions = $state([]);\n\tweek = $state('');\n\n\tthisWeek = $derived(this.sessions.filter((s) => inWeek(s.date, this.week)));\n\ttotal = $derived(minutesOf(this.thisWeek));\n\tdoneMinutes = $derived(minutesOf(this.thisWeek.filter((s) => s.done)));\n\tbyCourse = $derived(totalsBy(this.thisWeek, 'course'));\n\tbyDay = $derived(totalsBy(this.thisWeek, 'date'));\n\n\tconstructor(data) {\n\t\tthis.courses = data.courses;\n\t\tthis.sessions = data.sessions;\n\t\tthis.week = mondayOf(data.sessions.at(-1).date);\n\t}", "note": "Two fields of state now: the sessions and the week. Which course is being looked at belongs to the address."},
 {"code": "\tcourse(id) {\n\t\treturn this.courses.find((c) => c.id === id);\n\t}\n\n\tsessionsFor(id) {\n\t\treturn this.thisWeek.filter((s) => s.course === id).toSorted((a, b) => (a.date < b.date ? -1 : 1));\n\t}", "note": "Methods that read state are reactive when called from a `$derived` or the markup: what they read inside is tracked like any read."},
 {"code": "\tadd({ course, date, minutes }) {\n\t\tthis.sessions.push({ id: this.sessions.length + 1, course, date, minutes, done: false });\n\t}\n\n\tmove(days) {\n\t\tthis.week = addDays(this.week, days);\n\t}\n}\n\nfunction minutesOf(sessions) {\n\treturn sessions.reduce((sum, s) => sum + s.minutes, 0);\n}\n\nfunction totalsBy(sessions, field) {\n\tconst minutes = {};\n\tfor (const s of sessions) minutes[s[field]] = (minutes[s[field]] ?? 0) + s.minutes;\n\treturn minutes;\n}", "note": "`add` now takes the course with the rest of the session, from whichever page is adding it."}
]}
```

## The course page

Save this as `src/routes/(planner)/courses/[id]/+page.svelte`. It is lesson 6's panel, promoted to a
page: the course's sessions this week, its total and the form, with the week navigation at the top so
the student can move through weeks without going back:

```schooling-example
{"language": "html", "file": "src/routes/(planner)/courses/[id]/+page.svelte", "parts": [
 {"code": "<script>\n\timport { format } from '#lib/week.js';\n\timport { getPlanner } from '#lib/context.js';\n\timport WeekNav from '#lib/WeekNav.svelte';\n\timport WeekTotal from '#lib/WeekTotal.svelte';\n\timport List from '#lib/List.svelte';\n\timport AddSession from '#lib/AddSession.svelte';\n\n\tlet { params } = $props();\n\n\tconst planner = getPlanner();", "note": "A page receives the route's parameters as the `params` prop. `params.id` is the part of the address in place of `[id]`."},
 {"code": "\tlet course = $derived(planner.course(params.id));\n\tlet sessions = $derived(planner.sessionsFor(params.id));\n</script>\n\n<svelte:head>\n\t<title>{course?.name ?? 'No such course'} · Study planner</title>\n</svelte:head>", "note": "Derived from the parameter, so following a link from one course to another updates the page without recreating it."},
 {"code": "{#if course}\n\t<h1>{course.name}</h1>\n\t<WeekNav week={planner.week} onchange={(next) => (planner.week = next)} />\n\t<List items={sessions}>\n\t\t{#snippet row(session)}\n\t\t\t<label class:done={session.done}>\n\t\t\t\t<input type=\"checkbox\" bind:checked={session.done} />\n\t\t\t\t{format(session.date)}, {session.minutes} min\n\t\t\t</label>\n\t\t{/snippet}\n\t\t{#snippet empty()}\n\t\t\t<p>Nothing planned for {course.name} this week.</p>\n\t\t{/snippet}\n\t</List>\n\t<WeekTotal minutes={planner.byCourse[course.id] ?? 0} label=\"for {course.name} this week\" />\n\t{#key planner.week}\n\t\t<AddSession onadd={(session) => planner.add({ ...session, course: course.id })} />\n\t{/key}\n{:else}\n\t<h1>No such course</h1>\n\t<p>There is no course called “{params.id}”. <a href=\"/\">Back to the planner</a></p>\n{/if}\n\n<style>\n\t.done {\n\t\ttext-decoration: line-through;\n\t}\n</style>", "note": "An address can name a course that does not exist. The page says so, rather than failing on `course.name`."}
]}
```

From the week, follow a course's link:

```
ana@dev:~/planner$ look http://localhost:5173/ --click 'Spanish'
-- click Spanish
at /courses/spanish
title: Spanish · Study planner
- main:
  - heading "Spanish" [level=1]
  - paragraph:
    - button "Previous week"
    - text: Week of 19 Oct 2026
    - button "Next week"
  - list:
    - listitem:
      - checkbox "22 Oct 2026, 30 min"
      - text: 22 Oct 2026, 30 min
  - paragraph: 30 minutes for Spanish this week (0 h 30 min)
  - text: Date
  - textbox "Date"
  - text: Minutes
  - spinbutton "Minutes": "30"
  - button "Add session"
```

`at /courses/spanish`, with Spanish's one session this week. **The week came with it**: the planner
lives in the `(planner)` layout, which stayed while the page inside it changed, so the planner, the week
and every session added are the same on both pages. Move to the week before, add a session, go back to
the week page, and it is all there:

```
ana@dev:~/planner$ look http://localhost:5173/courses/guitar --click 'Previous week' --fill 'Date=2026-10-14' --press Enter --click 'Study planner'
-- click Previous week
-- fill Date=2026-10-14
-- press Enter
-- click Study planner
at /
title: 120 min this week · Study planner
- main:
  - heading "Study planner" [level=1]
  - paragraph: Left and right arrows move the week.
  - paragraph:
    - button "Previous week"
    - text: Week of 12 Oct 2026
    - button "Next week"
  - list:
    - listitem:
      - link "Linear algebra":
        - /url: /courses/algebra
      - text: 60 min
    - listitem:
      - link "Spanish":
        - /url: /courses/spanish
      - text: 30 min
    - listitem:
      - link "Guitar":
        - /url: /courses/guitar
      - text: 30 min
  - paragraph: 120 minutes this week (2 h 0 min)
  - paragraph: 90 of 120 minutes done.
  - list "Minutes per day":
    - listitem: "12 Oct 2026: 0 min"
    - listitem: "13 Oct 2026: 60 min"
    - listitem: "14 Oct 2026: 30 min"
    - listitem: "15 Oct 2026: 30 min"
    - listitem: "16 Oct 2026: 0 min"
    - listitem: "17 Oct 2026: 0 min"
    - listitem: "18 Oct 2026: 0 min"
```

Thirty minutes of guitar on the 14th, added on the course page, counted on the week page, with the week
of 12 October still showing. And an address with a course nobody planned:

```
ana@dev:~/planner$ look http://localhost:5173/courses/piano
at /courses/piano
title: No such course · Study planner
- main:
  - heading "No such course" [level=1]
  - paragraph:
    - text: There is no course called “piano”.
    - link "Back to the planner":
      - /url: /
```

`Panel.svelte` has nothing to do any more: the course page is the panel now. It can stay in `src/lib`,
or be deleted with `git rm src/lib/Panel.svelte`; nothing imports it.
