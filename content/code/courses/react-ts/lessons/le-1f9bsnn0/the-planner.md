---
title: The app this course builds
version: 1
---

**The course builds one app, a study planner, and grows it lesson by lesson.** A student keeps a
list of the courses they are taking, opens one, adds study sessions to it with a date and a
duration, ticks them off when they are done, and sees how much of the week's plan is finished. It is
small enough that every line of it is shown in a lesson, and it needs everything a real app needs:
a list, a form, data from a server, a second screen with its own address, and a number computed
from all of it.

**`angular`, `vue` and `svelte` build the same app**, with the same screens and the same data, and
lesson 24 opens their versions beside yours. That is why the screens below are fixed now, before any
of it is written: what changes between the four courses is the code, and nothing a user would see.

## Two screens

```schooling-figure
{"svg": "<svg data-fig=\"screens\" viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"The planner's two screens. On the left, the list of courses: the heading Study planner, the week of 19 October 2026 with 80 of 195 minutes done, and three courses with their sessions and minutes that week. Choosing Statistics opens the screen on the right: a link back to the courses, the Statistics heading, its two sessions with a box to tick each, and a form with a date, minutes and an Add session button.\"><rect x=\"10\" y=\"40\" width=\"330\" height=\"250\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"20\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">1 · the courses</text><text x=\"26\" y=\"64\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--phosphor)\">Study planner</text><text x=\"26\" y=\"88\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Week of 19 Oct 2026</text><text x=\"26\" y=\"106\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">80 of 195 minutes done</text><rect x=\"22\" y=\"128\" width=\"306\" height=\"38\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"34\" y=\"141\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--phosphor)\">Statistics</text><text x=\"34\" y=\"156\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">2 sessions · 90 min</text><rect x=\"22\" y=\"176\" width=\"306\" height=\"38\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"34\" y=\"189\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--phosphor)\">Spanish</text><text x=\"34\" y=\"204\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">2 sessions · 60 min</text><rect x=\"22\" y=\"224\" width=\"306\" height=\"38\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"34\" y=\"237\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--phosphor)\">Organic chemistry</text><text x=\"34\" y=\"252\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">1 session · 45 min</text><rect x=\"380\" y=\"40\" width=\"330\" height=\"250\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"390\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">2 · one course</text><text x=\"396\" y=\"64\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">Back to courses</text><text x=\"396\" y=\"90\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">Statistics</text><text x=\"396\" y=\"116\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">[x]</text><text x=\"424\" y=\"116\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Mon 19 Oct · 50 min</text><text x=\"396\" y=\"142\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">[ ]</text><text x=\"424\" y=\"142\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Wed 21 Oct · 40 min</text><line x1=\"392\" y1=\"170\" x2=\"698\" y2=\"170\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"396\" y=\"190\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Add a session</text><text x=\"396\" y=\"214\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">Date</text><rect x=\"450\" y=\"203\" width=\"110\" height=\"22\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"505.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">2026-10-24</text><text x=\"396\" y=\"242\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">Minutes</text><rect x=\"450\" y=\"231\" width=\"60\" height=\"22\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"480.0\" y=\"242.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">30</text><rect x=\"396\" y=\"260\" width=\"104\" height=\"22\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"448.0\" y=\"271.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Add session</text><line x1=\"330\" y1=\"147\" x2=\"380\" y2=\"147\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"380.0,147.0 372.5,150.2 372.5,143.8\" fill=\"var(--phosphor)\"></polygon></svg>", "caption": "What the planner shows, in every course of the fork. The app's own words are English in both languages."}
```

The first screen lists the courses. At the top is the week: the minutes planned from Monday to
Sunday, and how many of those minutes are done. Each course shows its sessions in that week and
their minutes. Choosing a course opens the second screen, which lists that course's sessions with a
box to tick for each, and a form to add one. A link goes back.

The week has to come from somewhere. In your browser it is the week of today. In the transcripts it
is the week of **Monday 19 October 2026**, because a transcript recorded on one day and read on
another must show the same numbers, so `look --today 2026-10-21` tells the page it is that
Wednesday. The data below sits in that week on purpose; lesson 4 adds buttons to move between weeks,
and with them you can reach it from any date.

## The data

The planner's data is one JSON file, and the development server serves it as it is from `public/`.
Save it as `public/courses.json`:

```json
{
  "courses": [
    { "id": "statistics", "name": "Statistics" },
    { "id": "spanish", "name": "Spanish" },
    { "id": "chemistry", "name": "Organic chemistry" }
  ],
  "sessions": [
    { "id": "s1", "course": "statistics", "date": "2026-10-19", "minutes": 50, "done": true },
    { "id": "s2", "course": "statistics", "date": "2026-10-21", "minutes": 40, "done": false },
    { "id": "s3", "course": "spanish", "date": "2026-10-20", "minutes": 30, "done": true },
    { "id": "s4", "course": "spanish", "date": "2026-10-23", "minutes": 30, "done": false },
    { "id": "s5", "course": "chemistry", "date": "2026-10-14", "minutes": 60, "done": true },
    { "id": "s6", "course": "chemistry", "date": "2026-10-22", "minutes": 45, "done": false }
  ]
}
```

```
ana@dev:~/planner$ curl -s http://localhost:5173/courses.json | head -n 5
{
  "courses": [
    { "id": "statistics", "name": "Statistics" },
    { "id": "spanish", "name": "Spanish" },
    { "id": "chemistry", "name": "Organic chemistry" }
```

Three courses and six sessions. **A session names its course by the course's `id`**, never by its
name: rename "Organic chemistry" to "Chemistry II" and every session still belongs to it, because
nothing pointed at the words. A date is written `YYYY-MM-DD`, the one format that sorts correctly
as text, and a duration is a whole number of minutes.

## The numbers to expect

Five of the six sessions fall between Monday 19 and Sunday 25 October; `s5`, on the 14th, is the
week before. So the week the transcripts show plans **195 minutes**, 50 + 40 + 30 + 30 + 45, and
**80** of them are done, the 50 and the 30 already ticked. Statistics has 90 minutes in that week,
Spanish 60, and Organic chemistry 45. Every lesson that draws the first screen has to arrive at
those numbers, and lesson 22 turns them into a test.
