---
title: The planner, rewritten in tokens
version: 1
---

**The planner's stylesheet is rewritten to use only tokens, and to import the generated file.** Every
colour, size and gap becomes a `var(--…)`, and a few rules are added for what the planner did not style
before: links, buttons and the form's panel. Replace `src/style.css` with this:

```css
/* src/style.css */
@import "./tokens.css";

:root {
  color-scheme: light dark;
}

[data-theme="light"] {
  color-scheme: light;
}

[data-theme="dark"] {
  color-scheme: dark;
}

body {
  font-family: system-ui, sans-serif;
  font-size: var(--font-size-0);
  line-height: 1.5;
  margin: var(--space-8) auto;
  max-width: 40rem;
  padding: 0 var(--space-4);
  background: var(--surface);
  color: var(--text);
}

h1 {
  font-size: var(--font-size-4);
}

h2 {
  font-size: var(--font-size-2);
}

a {
  color: var(--accent);
}

li {
  margin: var(--space-1) 0;
}

li span {
  color: var(--muted);
}

button {
  font: inherit;
  background: var(--accent);
  color: var(--on-accent);
  border: 0;
  border-radius: var(--space-1);
  padding: var(--space-1) var(--space-3);
}

form {
  display: flex;
  gap: var(--space-4);
  flex-wrap: wrap;
  align-items: end;
  background: var(--raised);
  padding: var(--space-4);
  border-radius: var(--space-2);
}
```

`@import` at the top pulls `tokens.css` in, and Vite inlines it into the one stylesheet the build writes,
so the browser still makes a single request. `color-scheme` tells the browser which themes the page
supports, so the date and number fields follow the theme instead of staying white on a dark page.

## A check a reviewer can run

**The stylesheet should contain no colour and no pixel value.** That is easy to say and easy to break in a
hurry, and a search finds it:

```
ana@dev:~/planner$ grep -nE '#[0-9a-fA-F]{3,6}|[0-9]px' src/style.css; echo $?
1
```

No line printed, and `grep` exited with 1, its way of saying it found nothing. The two values left that are not tokens, `1.5` and
`40rem`, are a ratio and a column width, and the spacing scale's last section said why those stay as they
are. A search like this one is a fair step for the pipeline as well.

Build, and open the planner with your system in light mode and then in dark. The page, the panel behind
the form, the links and the buttons all change together, and every pair of text and background is one the
contrast script measured.

```
ana@dev:~/planner$ npm run build 2>&1 | grep css
dist/assets/index-BU4yu1tj.css  2.11 kB │ gzip: 0.64 kB
ana@dev:~/planner$ npm run contrast > /dev/null && echo contrast ok
contrast ok
ana@dev:~/planner$ git add tokens.json tokens.mjs contrast.mjs src/tokens.css src/style.css package.json
ana@dev:~/planner$ git commit -qm "Tokens, a type and spacing scale, two themes"
```

The stylesheet grew from 0.18 kB to about 2 kB with the tokens in it, 0.64 kB compressed: the cost of a design system
on the wire for an app this size.
