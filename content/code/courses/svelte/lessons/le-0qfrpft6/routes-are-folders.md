---
title: A route is a folder
version: 1
---

**In SvelteKit, the address of a page is the path of a folder under `src/routes`, and the page is the
`+page.svelte` inside it.** `src/routes/+page.svelte` is `/`, `src/routes/about/+page.svelte` is
`/about`, and a file at `src/routes/courses/algebra/+page.svelte` would be `/courses/algebra`. There is no
table of routes to keep in step with the files: the files are the table. Lessons 4, 8, 10 and 11 used
that already, for their experiments at `/old`, `/keys`, `/timer` and `/hello`. This lesson uses it for
the planner itself.

Files whose names start with `+` are the ones SvelteKit reads: `+page.svelte`, `+layout.svelte`,
`+error.svelte`, and from lesson 13 the `+page.js` and `+page.server.js` beside them. Anything else in a
route folder, a component used only there or a helper, is ignored by the router and can sit next to
the page that uses it.

The planner needs a second page that is not the planner: a short one saying what the application is.
Save it as `src/routes/about/+page.svelte`:

```schooling-example
{"language": "html", "file": "src/routes/about/+page.svelte", "parts": [
 {"code": "<svelte:head>\n\t<title>About · Study planner</title>\n</svelte:head>", "note": "`<svelte:head>` puts elements in the document's `<head>`. Each page sets its own title, which the browser shows in the tab and a screen reader announces first."},
 {"code": "<h1>About the planner</h1>\n<p>\n\tThe study planner lists your courses, the sessions you plan for each, and the minutes in your week.\n\tIt keeps everything on this computer, in one small file, and asks nobody for anything.\n</p>\n<p><a href=\"/\">Back to the planner</a></p>", "note": "A link to another page of the application is an ordinary `<a href>`. There is no special link component."}
]}
```

```
ana@dev:~/planner$ look http://localhost:5173/about --click 'Back to the planner'
-- click Back to the planner
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

`look` printed `at /`: the link worked, and the planner's page is showing. What the tree cannot show is
**how** it got there, and that is the interesting part.

## Client-side navigation

**SvelteKit intercepts clicks on links to its own pages and does not reload.** It fetches the code for
the new page, if it does not have it already, renders it in place of the old one, and updates the
address with the History API. Back and Forward work, and so does opening a link in a new tab, because
the addresses are real: the server can render every one of them on its own, which is what happened
when `look` opened `/about` directly.

The difference matters for the planner more than for most pages. A reload starts the browser from
nothing, so all the state in memory, the week, any session added, is gone: lesson 7 described what a
form would have cost on a plain HTML page. A client-side navigation keeps the parts of the page that both addresses share,
which is the subject of the next section, and the parts of the state that live in them.
