---
title: HTML is not how the page looks
version: 1
---

Most people meet HTML with a picture already in their head: **HTML is the code that makes the page look the way it does**. A heading is big because it is in an `<h1>`; text is bold because it is in a `<b>`; a page has two columns because somebody wrote the right tags. That picture is wrong in a way that costs you later, so it is worth replacing now.

HTML describes **what each piece of content is**. `<h1>` says "this is the main heading of the page". That it comes out large and bold is a decision the browser makes with its own default stylesheet, and every one of those decisions can be undone with CSS. You can make an `<h1>` small and grey and a `<p>` enormous; the page would look strange, and it would still be correctly marked up, because the HTML would still be telling the truth about what each part is.

## Why the difference matters

A browser drawing the page on a screen is only one of the readers your HTML has. Three others read it without ever looking at the picture:

- **A screen reader**, used by people who cannot see the screen, reads the headings out, lets its user jump from one to the next, and announces a list as "list, five items". It knows what is a heading only from the HTML.
- **A search engine** reads the title, the headings and the links to work out what the page is about. A heading drawn with a big bold `<div>` is, to it, one more paragraph.
- **The browser itself**, in reader mode, on a smartwatch or when somebody's own stylesheet overrides yours, uses what the elements are to decide what to show.

So the question to ask while writing HTML is never "how will this look?" but **"what is this?"**. Lesson 2 is entirely about that question. How it looks is CSS, lessons 5 to 13.

## The second wrong picture: if it shows, it is right

The other belief worth naming is that a page which displays correctly has correct HTML. **The browser is the most forgiving reader your HTML will ever have.** It was built to show something for any input, because the early web was written by hand by people who made mistakes, and a browser that refused broken pages lost to one that showed them.

So it repairs. It closes elements you left open, moves elements that cannot go where you put them, and invents the ones you left out. This lesson shows it doing all three, with the exact document the browser built printed beside the file it was given. Most repairs are harmless. Some change what is bold, what is inside a link or what a form sends. And one of them, in section 07 of this lesson, turns a whole page into a blank window because of a single missing closing tag.

A page is correct when its HTML says what it means without the browser having to guess, and the tool that tells you whether that is true is a validator, section 11.
