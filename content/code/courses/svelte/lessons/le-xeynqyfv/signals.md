---
title: Signals, and how a change finds its readers
version: 1
---

**A signal is a value that keeps a list of the code that read it.** `$state` makes one. When an
effect runs and reads `minutes`, the signal `minutes` writes that effect into its list. When
`minutes` is later set to something new, the signal goes down its list and schedules every effect on
it to run again. Nothing else is asked, so nothing else runs.

The list is built **while the code runs**, by the reads themselves, not by the compiler guessing
from the source. That is the difference from Svelte 4, whose `$:` statements were sorted out at
compile time from the names that appeared in them; lesson 4 shows what that got wrong.

## A value nobody reads

To see the list at work, give the counter a second piece of state that the effect does not read: a
weekly goal, with a button to raise it.

```schooling-example
{"language": "html", "file": "src/lib/Counter.svelte", "parts": [
 {"code": "<script>\n\tlet minutes = $state(0);\n\tlet goal = $state(120);\n\tconsole.log('the script ran');\n\n\t$effect(() => {\n\t\tconsole.log(`the effect ran: minutes is ${minutes}`);\n\t});\n</script>", "note": "Two signals now. The effect below reads `minutes` and never `goal`."},
 {"code": "<button onclick={() => (minutes += 30)}>Add 30 minutes</button>\n<button onclick={() => (goal += 60)}>Raise the goal</button>\n<p>{minutes} minutes this week</p>\n<p>The goal is {goal} minutes.</p>", "note": "Each button sets one signal. The paragraphs read one each."}
]}
```

```
ana@dev:~/planner$ look http://localhost:5173/ --console --click 'Raise the goal' --click 'Add 30 minutes'
console: [vite] connecting...
console: [vite] connected.
console: the script ran
console: the effect ran: minutes is 0
-- click Raise the goal
-- click Add 30 minutes
console: the effect ran: minutes is 30
at /
- main:
  - heading "Study planner" [level=1]
  - button "Add 30 minutes"
  - button "Raise the goal"
  - paragraph: 30 minutes this week
  - paragraph: The goal is 180 minutes.
```

**Raising the goal did not run the effect**, because the effect never read `goal`, so `goal`'s list
does not contain it. The second paragraph changed anyway, because the compiler wrote a separate
template effect for it that reads `goal`. Adding thirty minutes ran the effect once, because
`minutes`'s list does contain it.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"The counter&#x27;s signals and their readers. The signal minutes has two readers: the template effect that sets the first paragraph, and the effect that logs. The signal goal has one reader: the template effect that sets the second paragraph. Pressing Raise the goal reaches only goal&#x27;s reader; pressing Add 30 minutes reaches only minutes&#x27;s two readers.\"><rect x=\"40\" y=\"50\" width=\"150\" height=\"50\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"115\" y=\"75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">minutes</text><rect x=\"40\" y=\"160\" width=\"150\" height=\"50\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"115\" y=\"185\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">goal</text><text x=\"115\" y=\"28\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">signals</text><text x=\"560\" y=\"28\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">their readers</text><rect x=\"440\" y=\"40\" width=\"240\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"560\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">sets the first paragraph</text><rect x=\"440\" y=\"110\" width=\"240\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"560\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the effect that logs</text><rect x=\"440\" y=\"185\" width=\"240\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"560\" y=\"205\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">sets the second paragraph</text><line x1=\"190\" y1=\"70\" x2=\"438\" y2=\"50\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"438.0,50.0 430.9,53.7 430.4,47.5\" fill=\"var(--phosphor)\"></polygon><line x1=\"190\" y1=\"80\" x2=\"438\" y2=\"120\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"438.0,120.0 430.2,121.9 431.2,115.8\" fill=\"var(--phosphor)\"></polygon><line x1=\"190\" y1=\"185\" x2=\"438\" y2=\"195\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"438.0,195.0 430.5,197.8 430.8,191.6\" fill=\"var(--phosphor)\"></polygon><text x=\"300\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a change goes down its signal's list, and nowhere else</text></svg>", "caption": "Each signal keeps the list of what read it. Raising the goal reaches one reader; adding minutes reaches two."}
```

## Reads decide, on every run

Because the list is rebuilt each time an effect runs, an effect that reads a signal only on some
runs depends on it only on those runs. That is usually what you want, and it is the source of the
one surprise signals have. An effect like this one:

```javascript
$effect(() => {
	if (minutes > 0) console.log(`${minutes} of ${goal}`);
});
```

does not depend on `goal` while `minutes` is 0, because on that run `goal` was never read. Raise the
goal first and nothing prints; add thirty minutes and it prints with the new goal, and from then on
it follows both. The rule that explains every case is short: **an effect depends on exactly what it
read the last time it ran.**

## Where the signals live

`$state` is not a function you could call from any JavaScript file. It is a **rune**, a word the
compiler recognises, and it only works in `.svelte` files and in modules named `.svelte.js`, which
lesson 10 uses to share state between components. In both, the compiler rewrites the variable into a
signal and every use of it into a read or a write, as lesson 1's output showed. That rewriting is why
`minutes += 30` is all it takes to change the page: the compiler turned that line into
`$.set(minutes, $.get(minutes) + 30)`.
