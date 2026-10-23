---
title: What hydration is
version: 1
---

**Hydration is the moment a script in the browser takes over HTML that the server drew, without
drawing it again.** The page arrived finished. The text is right, the buttons are there, and none of
them does anything, because a button in HTML is only a description of a button: what happens when
it is pressed lives in JavaScript, and the JavaScript has not run yet. Hydrating is attaching that
behaviour to the elements that are already on the screen.

The planner of lessons 1 and 3 did not hydrate. Its script fetched the data again and replaced the
whole `<main>` with an identical copy of itself. That works, and it throws away the one thing server
rendering paid for, a finished page, and repeats both the request and the work.

## The three things hydration needs

To take over a page instead of redrawing it, the script must be able to answer three questions:

1. **Which data was this page drawn from?** Without it the script cannot know what the page means:
   which session a button marks done, which course the form adds to. Lesson 2's section "What each
   one sends besides the HTML" showed each framework's answer, a copy of the data inside the page.
2. **Is the HTML what I would have drawn?** If the server and the browser disagree, the script's idea
   of the page and the page on the screen are two different things. That is a **hydration
   mismatch**, and the section "A mismatch, made on purpose" makes one.
3. **Where does each piece of behaviour go?** In the planner every click goes to one listener on
   `<main>`, so the answer is trivial. A framework walks its component tree over the existing
   elements and attaches each component's handlers to the element it would have created.

```schooling-figure
@fig
```

## The window it leaves

Between the moment a server-rendered page appears and the moment hydration finishes, the page looks
ready and is not. That gap is the subject of the section "The window where clicks are lost", and it
is the main cost server rendering adds: client rendering shows nothing until the page works, and
server rendering shows a page that does not work yet. **Which is better depends on how long the
gap is**, and the gap is the time to download, parse and run the page's JavaScript, which is why
lesson 2 weighed it.
