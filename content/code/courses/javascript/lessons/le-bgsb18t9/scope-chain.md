---
title: How a function finds a name
version: 1
---

Lesson 3 said a name belongs to a scope. **Scopes nest**, because functions and blocks are written
inside each other, and when code uses a name the engine looks for it in a fixed order:

```javascript
const library = "City Library";

function openShelf(shelfName) {
  const opened = "09:00";

  function describeBook(title) {
    return `${title} on ${shelfName}, ${library}, open since ${opened}`;
  }

  return describeBook("Iracema");
}

console.log(openShelf("Romance"));

function lookForIt() {
  return readerCount;
}
console.log(lookForIt());
```

```
ana@dev:~/js$ node scope-chain.js 2>&1 | head -n 7
Iracema on Romance, City Library, open since 09:00
/home/ana/js/scope-chain.js:16
  return readerCount;
  ^

ReferenceError: readerCount is not defined
    at lookForIt (/home/ana/js/scope-chain.js:16:3)
```

`describeBook` declares one name, `title`, and uses four. It found them like this:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Three nested scopes. The file&#x27;s scope holds library. Inside it, openShelf&#x27;s scope holds shelfName and opened. Inside that, describeBook&#x27;s scope holds title. A name used in describeBook is looked for in its own scope first, then outwards, one scope at a time, and never inwards.\"><defs><marker id=\"chain-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"16\" y=\"14\" width=\"520\" height=\"222\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"30\" y=\"34\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">the file</text><text x=\"30\" y=\"54\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">library = &quot;City Library&quot;</text><rect x=\"46\" y=\"70\" width=\"470\" height=\"152\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"60\" y=\"90\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">openShelf</text><text x=\"60\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">shelfName = &quot;Romance&quot;   opened = &quot;09:00&quot;</text><rect x=\"76\" y=\"126\" width=\"420\" height=\"82\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"90\" y=\"146\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">describeBook</text><text x=\"90\" y=\"166\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">title = &quot;Iracema&quot;</text><text x=\"90\" y=\"190\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">uses title, shelfName, library, opened</text><path d=\"M600 190 L600 46\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.6\" marker-end=\"url(#chain-ah-amber)\"></path><text x=\"610\" y=\"190\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">1. its own scope</text><text x=\"610\" y=\"118\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">2. openShelf</text><text x=\"610\" y=\"46\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">3. the file</text></svg>", "caption": "A name is looked up from the inside out, and the nesting is decided by where the code is written."}
```

**First its own scope, then the scope it was written inside, then the next one out**, until it
reaches the file's top level. That sequence is the **scope chain**. The first scope that has the
name wins, which is how an inner declaration shadows an outer one (lesson 3). If no scope has it,
the result is the `ReferenceError` that `lookForIt` produced: `readerCount is not defined`.

## Written, not called

The nesting that matters is **where the function is written in the source**, not where it is
called from. That is why this kind of scope is called **lexical**: you can work it out by reading
the code, without running it. A function written at the top of a file cannot see the variables of
whatever function happens to call it, and a function written inside another can always see that
other function's names.

Lookups go **outwards only**. `openShelf` cannot read `title`, because `title` lives in a scope
inside it. Data flows into an inner function through its parameters and through the names it can
see outwards; it flows back out through what it returns.
