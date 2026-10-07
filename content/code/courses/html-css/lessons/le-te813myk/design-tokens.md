---
title: Design tokens: naming the decisions
version: 1
---

The variables a site's design is built from are often called **design tokens**: the named decisions about colour, spacing, type and so on, written down once so that every rule refers to them. A design team keeps them in a design tool, and the stylesheet's `:root` is where they become CSS. Naming them well is most of the work, and two levels of name help:

```css
:root {
  /* the palette: what colours exist */
  --green-700: #2f6f4e;
  --green-200: #8fd1ad;
  --red-800: #8a1c1c;
  --sand-50: #fbf8f2;

  /* the roles: where each is used */
  --color-page: var(--sand-50);
  --color-text: #1d1d1b;
  --color-accent: var(--green-700);
  --color-danger: var(--red-800);

  /* space, on one scale */
  --space-1: 0.25rem;
  --space-2: 0.5rem;
  --space-4: 1rem;
  --space-8: 2rem;

  /* type */
  --font-body: system-ui, sans-serif;
  --text-small: 0.875rem;
  --text-heading: 1.5rem;

  /* what sits on top of what, lesson 7 */
  --layer-dropdown: 10;
  --layer-sticky: 20;
  --layer-modal: 100;
}
```

**The palette names say what a colour is**; the role names say what it is for. Components use only the roles: a button uses `--color-accent`, never `--green-700`. Then a redesign that makes the accent blue changes one line, and a dark theme redefines the roles and leaves the palette alone, as section 06 did.

**A scale instead of free numbers.** With `--space-1` to `--space-8`, every gap on the site is one of a few sizes, and a page looks consistent without anybody measuring. A value that is not on the scale, `margin: 13px`, is then visibly an exception, which is usually a mistake.

**z-index as named levels.** Lesson 7 section 08 ended with this: a short scale with names makes "the modal is above the dropdown" a fact in one place, instead of a contest between 9999 and 99999 in two files.

Tailwind, lesson 13, is built on exactly this idea, with its own tokens, and lets you replace them with yours.
