---
title: Errors a screen reader can hear
version: 1
---

**An error message that only appears in red under a field does not exist for a student who cannot see
it.** Three attributes make it exist: `aria-invalid` says the field is wrong, `aria-describedby` points
the field at its message, so the message is read with the field, and a live region announces what
changed after a submit. All three are already in the planner's `FormField` and `SessionForm`.

Press the button with the course empty and 500 minutes typed in:

```
ana@dev:~/vue/planner$ look http://localhost:5173/ --clock 2026-10-21T10:00 --do 'fill input[type=number] 500' --do 'click text=Add the session' --html form --text -
[vite] connecting...
[vite] connected.
-- fill input[type=number] 500
-- click text=Add the session
== the HTML of form
<form novalidate=""><div data-v-b9645e84="" class="field"><label data-v-b9645e84="" for="v-0">Course</label><select id="v-0" aria-invalid="true" aria-describedby="v-0-error"><option disabled="" value="">Choose…</option><option value="statistics">Statistics</option><option value="spanish">Spanish</option><option value="guitar">Guitar</option></select><p data-v-b9645e84="" id="v-0-error" class="error">Choose a course.</p></div><div data-v-b9645e84="" class="field"><label data-v-b9645e84="" for="v-1">Date</label><input data-v-b9645e84="" id="v-1" type="date"><!--v-if--></div><div data-v-b9645e84="" class="field"><label data-v-b9645e84="" for="v-2">Minutes</label><input data-v-b9645e84="" id="v-2" type="number" min="5" max="240" aria-invalid="true" aria-describedby="v-2-error"><p data-v-b9645e84="" id="v-2-error" class="error">Between 5 and 240 whole minutes.</p></div><button>Add the session</button><p role="status" class="saved"></p></form>
```

Read the `<select>` and the minutes `<input>`: **each has `aria-invalid="true"` and an
`aria-describedby` naming the `<p>` with its message**, and the date field, which is fine, has neither.
When a screen-reader user moves to the minutes field, they hear something like *"Minutes, spin button,
500, invalid entry, Between 5 and 240 whole minutes."* The colour is for the eye; the attributes are for
everybody else.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"One form field and the three ids that join its parts. The label&#x27;s for attribute names the input&#x27;s id, v-2, so the label names the field. The input&#x27;s aria-describedby names v-2-error, the id of the paragraph holding the message, so the message is read with the field. aria-invalid true marks the field as wrong. All three ids come from one useId call.\"><rect x=\"30\" y=\"20\" width=\"260\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"42\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">&lt;label for=\"v-2\"&gt;Minutes&lt;/label&gt;</text><rect x=\"30\" y=\"86\" width=\"400\" height=\"52\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"42\" y=\"104\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">&lt;input id=\"v-2\" aria-invalid=\"true\"</text><text x=\"42\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">       aria-describedby=\"v-2-error\"&gt;</text><rect x=\"30\" y=\"164\" width=\"400\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"42\" y=\"184\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">&lt;p id=\"v-2-error\"&gt;Between 5 and 240…&lt;/p&gt;</text><line x1=\"160\" y1=\"62\" x2=\"160\" y2=\"84\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"160.0,84.0 156.9,76.6 163.1,76.6\" fill=\"var(--phosphor)\"></polygon><line x1=\"230\" y1=\"140\" x2=\"230\" y2=\"162\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"230.0,162.0 226.9,154.6 233.1,154.6\" fill=\"var(--phosphor)\"></polygon><text x=\"470\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">names the field</text><text x=\"470\" y=\"112\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">is announced as invalid</text><text x=\"470\" y=\"184\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">is read after the field</text><line x1=\"294\" y1=\"40\" x2=\"462\" y2=\"40\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"2 3\"></line><line x1=\"434\" y1=\"112\" x2=\"462\" y2=\"112\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"2 3\"></line><line x1=\"434\" y1=\"184\" x2=\"462\" y2=\"184\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"2 3\"></line></svg>", "caption": "The red text is for the eye; the ids are what a screen reader follows."}
```

## What each attribute does

| attribute | on | what a screen reader does with it |
|---|---|---|
| `<label for>` | the label | names the field |
| `aria-invalid="true"` | the field | announces it as invalid when it is reached |
| `aria-describedby` | the field, naming the message's id | reads the message after the field's name and value |
| `role="status"` | the paragraph that says what happened | announces its new text when it changes, without moving the focus |

`aria-invalid` is set only when there is an error, and removed otherwise, as `FormField` does with
`undefined`. A field marked invalid before the student has done anything is announced as wrong on their
first visit, which is the screen-reader version of the three red messages the last section avoided.

## Where the focus goes

After a failed submit, a sighted student sees the red messages. A keyboard user is still on the
button, and the errors are above it. Two choices are defensible: move the focus to the first invalid
field, or announce a summary. The planner keeps it small and does neither on failure, relying on each
field announcing its own error when reached. **After a successful submit**, it moves the focus back to
the course field, ready for the next session, and the status line says what was added. Lesson 9's
template ref is how, and the next section's handler is where it happens.

WCAG 2.2 AA asks for exactly these things, among others: errors identified in text, fields with labels,
and status messages announced. `front-quality` lessons 10 to 12 take the planner's kind of form through
axe and a screen reader in full.
