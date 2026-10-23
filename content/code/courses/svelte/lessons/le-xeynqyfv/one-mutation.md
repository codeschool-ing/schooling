---
title: Counting what changes on the page
version: 1
---

**A change in Svelte touches only the nodes that show it, and the browser can count them for you.**
A `MutationObserver` is a browser API that reports every change made to the page: a node added or
removed, an attribute set, a piece of text replaced. Put one on the planner's page and press the
buttons, and each report is one thing that changed.

This version of the page starts an observer on `<main>` once the page is on screen, and logs each
report.
The effect reads no state, so it runs once; the function it returns runs when the page goes away,
and stops the observer:

```schooling-example
{"language": "html", "file": "src/routes/+page.svelte", "parts": [
 {"code": "<script>\n\timport Counter from '#lib/Counter.svelte';", "note": "The counter, as the previous section left it."},
 {"code": "\t$effect(() => {\n\t\tconst observer = new MutationObserver((records) => {\n\t\t\tfor (const record of records) {\n\t\t\t\tconsole.log(`changed: ${record.type}, now \"${record.target.textContent}\"`);\n\t\t\t}\n\t\t});", "note": "One report per change, with what the changed node says afterwards."},
 {"code": "\t\tobserver.observe(document.querySelector('main'), {\n\t\t\tsubtree: true,\n\t\t\tchildList: true,\n\t\t\tcharacterData: true,\n\t\t\tattributes: true\n\t\t});\n\t\treturn () => observer.disconnect();\n\t});\n</script>\n\n<main>\n\t<h1>Study planner</h1>\n\t<Counter />\n</main>", "note": "Watch everything inside `<main>`: children added or removed, text changed, attributes changed."}
]}
```

Two presses of one button and one of the other:

```
ana@dev:~/planner$ look http://localhost:5173/ --console --click 'Add 30 minutes' --click 'Add 30 minutes' --click 'Raise the goal'
console: [vite] connecting...
console: [vite] connected.
console: the script ran
console: the effect ran: minutes is 0
-- click Add 30 minutes
console: the effect ran: minutes is 30
console: changed: characterData, now "30 minutes this week"
-- click Add 30 minutes
console: the effect ran: minutes is 60
console: changed: characterData, now "60 minutes this week"
-- click Raise the goal
console: changed: characterData, now "The goal is 180 minutes."
at /
- main:
  - heading "Study planner" [level=1]
  - button "Add 30 minutes"
  - button "Raise the goal"
  - paragraph: 60 minutes this week
  - paragraph: The goal is 180 minutes.
```

**One press, one change.** Each `characterData` line is one text node whose contents were replaced,
and nothing else on the page was touched: no element was recreated, no attribute rewritten, the
button that was pressed was left alone. The text node is the one inside the paragraph, and its whole
content is the sentence, which is why the report shows all of it.

## What this does not prove

It would be easy to read this as "Svelte touches the page less than React", and that would be wrong.
**A virtual DOM ends at the same place.** React, after its diff, would also replace exactly one piece
of text, and an observer on a React page would print the same three lines. The DOM work is the same
because both frameworks are doing their job.

The difference is in the work **before** that one change. React called `Counter` again, built a new
description of a button and two paragraphs, and compared it with the old one, all to find the one
text node that a Svelte effect already knew about. On a counter that costs nothing anybody could
measure. On a page with a few thousand rows, where one row changes, it is the difference between
comparing a few thousand descriptions and setting one node, and the frameworks with a virtual DOM
each have their own tools to avoid the comparison when it hurts. Svelte's position is that you should
not need them.

Put `+page.svelte` back to the version in "The script runs once" before the drill: the observer was
a probe, and lesson 3 replaces the page anyway.
