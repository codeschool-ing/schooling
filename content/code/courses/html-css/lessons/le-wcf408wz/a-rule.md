---
title: A rule, and where CSS lives
version: 2
---

Lesson 2 made the opening-hours subheadings `<h2>` and promised that if they were too big, that was CSS. Here is that CSS, the first rule of this lesson:

```css
h2 { font-size: 1.1rem; }
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 224\" role=\"img\" aria-label=\"One CSS rule, .event h2 { font-size: 1.1rem; }, taken apart. .event h2 is the selector, which chooses the elements. Inside the braces is the declaration block. font-size: 1.1rem; is one declaration: font-size is the property, 1.1rem the value, and a semicolon ends it.\"><rect x=\"20\" y=\"30\" width=\"680\" height=\"110\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"60\" y=\"54\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"20\" fill=\"var(--phosphor)\">.event h2</text><text x=\"180\" y=\"54\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"20\" fill=\"var(--paper)\">{</text><text x=\"84\" y=\"82\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"20\" fill=\"var(--amber)\">font-size</text><text x=\"192\" y=\"82\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"20\" fill=\"var(--paper)\">:</text><text x=\"216\" y=\"82\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"20\" fill=\"var(--paper)\">1.1rem</text><text x=\"288\" y=\"82\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"20\" fill=\"var(--paper)\">;</text><text x=\"60\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"20\" fill=\"var(--paper)\">}</text><path d=\"M60 22 v6 H168 v-6\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></path><text x=\"114\" y=\"14\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">selector: which elements</text><path d=\"M84 150 v8 H192 v-8\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></path><text x=\"138\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">property</text><path d=\"M216 150 v8 H288 v-8\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></path><text x=\"252\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">value</text><path d=\"M84 188 v8 H300 v-8\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></path><text x=\"192\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">declaration</text><text x=\"440\" y=\"66\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">the braces hold the declaration block:</text><text x=\"440\" y=\"84\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">as many declarations as you like,</text><text x=\"440\" y=\"102\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">each ending in a semicolon</text></svg>", "caption": "A rule is a selector and a block of declarations; a declaration is a property and a value."}
```

A **rule** is a **selector**, here `h2`, which picks the elements it applies to, followed by a **declaration block** in braces. Inside the block, each **declaration** is a **property**, a colon, a **value** and a semicolon. A rule can carry any number of declarations; this one carries one.

The rule lives in `events.css`, and the page links it as lesson 1 section 12 showed. The page is the bookshop's events page, `events.html`:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>Events · Andorinha Books</title>
    <link rel="stylesheet" href="events.css">
  </head>
  <body>
    <main id="events">
      <h1>Events</h1>
      <p class="intro">Everything here is free unless it says otherwise.</p>
      <article class="event">
        <h2>Poetry reading: Hilda Hilst</h2>
        <p>Thursday 8 October, 7 pm.</p>
        <p class="note">Bring a poem of your own.</p>
      </article>
      <article class="event featured">
        <h2>Book swap</h2>
        <p>Saturday 10 October, from 10 am.</p>
        <a href="swap.html" class="more">How the swap works</a>
      </article>
      <article class="event cancelled">
        <h2>Bookbinding class</h2>
        <p>Cancelled: the teacher is ill.</p>
      </article>
    </main>
  </body>
</html>
```

Every page in this lesson is this one, linking a different stylesheet. Save a copy for each stylesheet a section shows, named after it, and change its `<link>`: `cascade.html` links `cascade.css`, `states.html` links `states.css`, and the same goes for `extras`, `order` and `inherit`. Here is what `events.css` did to the headings:

```
ana@laptop:~/site$ probe events.html rules h2 font-size
h2 (0,0,1)  font-size: 1.5em                browser default
h2 (0,0,1)  font-size: 1.1rem               events.css
computed font-size: 17.6px
```

Two rules set `font-size` on that `<h2>`. The first is the **browser's default stylesheet**, the one that made headings big and bold before you wrote any CSS, saying `1.5em`. The second is yours, saying `1.1rem`. Yours won, and the heading is **17.6 pixels**: `rem` is a multiple of the root font size, which is 16 pixels by default, and 1.1 times 16 is 17.6. Lesson 6 is about units. Why yours won is the subject of most of this lesson.

## Three places to write CSS

**In a stylesheet linked from the head**, as above. This is where nearly all CSS should live: one file serves every page, the browser downloads it once and caches it, and the HTML stays about content.

**In a `<style>` element in the head**, which works the same way for one page. It is useful for a single page, for a demonstration like the pages in this course, and for small pieces of CSS that must arrive with the HTML.

**In a `style` attribute on an element**, `<p style="color: grey">`. This applies to that one element only, cannot use selectors, cannot be reused, and is hard to override, as section 09 measures. Avoid it in what you write by hand; you will meet it in code that a script or a framework generates.

## Comments, and what happens to a mistake

A comment in CSS is written `/* like this */`, and can span lines. There is no `//` comment in CSS. **A declaration the browser does not understand is skipped, silently**, and the rest of the rule still applies: a misspelt `colr: green;` changes nothing and says nothing. That forgiveness is lesson 1's parser again, and DevTools is again where it shows: the Styles panel draws an unknown property with a warning sign and strikes it through.
