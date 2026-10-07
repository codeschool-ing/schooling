---
title: What this course is, and how it measures a page
version: 2
---

This course teaches you to write the two languages every web page is made of. **HTML says what the content is**: this is a heading, this is a list, this is a form field with that label. **CSS says how it looks and where it goes**: this colour, that much space, these three cards side by side on a wide screen and stacked on a phone. Thirteen lessons cover them in that order: four on HTML, then nine on CSS, ending with Tailwind, a framework that writes CSS for you once you know what CSS it should write.

The course assumes `web-fundamentals`, and leans on two of its lessons in particular. Lesson 10 there explains how a browser turns a response into pixels: the DOM, the CSSOM, layout and paint. Lesson 11 there is the browser's developer tools, and the Elements panel is the tool you will use most while working through this one. Where this course needs one of those ideas it names it and moves on rather than teaching it again.

## The site you will build

Every example in the course belongs to one small site: **Andorinha Books**, a second-hand bookshop in Pinheiros, São Paulo. It is invented, and it was chosen because a bookshop needs a bit of everything: a home page, a list of events, a form for ordering a book, a table of opening hours, photographs of the shelves, and a layout that has to work on the phone of somebody standing outside the shop. Each lesson adds the part it teaches.

The pages are files you write, in one folder on your own computer, and the next section sets that folder up. Each lesson shows every page it uses, whole, in the section that uses it. You open a page by double-clicking it: a browser reads an HTML file from your disk exactly as it reads one from a server, which is all this course needs.

## How this course measures a page

The output of HTML and CSS is a **picture**, and a picture is awkward to quote. "The card is narrower than the one beside it" is a description; it is not something you can check. So every claim this course makes about what the browser did is a measurement, printed by a small program called `probe`.

`probe` opens a page in Chromium, the engine inside Chrome and Edge, and asks it the questions the Elements panel answers when you click on something: where is this box, how wide is it, what colour did this rule finally give it, what would a screen reader announce here. It prints the answers as text. Here it is opening this lesson's first page and printing its title and what assistive technology sees in it:

```
ana@laptop:~/site$ probe skeleton.html title tree
title: "Andorinha Books"
- heading "Andorinha Books" [level=1]
- paragraph: Second-hand books in Pinheiros, São Paulo.
```

**`probe` is the course's measuring instrument, not something you install.** It is a few hundred lines of JavaScript that drive Chromium through Playwright, a browser-testing library. It exists so that the numbers in these lessons are numbers a browser printed rather than numbers somebody expected. You do not type the lines that start with `probe`: the output is the point. Everything it prints, you can read in DevTools on your own page, by clicking on the element and looking at the **Computed** tab and the box diagram beside it, and the course tells you where to look each time. The lines that do not start with `probe`, the validator in section 13 and Tailwind in lesson 13, are commands you run yourself.

## The questions are about predicting the browser

A page is checked by looking at it, and nothing in this platform can look at a page you wrote and say whether it is right. So the questions in these lessons ask the other half of the skill: **given this HTML and this CSS, what will the browser do?** How wide will that box be, which rule wins, which element is on top at that point. Those have one right answer, and it is the answer `probe` printed.

That is not a lesser exercise. The difference between somebody who writes CSS by trying things until it looks right and somebody who writes it on purpose is exactly this: the second person can predict the result before reloading. The building you do in your own browser, starting from the pages each lesson shows.

## Where this course sits in your track

::: track frontend
In your track this is the first paid course, straight after `web-fundamentals`, and everything after it renders into what it teaches. `javascript` comes next and spends much of its time changing the DOM this course builds; the framework you pick at the fork generates HTML and attaches CSS to it. Lessons 8, 9 and 11, on Flexbox, Grid and responsiveness, are the ones a front-end interview will test.
:::

::: track backend
In your track this course comes before you choose a server language, and that is deliberate. A back-end developer sends HTML, renders templates and reads bug reports that say "the page is broken", so you need to know what a correct page is. Lessons 1 to 4, on HTML, matter most for your work; lesson 3, on forms, is exactly what arrives at your server as a request.
:::

::: track qa
In your track you reach this course after `manual-testing`, and its value to you is knowing what you are looking at. A tester who can read the HTML of a form, the accessibility tree of a page and the CSS rule that hid a button writes a bug report a developer can act on. `web-automation` comes after `javascript` and finds every element by the selectors lesson 5 teaches.
:::

::: track *
Lessons 1 to 4 are HTML and lessons 5 to 13 are CSS. If you only have time for some of it, lessons 2, 5, 8 and 11 are the ones every later front-end course assumes: semantic structure, how a rule wins, Flexbox and responsiveness.
:::
