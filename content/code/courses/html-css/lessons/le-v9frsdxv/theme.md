---
title: Your design tokens in @theme
version: 2
---

Lesson 10 promised that Tailwind could take your tokens instead of its own. That is the **`@theme`** block in the input stylesheet, here `theme/input.css`:

```css
@import "tailwindcss";

@theme {
  --color-andorinha-50: #fbf8f2;
  --color-andorinha-700: #2f6f4e;
  --color-andorinha-900: #1d1d1b;
  --color-cancelled: #8a1c1c;
  --font-display: Georgia, "Times New Roman", serif;
}
```

Each variable in `@theme` is a token and **also creates utilities**. Its name says which: `--color-andorinha-700` creates `bg-andorinha-700`, `text-andorinha-700`, `border-andorinha-700` and every other colour utility for that colour; `--font-display` creates `font-display`. The page uses them like built-in ones.

The page beside it, `theme/index.html`, uses those names:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Andorinha Books</title>
    <link rel="stylesheet" href="out.css">
  </head>
  <body class="bg-andorinha-50 text-andorinha-900">
    <main class="mx-auto max-w-3xl p-4">
      <h1 id="title" class="font-display text-3xl">This week</h1>
      <article class="mt-4 border-l-4 border-andorinha-700 p-4">
        <h2 id="poetry" class="font-semibold">Poetry reading</h2>
      </article>
      <article class="mt-4 border-l-4 border-cancelled p-4">
        <h2 id="swap" class="font-semibold text-cancelled">Book swap, cancelled</h2>
      </article>
    </main>
  </body>
</html>
```

```
ana@laptop:~/site$ npx @tailwindcss/cli --cwd theme -i input.css -o out.css --silent
ana@laptop:~/site$ grep -E -- "--(color-andorinha|color-cancelled|font-display)[a-z0-9-]*:" theme/out.css
    --color-andorinha-50: #fbf8f2;
    --color-andorinha-700: #2f6f4e;
    --color-andorinha-900: #1d1d1b;
    --color-cancelled: #8a1c1c;
    --font-display: Georgia, "Times New Roman", serif;
ana@laptop:~/site$ probe theme/index.html style body background-color style "#title" font-family,font-size style "#poetry,#swap" color
body.bg-andorinha-50.text-andorinha-900  background-color: rgb(251, 248, 242)
h1#title  font-family: Georgia, "Times New Roman", serif
h1#title  font-size: 30px
h2#poetry  color: rgb(29, 29, 27)
h2#swap  color: rgb(138, 28, 28)
```

The tokens are declared on `:root` with the values you gave them, and the page has the bookshop's colours: the page background **`rgb(251, 248, 242)`**, the cancelled event's heading **`rgb(138, 28, 28)`**, and the display font on the `<h1>`.

## How far to take it

Tailwind's own palette and scale stay available beside yours. To use **only** your colours, start the block with **`--color-*: initial;`**, which removes every built-in colour, so that `bg-red-500` no longer exists and nobody can reach for it. The same works for any namespace: `--font-*`, `--text-*`, `--spacing`.

**Name tokens by role**, lesson 10 section 06. `--color-cancelled` survives a redesign where `--color-red` would not. And because every token is a CSS custom property on `:root`, your own CSS can use the same values: `border-color: var(--color-andorinha-700)` in a stylesheet stays in step with `border-andorinha-700` in the HTML.
