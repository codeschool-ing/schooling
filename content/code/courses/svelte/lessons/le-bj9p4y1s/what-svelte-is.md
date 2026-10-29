---
title: A framework that is a compiler
version: 1
---

**Svelte is a compiler that turns components into plain JavaScript before the browser sees them.**
React, Vue and Angular ship a library to the browser, and that library reads your components while
the page runs. Svelte does that work earlier, on your computer, when you build. What reaches the
browser is code that updates the page directly, plus a small runtime of helpers that code calls.

The usual picture is that a framework is something you download and call. Svelte breaks that
picture on purpose. The syntax you write, `$state`, `{#each}`, `onclick={…}`, is not JavaScript a
browser could run; it is input to a program that reads it and writes something else. The section
"What the compiler writes", two from the end of this lesson, shows the program it writes for a
component of six lines.

## The two names you will meet

**Svelte** is the component language and its compiler. A `.svelte` file holds a component: a
`<script>`, some markup and a `<style>`. This course uses **Svelte 5.57.2**, and lessons 2 to 11
are about it.

**SvelteKit** is the framework built on Svelte for whole applications: pages at addresses, data
loaded on the server, forms that post, and a build that produces something you can deploy. This
course uses **SvelteKit 3.1.0**, released in October 2026, and lessons 12 to 19 are about it. A
project created today is a SvelteKit project even when you only want components, so you will have
SvelteKit from this lesson on and use its routing from lesson 12.

Both run on **Vite**, the build tool that serves your project while you work on it and bundles it
when you are done. You will rarely call Vite by name; `npm run dev` and `npm run build` do.

## Where this course sits

This is one of four options at the same step of the `frontend` track. **React with TypeScript,
Angular, Vue and Svelte** each teach a framework, and you take one of them. The courses after the
fork assume none of the four, so nothing you skip here is something you will be asked for later.

**The four courses build the same application**, so that a student who switches course
recognises everything but the code. It is a **study planner**:

- the first screen lists your courses, and how many minutes of study each has this week;
- a course opens to its sessions, each with a date, a duration and a box to mark it done;
- a form adds a session to a course;
- the week's total is always on screen, and buttons move to the week before or after.

The data is three courses and six sessions in October 2026, in a JSON file of about twenty lines
that lesson 3 gives you whole. There is no external service and no account anywhere. Lesson 20
looks at the same planner in the other three frameworks, which is why it can compare like with
like.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"The study planner the four framework courses build. On the left, the first screen: the heading Study planner, the week of 19 October 2026 with buttons for the week before and after, three courses with their minutes this week (Linear algebra 150, Spanish 30, Guitar 45) and the week&#x27;s total, 225 minutes. Choosing a course opens the screen on the right: Linear algebra&#x27;s sessions, each with a date, a duration and a done box, and a form that adds a session with a date and a number of minutes. Underneath both, one JSON file holds three courses and six sessions.\"><rect x=\"20\" y=\"20\" width=\"300\" height=\"230\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"36\" y=\"44\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">Study planner</text><text x=\"170\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">‹   Week of 19 Oct 2026   ›</text><rect x=\"36\" y=\"92\" width=\"268\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"48\" y=\"105\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Linear algebra</text><text x=\"292\" y=\"105\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">150 min</text><rect x=\"36\" y=\"126\" width=\"268\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"48\" y=\"139\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Spanish</text><text x=\"292\" y=\"139\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">30 min</text><rect x=\"36\" y=\"160\" width=\"268\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"48\" y=\"173\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Guitar</text><text x=\"292\" y=\"173\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">45 min</text><line x1=\"36\" y1=\"202\" x2=\"304\" y2=\"202\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"48\" y=\"222\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">this week</text><text x=\"292\" y=\"222\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">225 min</text><line x1=\"304\" y1=\"105\" x2=\"398\" y2=\"105\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"398.0,105.0 390.6,108.1 390.6,101.9\" fill=\"var(--phosphor)\"></polygon><text x=\"351\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">choose a course</text><rect x=\"400\" y=\"20\" width=\"300\" height=\"230\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"416\" y=\"44\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">Linear algebra</text><rect x=\"416\" y=\"62\" width=\"268\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"428\" y=\"74\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">2026-10-13</text><text x=\"560\" y=\"74\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">60 min</text><rect x=\"650\" y=\"68\" width=\"12\" height=\"12\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"416\" y=\"92\" width=\"268\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"428\" y=\"104\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">2026-10-19</text><text x=\"560\" y=\"104\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">90 min</text><rect x=\"650\" y=\"98\" width=\"12\" height=\"12\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"416\" y=\"122\" width=\"268\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"428\" y=\"134\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">2026-10-24</text><text x=\"560\" y=\"134\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">60 min</text><rect x=\"650\" y=\"128\" width=\"12\" height=\"12\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"416\" y=\"168\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">add a session</text><rect x=\"416\" y=\"180\" width=\"110\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"426\" y=\"192\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">date</text><rect x=\"534\" y=\"180\" width=\"70\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"544\" y=\"192\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">minutes</text><rect x=\"612\" y=\"180\" width=\"72\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"648\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">Add</text><text x=\"684\" y=\"228\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">150 min this week</text><rect x=\"170\" y=\"280\" width=\"380\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"360\" y=\"297\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">one JSON file: 3 courses, 6 sessions, October 2026</text><line x1=\"170\" y1=\"280\" x2=\"120\" y2=\"252\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></line><line x1=\"550\" y1=\"280\" x2=\"600\" y2=\"252\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></line></svg>", "caption": "The planner's two screens, and the one file behind both."}
```

## How the course runs

**Lesson 1 sets up your computer and makes the project**, and every lesson after it changes that
same project, in `~/planner`. Each lesson shows every file it changes, whole, so you can type it
or copy it; nothing comes from anywhere but the lesson in front of you. Two lessons look around
more than they build: lesson 2, at what having no virtual DOM changes, and lesson 4, at Svelte 4
code, since a great deal of it is still in use.

You need the `javascript` course's material, and the `git` course's habit of committing as you
go. TypeScript is not assumed: the planner is plain JavaScript until lesson 18 converts it.
