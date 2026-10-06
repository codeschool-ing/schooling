---
title: Fallbacks, and a variable that does not exist
version: 1
---

`var()` takes a second argument, used when the variable is not defined: `var(--padding, 8px)`. Here are two paragraphs, one using a variable that was never declared, with a fallback, and one using a misspelt name, without one:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>Fallbacks · Andorinha Books</title>
    <style>
      :root { --gap: 24px; }
      .missing { padding: var(--padding, 8px); }
      .typo { padding: var(--paddng); }
      main { color: #2f6f4e; }
      .wrong {
        color: #8a1c1c;
        color: var(--gap);
      }
    </style>
  </head>
  <body>
    <main>
      <p class="missing">--padding is never declared.</p>
      <p class="typo">--paddng is a typo.</p>
      <p class="wrong">--gap is a length, used as a colour.</p>
    </main>
  </body>
</html>
```

```
ana@laptop:~/site$ probe fallback.html style .missing padding-left style .typo padding-left
p.missing  padding-left: 8px
p.typo  padding-left: 0px
```

The first got the fallback, **8px**. The second, `var(--paddng)`, found nothing and had no fallback, so `padding-left` became **0px**: the property's initial value. There was no error and no warning in the page. A misspelt variable name behaves exactly like a property that was never set, which is the hardest kind of mistake to see, because nothing looks broken; it just looks like a smaller gap than somebody intended.

## When to write a fallback

**For variables a component expects from outside**, which a page may or may not set, a fallback is the component's default: `padding: var(--card-padding, 1rem)` works whether or not anybody configured it.

**For your own design tokens, declared on `:root`**, a fallback mostly hides typos. If `--space` is always declared, `var(--space, 8px)` will only ever use the 8px when the name is misspelt, and then it hides the mistake behind a plausible value. Leave those without, and let DevTools show you: the Computed pane lists every custom property an element can see, and the Styles pane marks a `var()` whose variable does not exist.

A fallback can itself use a variable, `var(--card-accent, var(--accent))`, which reads as "the card's own accent if somebody set one, the site's otherwise".
