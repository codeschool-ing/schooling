---
title: Organising the stylesheet
version: 2
---

A stylesheet that grows without a plan ends up with the same button styled in four places and nobody sure which wins. The fix is an **order**, chosen once, in which the general comes before the specific. A common one has six parts, and this lesson's `css/` folder, inside `site`, follows it:

```
ana@laptop:~/site$ find css -type f | sort
css/base.css
css/components/event-card.css
css/layout.css
css/main.css
css/reset.css
css/tokens.css
css/utilities.css
```

1. **`reset.css`**: the few rules that undo browser defaults nobody wants: `box-sizing: border-box` for everything, lesson 6, no margin on the body, images as blocks.
2. **`tokens.css`**: the custom properties of section 08, and nothing else.
3. **`base.css`**: the default look of plain elements, by type selector only: the body's font and colour, links, headings, lists. No classes.
4. **`layout.css`**: the large shapes, the page grid and the containers that hold things, lessons 8 and 9.
5. **`components/`**: one file per component, each styling only its own class names: the event card, the menu, the order form.
6. **`utilities.css`**: small single-purpose classes that must win wherever they are put, such as the `visually-hidden` class from lesson 7.

The order is also the order of **increasing specificity and increasing reach**: element selectors, then a few layout classes, then component classes, then utilities that override. Written in that order, the cascade mostly works without anybody fighting it, and section 10 makes that order a rule the browser enforces.

Every one of them is short. Here they are, to save under those names:

`css/reset.css`:

```css
*, *::before, *::after { box-sizing: border-box; }
body { margin: 0; }
img { display: block; max-width: 100%; }
```

`css/tokens.css`:

```css
:root {
  --color-text: #1d1d1b;
  --color-accent: #2f6f4e;
  --space: 0.5rem;
}
```

`css/base.css`:

```css
body { color: var(--color-text); font: 1rem/1.5 system-ui, sans-serif; }
a { color: var(--color-accent); }
```

`css/layout.css`:

```css
.page { display: grid; gap: calc(var(--space) * 4); }
```

`css/components/event-card.css`:

```css
.event-card { padding: calc(var(--space) * 2); border-left: 4px solid var(--color-accent); }
.event-card__title { margin: 0; font-size: 1.1rem; }
.event-card--cancelled { --color-accent: #8a1c1c; }
```

`css/utilities.css`:

```css
.visually-hidden {
  position: absolute !important;
  width: 1px;
  height: 1px;
  overflow: hidden;
  clip-path: inset(50%);
  white-space: nowrap;
}
```

`css/main.css`:

```css
@layer reset, tokens, base, layout, components, utilities;

@import url("reset.css") layer(reset);
@import url("tokens.css") layer(tokens);
@import url("base.css") layer(base);
@import url("layout.css") layer(layout);
@import url("components/event-card.css") layer(components);
@import url("utilities.css") layer(utilities);
```

## One file or many

`main.css` brings the others in with **`@import`**, and that has a cost the browser shows. The page that uses them, `site.html`, links `main.css` and nothing else:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>Events · Andorinha Books</title>
    <link rel="stylesheet" href="css/main.css">
  </head>
  <body>
    <main class="page">
      <article class="event-card event-card--cancelled">
        <h2 class="event-card__title">Bookbinding class</h2>
        <p>Cancelled: the teacher is ill.</p>
      </article>
    </main>
  </body>
</html>
```

Opened, it asks for these files:

```
ana@laptop:~/site$ probe site.html fetched
main.css
reset.css
tokens.css
base.css
layout.css
event-card.css
utilities.css
```

That is what the page asked for, in order: `main.css` first, then the six files it imports. The browser cannot know about `reset.css` until it has downloaded and read `main.css`, so the imports are found a round trip late, and nothing is drawn until they have all arrived, lesson 1 section 12. On a site served over a network, that delay is real. So **the files are for the people working on the CSS, and the browser should get one file**: in development `@import` is convenient, and for production a build step joins them into one stylesheet. `front-delivery` is where that build is set up. For a small site with one stylesheet, the parts are simply sections of one file, in the same order.
