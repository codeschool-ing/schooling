---
title: The witness, with and without the policy
version: 1
---

**A policy is proved the way every defence in this course is: by an ordinary input that would have
done something, and now does nothing.** The witness here is the smallest script there is, one that
changes the page's title, added to the page the way an injected one would be: as an element, from
inside the page. Save it as `server/witness.js`:

```javascript
// server/witness.js
const script = document.createElement("script");
script.textContent = 'document.title = "an inline script ran"';
document.body.append(script);
document.title;
```

`look.mjs` from lesson 7 runs it in the page and prints the last line's value, the title.

First on the development server, which sends no policy:

```
ana@dev:~/planner$ node server/look.mjs http://localhost:5173/ "$(cat server/witness.js)"
result:   an inline script ran
```

**The title changed**: an inline script added to the page ran, as any would. Then on the built site,
under its policy:

```
ana@dev:~/planner$ node server/look.mjs http://localhost:4173/ "$(cat server/witness.js)"
console:  Executing inline script violates the following Content Security Policy directive 'script-src 'self''. Either the 'unsafe-inline' keyword, a hash ('sha256-pEY6BBBxZAVxAefxgixuyIDc9Sf/P5B1/XuTyDX/02k='), or a nonce ('nonce-...') is required to enable inline execution. The action has been blocked.
result:   Study planner
```

**The title is still the planner's**, and the console says exactly why, naming the directive that
refused it and the three ways to allow it: `'unsafe-inline'`, a hash of the script, or a nonce. The
first would undo the policy, and the other two are for inline scripts the site itself writes, which the
planner has none of. The page's own code ran, as the test of the last section showed; the script that
was not its own did not.

## What the policy cannot do

A policy restricts where code comes from, so **it does nothing about code that comes from the right
place and does the wrong thing**. If the planner's own `assets/index-….js` wrote a person's text into
the page with `innerHTML`, that line runs, because it is the planner's own script. What the policy stops
is the *next* step, an injected `<script>` or a handler attribute running; lesson 9 removes the first
step, so there is nothing for the policy to stop.
