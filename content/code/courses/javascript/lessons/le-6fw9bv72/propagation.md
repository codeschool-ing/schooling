---
title: Where an event goes: capture and bubbling
version: 1
---

A click on a button is also a click on everything the button is inside. **The browser delivers the
event to every ancestor of the target, twice**: once on the way down, once on the way back up. Four
elements with a listener for each direction show the whole journey:

```html
<!doctype html>
<ul id="books">
  <li class="book"><button class="lend">Lend</button></li>
</ul>
<script>
  const say = (where, phase) => (event) =>
    console.log(`${phase.padEnd(7)} ${where.padEnd(8)} target=${event.target.className}`);

  for (const [where, el] of [["document", document], ["ul", document.querySelector("ul")],
                             ["li", document.querySelector("li")], ["button", document.querySelector("button")]]) {
    el.addEventListener("click", say(where, "capture"), { capture: true });
    el.addEventListener("click", say(where, "bubble"));
  }
</script>
```

```
ana@dev:~/js$ page bubble.html --do 'click .lend'
-- click .lend
capture document target=lend
capture ul       target=lend
capture li       target=lend
capture button   target=lend
bubble  button   target=lend
bubble  li       target=lend
bubble  ul       target=lend
bubble  document target=lend
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"A click on the Lend button travels in three phases. In the capture phase it goes down from document through ul and li to the button. At the button it reaches its target. In the bubble phase it goes back up from the button through li and ul to document. A listener runs in the bubble phase unless it asked for capture.\"><defs><marker id=\"phases-ah-paper\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper)\"></path></marker></defs><defs><marker id=\"phases-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"170\" y=\"14\" width=\"380\" height=\"232\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"32\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">document</text><rect x=\"200\" y=\"46\" width=\"320\" height=\"192\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">ul#books</text><rect x=\"230\" y=\"78\" width=\"260\" height=\"152\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">li.book</text><rect x=\"290\" y=\"160\" width=\"140\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">button.lend</text><path d=\"M110 30 L110 170\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.8\" marker-end=\"url(#phases-ah-phosphor)\"></path><text x=\"100\" y=\"100\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">1. capture</text><text x=\"360\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">2. target</text><path d=\"M610 170 L610 30\" fill=\"none\" stroke=\"var(--paper)\" stroke-width=\"1.8\" marker-end=\"url(#phases-ah-paper)\"></path><text x=\"620\" y=\"100\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">3. bubble</text></svg>", "caption": "Every click visits each ancestor twice, on the way down and on the way up."}
```

1. **Capture**: from `document` down through every ancestor to the target. Only listeners added
   with `{ capture: true }` run here;
2. **target**: the element that was clicked, where both kinds of listener run;
3. **bubbling**: back up from the target to `document`. **A listener added without options runs
   here**, which is why most code never thinks about capture at all.

`target=lend` on every line is the point: **however far up a listener sits, `event.target` is still
the button that was clicked**. `currentTarget` is the one that changes, naming the element whose
listener is running.

## Stopping the journey

```html
<!doctype html>
<li class="book">Iracema <button class="lend">Lend</button></li>
<script>
  document.querySelector(".book").addEventListener("click", () => console.log("row opened"));
  document.querySelector(".lend").addEventListener("click", (event) => {
    event.stopPropagation();
    console.log("lent");
  });
</script>
```

```
ana@dev:~/js$ page stop.html --do 'click .lend' --do 'click .book'
-- click .lend
lent
-- click .book
row opened
```

The row opens when clicked, and the button inside it lends the book. Without the
`stopPropagation()` call, clicking the button would have lent the book **and** opened the row, because
the click would have bubbled up to the row's listener. With it, the first click printed only `lent`,
and the row still opened when it was clicked directly.

**Use `stopPropagation` sparingly.** Every listener above the element loses the event, including
ones you did not write: analytics, a menu that closes when you click elsewhere, a framework's own
handling. Checking `event.target` in the row's listener, which the next section does, usually solves
the same problem without hiding the click from anyone.
