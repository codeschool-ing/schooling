---
title: A form that submits
version: 1
---

**A form is the right element for anything that collects input and acts on it, because the browser
gives it behaviour you would otherwise write by hand.** Enter in any field submits it. `required`,
`min` and `step` are checked before submission, with a message in the student's own language. And a
screen reader announces it as a form, with its fields in order. `AddSession` has been a `<p>` with a
button since lesson 5; this section makes it a form.

```schooling-example
{"language": "html", "file": "src/lib/AddSession.svelte", "parts": [
 {"code": "<script>\n\tlet { onadd } = $props();\n\n\tlet date = $state('');\n\tlet minutes = $state(30);"},
 {"code": "\tfunction submit(event) {\n\t\tevent.preventDefault();\n\t\tonadd({ date, minutes });\n\t\tdate = '';\n\t}\n</script>", "note": "The handler receives the submit event. `preventDefault()` stops the browser's own submission, which would reload the page."},
 {"code": "<form onsubmit={submit}>\n\t<label>Date <input type=\"date\" required bind:value={date} /></label>\n\t<label>Minutes <input type=\"number\" min=\"5\" step=\"5\" required bind:value={minutes} /></label>\n\t<button>Add session</button>\n</form>", "note": "`required` replaces the disabled button: the browser refuses to submit without a date, and says why. A plain `<button>` in a form is a submit button."}
]}
```

Fill in a date and press Enter, without touching the button:

```
ana@dev:~/planner$ look http://localhost:5173/ --fill 'Date=2026-10-21' --press Enter
-- fill Date=2026-10-21
-- press Enter
at /
title: 255 min this week · Study planner
- main:
  - heading "Study planner" [level=1]
  - paragraph:
    - button "Previous week"
    - text: Week of 19 Oct 2026
    - button "Next week"
  - list:
    - listitem:
      - button "Linear algebra" [pressed]
      - text: 180 min
    - listitem:
      - button "Spanish"
      - text: 30 min
    - listitem:
      - button "Guitar"
      - text: 45 min
  - paragraph: 255 minutes this week (4 h 15 min)
  - region "Linear algebra":
    - heading "Linear algebra" [level=2]
    - list:
      - listitem:
        - checkbox "19 Oct 2026, 90 min" [checked]
        - text: 19 Oct 2026, 90 min
      - listitem:
        - checkbox "24 Oct 2026, 60 min"
        - text: 24 Oct 2026, 60 min
      - listitem:
        - checkbox "21 Oct 2026, 30 min"
        - text: 21 Oct 2026, 30 min
    - paragraph: 180 minutes for Linear algebra this week (3 h 0 min)
    - text: Date
    - textbox "Date"
    - text: Minutes
    - spinbutton "Minutes": "30"
    - button "Add session"
```

The session of the 21st is in the list and the date field is empty again, ready for the next one.
**Enter submitted the form**, because that is what Enter in a form field does, and `submit` ran.

Press the button with no date, and nothing happens:

```
ana@dev:~/planner$ look http://localhost:5173/ --click 'Add session'
-- click Add session
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
    - spinbutton "Minutes": "30"
    - button "Add session"
```

The browser checked `required`, refused to submit, and showed a message beside the field that `look`
cannot print, because it is drawn by the browser rather than written into the page. The handler never
ran, so nothing reached the page.

## What `preventDefault` is preventing

Take the `event.preventDefault();` line out of `submit` and try again:

```
ana@dev:~/planner$ look http://localhost:5173/ --fill 'Date=2026-10-21' --press Enter
-- fill Date=2026-10-21
-- press Enter
at /
title: 255 min this week · Study planner
- main:
  - heading "Study planner" [level=1]
  - paragraph:
    - button "Previous week"
    - text: Week of 19 Oct 2026
    - button "Next week"
  - list:
    - listitem:
      - button "Linear algebra" [pressed]
      - text: 180 min
    - listitem:
      - button "Spanish"
      - text: 30 min
    - listitem:
      - button "Guitar"
      - text: 45 min
  - paragraph: 255 minutes this week (4 h 15 min)
  - region "Linear algebra":
    - heading "Linear algebra" [level=2]
    - list:
      - listitem:
        - checkbox "19 Oct 2026, 90 min" [checked]
        - text: 19 Oct 2026, 90 min
      - listitem:
        - checkbox "24 Oct 2026, 60 min"
        - text: 24 Oct 2026, 60 min
      - listitem:
        - checkbox "21 Oct 2026, 30 min"
        - text: 21 Oct 2026, 30 min
    - paragraph: 180 minutes for Linear algebra this week (3 h 0 min)
    - text: Date
    - textbox "Date"
    - text: Minutes
    - spinbutton "Minutes": "30"
    - button "Add session"
```

**It still worked, and the reason is SvelteKit rather than the browser.** Without `preventDefault`, the
browser carries on with its own job after `submit` has run, which is to send the form to its `action`
address, here the same page, and load the answer. On a plain HTML page that is a reload: a fresh page,
started from the data file, with the session just added gone. SvelteKit intercepts a form that sends
with `GET`, as this one does by default, and turns the submission into a **client-side navigation** to
`/?`: the same page, so the components stay and so does their state. That is why the session of the
21st is still there.

Do not rely on it. The navigation runs the page's data loading again, which from lesson 13 is a request
to the server, and a form with `method="POST"` behaves differently again, as lesson 14 shows at length.
This form is not meant to go anywhere: it is a way of collecting two values and calling a function. Say
so with `event.preventDefault()`, and put the line back.
