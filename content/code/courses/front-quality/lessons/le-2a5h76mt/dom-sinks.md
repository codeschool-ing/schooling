---
title: The places text turns into code
version: 1
---

**A sink is any place in the DOM's interface that takes a string and does more with it than show it.**
Cross-site scripting needs one, and the list is short enough to know by heart, which is the practical
defence: look for these in a review, and ask of each where its string came from.

| sink | what it does with a string | the safe way |
|---|---|---|
| `element.innerHTML = s` | parses it as HTML and builds whatever it describes | `textContent`, or `createElement` and `append` |
| `element.outerHTML = s` | the same, replacing the element | as above |
| `element.insertAdjacentHTML(where, s)` | the same, beside the element | `insertAdjacentText`, or `append` |
| `document.write(s)` | writes markup into the document as it loads | nothing; there is no reason to use it |
| `a.href = s`, `iframe.src = s` | follows it, and a `javascript:` address runs as code | check `new URL(s).protocol` is `https:` or `http:` first |
| `element.setAttribute("onclick", s)` | an event handler attribute is code | `addEventListener` with a function |
| `eval(s)`, `new Function(s)`, `setTimeout(s, …)` | runs it | functions, never strings |

**The safe column is not a burden.** Every row has an ordinary alternative that does what was wanted,
and the planner's own view uses the first one throughout. Frameworks do the same by default: each of the
four escapes values written into a template, and each has one named way around it, which is the line to
look for in a review of code written in it.

## Links are the one that looks harmless

A link's `href` taken from data, a course's website for instance, is a sink because of one scheme:
`javascript:`. The check is three lines, and the planner would use it the day a course carried a link:

```typescript
function safeLink(address: string): string | undefined {
  const url = new URL(address, location.href);
  return url.protocol === "https:" || url.protocol === "http:" ? url.href : undefined;
}
```

Anything that is not `http:` or `https:` gets no link at all, which is the allowlist idea of lesson 7
applied to an address.
