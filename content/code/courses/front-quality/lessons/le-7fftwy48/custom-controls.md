---
title: When the control is not a control
version: 1
---

**A `button` comes with the keyboard included.** It takes the focus, Enter and Space press it, a screen
reader announces it as a button, and the planner's **Done** works from the keyboard without one line
written for it. A `div` with a click handler has none of that: Tab skips it, no key presses it, and a
screen reader reads it as text.

Here is what it takes to make a `div` behave as a button, which is the clearest argument for not doing it:

```schooling-example
{"language": "html", "parts": [{"code": "<div class=\"tick\" role=\"button\" tabindex=\"0\">Done</div>\n", "note": "A `div` that looks like the planner's button. `role` tells a screen reader to announce a button, and `tabindex=\"0\"` puts it in the tab order, which a `div` is not in."}, {"code": "<script>\n  const tick = document.querySelector(\".tick\");\n  tick.addEventListener(\"click\", markDone);\n", "note": "The click is the easy part, and the only part most people write."}, {"code": "  tick.addEventListener(\"keydown\", (event) => {\n    if (event.key === \"Enter\" || event.key === \" \") {\n      event.preventDefault();\n      markDone();\n    }\n  });\n</script>", "note": "Enter and Space have to be taught. `preventDefault` stops Space from scrolling the page, which is what it does on anything that is not a button. And this still fires Space when the key goes down, where a button waits for it to come up."}]}
```

**Four things, each of which a `button` already does**, and the copy still differs: a real button fires
on Space when the key is released rather than when it goes down, it can be `disabled`, and it submits the
form it sits in. Every one of them is a bug waiting in the copy. The first rule of ARIA, which lesson 12
reads in full, says the same thing: if an element exists for the job, use it.

## Traps, and Escape

2.1.2 *No Keyboard Trap*, level A, asks that the focus can always leave anything it entered with the
keyboard. Traps are rare in plain HTML and common in what is built on top of it: an embedded editor that
keeps Tab for itself, a map that captures the arrow keys, a dialog that keeps the focus inside and offers
no way out.

A dialog is the one place where keeping the focus inside is *right*, because what is behind it cannot be
used while it is open, and Escape is the way out. The `<dialog>` element opened with `showModal()` does all
of it: it moves the focus into the dialog, makes the rest of the page inert so that Tab cannot reach it,
closes on Escape, and gives the focus back to what opened it. As with the button, the element that exists for the
job does the job.
