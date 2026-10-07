---
title: A method for a bug
version: 1
---

**Debugging goes faster when it is a search rather than a series of guesses.** The tools in this
lesson each answer one question. A method decides which question to ask next.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"Five steps in a row, the last pointing back to the first: reproduce the bug on purpose, read what the error says, find the line with a breakpoint, explain the cause in one sentence, then fix it and keep a test that would have caught it. When the explanation turns out wrong, go back to finding the line.\"><defs><marker id=\"method-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><defs><marker id=\"method-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><defs><marker id=\"method-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"50\" width=\"120\" height=\"56\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"80.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--phosphor)\">reproduce</text><text x=\"80.0\" y=\"87.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">on purpose</text><path d=\"M140 78 L156 78\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#method-ah-phosphor)\"></path><rect x=\"160\" y=\"50\" width=\"120\" height=\"56\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"220.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--phosphor)\">read</text><text x=\"220.0\" y=\"87.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the whole error</text><path d=\"M280 78 L296 78\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#method-ah-phosphor)\"></path><rect x=\"300\" y=\"50\" width=\"120\" height=\"56\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--phosphor)\">locate</text><text x=\"360.0\" y=\"87.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">with a breakpoint</text><path d=\"M420 78 L436 78\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#method-ah-phosphor)\"></path><rect x=\"440\" y=\"50\" width=\"120\" height=\"56\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"500.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--phosphor)\">explain</text><text x=\"500.0\" y=\"87.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">in one sentence</text><path d=\"M560 78 L576 78\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#method-ah-phosphor)\"></path><rect x=\"580\" y=\"50\" width=\"120\" height=\"56\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"640.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--amber)\">fix</text><text x=\"640.0\" y=\"87.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">and keep a test</text><path d=\"M640 106 L640 160 L80 160 L80 110\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 3\" marker-end=\"url(#method-ah-amber)\"></path><text x=\"360\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">the bug again, or a new one: start over</text><path d=\"M500 106 L500 130 L360 130 L360 110\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"5 3\" marker-end=\"url(#method-ah-paper-dim)\"></path><text x=\"430\" y=\"142\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">wrong explanation</text></svg>", "caption": "A method rather than a guess: each step narrows where the bug can be."}
```

1. **Reproduce it on purpose.** Find the steps that make the bug happen every time. A bug you
   cannot make happen is one you cannot know you fixed. If it only happens sometimes, that is
   information: timing, a cache, data that differs between runs;
2. **Read the whole error.** The type, the message, the file and the line, and the stack under it.
   `Cannot read properties of undefined (reading 'title')` already said that something expected to
   be a book was not one;
3. **Locate it with a breakpoint**, not with more `log` lines. Pause where the value is wrong and
   read the stack to find where it came from. Then pause earlier, until you reach the first line
   where a value is not what you expected;
4. **Explain it in one sentence**: "the loop asks for index 3 of a three-item array". If you cannot
   write that sentence, you have found where the bug shows, not where it lives, and a fix now
   would be a guess;
5. **Fix it, and keep a test that would have caught it.** The test is what stops the same bug
   returning in six months, when somebody tidies the loop. `front-quality`, lesson 2, writes those
   tests.

## When the code is not yours to read

A page in production usually runs **minified** code: one long line, short names, no comments. A
**source map** is a file the build writes beside it that maps each position back to the original
source, and DevTools uses it to show your own files, with breakpoints on your own lines. Keep
source maps where your team can reach them and decide deliberately whether the public can. No build
step runs in this course, so there was nothing to map here.

An error a student never reports is one you never see. `front-delivery`, lesson 11, sends errors
from users' browsers to a place the team reads, which is where this method usually starts in a
real product.
