---
title: Links go somewhere, buttons do something
version: 2
---

Two elements make a page interactive without a single line of CSS: `<a href>` and `<button>`. They look different by default and people style them to look alike, so the difference is easy to lose. It is simple to state: **a link takes you to another place, a button does something here**. Going to the events page is a link. Reserving a book, opening a menu, submitting a form are buttons.

The choice matters because each element comes with behaviour you would otherwise have to build. Here is a page with three controls: a `<div>` styled to look like a button, a real `<button>` and a link. Both "buttons" call the same function, which writes *Reserved.* on the page.

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>Reserve · Andorinha Books</title>
    <link rel="stylesheet" href="controls.css">
  </head>
  <body>
    <main>
      <h1>Grande Sertão: Veredas</h1>
      <div class="button" onclick="reserve()">Reserve (div)</div>
      <button type="button" onclick="reserve()">Reserve (button)</button>
      <a href="shelf.html">Back to the shelf</a>
      <p id="status"></p>
    </main>
    <script>
      function reserve() {
        document.getElementById('status').textContent = 'Reserved.';
      }
    </script>
  </body>
</html>
```

Save it as `controls.html`, and beside it `controls.css`, which is what makes the `<div>` look like a button:

```css
.button {
  display: inline-block;
  padding: 0.4em 0.8em;
  background: #2f6f4e;
  color: white;
  cursor: pointer;
}
```

Clicked with a mouse, the two buttons behave identically. The accessibility tree is the first sign that they are not:

```
ana@laptop:~/site$ probe controls.html tree
- main:
  - 'heading "Grande Sertão: Veredas" [level=1]'
  - text: Reserve (div)
  - button "Reserve (button)"
  - link "Back to the shelf":
    - /url: shelf.html
  - paragraph
```

The `<button>` is a **button** named *Reserve (button)*. The `<div>` is **text**: a screen reader user hears the words and has no idea anything happens if they activate them. Then the keyboard, which is how people who cannot use a mouse, and many who simply prefer not to, get around a page. Tab moves the focus from one control to the next, and Enter activates the one that has it:

```
ana@laptop:~/site$ probe controls.html tab press Enter text "#status" tab tab
focus: button "Reserve (button)"
p#status  "Reserved."
focus: a "Back to the shelf"
focus: body (nothing left to focus)
```

The first Tab went to the `<button>`, and Enter reserved the book. The next went to the link. The next fell off the end of the page, and **the `<div>` was never reached**. To somebody using a keyboard, the first control on the page does not exist.

## What a `<button>` brings that a `<div>` does not

To make the `<div>` behave like a button you would need: `role="button"` so the tree says what it is, `tabindex="0"` so it can be focused, a key handler for Enter *and* for Space, because buttons answer both, a visible focus style, and a disabled state when needed. That is five things to remember and get right on every one of them. `<button>` has all of them already, and they are correct in every browser.

The same goes for links: `<a href>` is focusable, opens with Enter, shows its address on hover, can be opened in a new tab and is announced as a link. A `<span>` with a click handler that changes the page does none of it, and an `<a>` without `href` is not focusable either.

**A `<button>` inside a form submits the form by default.** Lesson 3 is about forms, and section 06 there is about exactly this; for a button that does something other than submit, write `type="button"`, as the page above does.
