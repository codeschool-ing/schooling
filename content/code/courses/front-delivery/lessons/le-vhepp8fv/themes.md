---
title: Themes are the same names with other values
version: 1
---

**A theme is a second set of values for the same semantic tokens, not a second stylesheet.** The planner's
CSS says `background: var(--surface)` once; what `--surface` holds depends on which theme applies. Adding a
theme is adding a column to `tokens.json`, and no rule in the app's stylesheet changes.

The generated file holds the semantic layer three times:

```
ana@dev:~/planner$ sed -n '/^:root,/,$p' src/tokens.css
:root,
[data-theme="light"] {
  --surface: var(--color-grey-0);
  --raised: var(--color-grey-50);
  --text: var(--color-grey-900);
  --muted: var(--color-grey-600);
  --accent: var(--color-green-600);
  --on-accent: var(--color-grey-0);
}

@media (prefers-color-scheme: dark) {
  :root:not([data-theme="light"]) {
    --surface: var(--color-grey-900);
    --raised: var(--color-grey-800);
    --text: var(--color-grey-50);
    --muted: var(--color-grey-300);
    --accent: var(--color-green-300);
    --on-accent: var(--color-grey-900);
  }
}

[data-theme="dark"] {
  --surface: var(--color-grey-900);
  --raised: var(--color-grey-800);
  --text: var(--color-grey-50);
  --muted: var(--color-grey-300);
  --accent: var(--color-green-300);
  --on-accent: var(--color-grey-900);
}
```

## Three blocks, three situations

1. **`:root, [data-theme="light"]`** is the default, and also what any element with `data-theme="light"`
   gets.
2. **`@media (prefers-color-scheme: dark)`** applies when the reader's operating system is set to dark.
   Inside it, `:root:not([data-theme="light"])` gives the root element the dark values unless the page has
   pinned it to light, which is what a theme switch in the interface does.
3. **`[data-theme="dark"]`** forces dark on any element that asks, whatever the system says.

The pattern serves both the reader's preference and an explicit choice. A theme switch is then one line
of JavaScript, setting `document.documentElement.dataset.theme`, and remembering it across visits is
`localStorage`. The planner has no switch; it follows the system, and lesson 6 uses the attribute to show
every component in both themes side by side.

## What else a theme has to change

Colours are the obvious part. Two less obvious ones:

- **`color-scheme`.** Form fields, scrollbars and the browser's own controls are drawn by the browser,
  not by your CSS, and they stay light on a dark page unless the page declares `color-scheme: light dark`.
  The planner's stylesheet does, in the next section.
- **the check, per theme.** The dark theme is a set of new pairs with their own contrast, as the last
  section's `grey-400` showed. A theme nobody measured is a theme nobody can read in some light.

## Themes as brands

The same mechanism serves a product sold under two brands, or a white-label app each customer colours in
their own way: each brand is another column of semantic values, maybe with its own primitives. The
components never learn which brand they are in. That is the same reason this course keeps saying "the
semantic layer": every theme, brand and mode is a different answer to the same named questions.
