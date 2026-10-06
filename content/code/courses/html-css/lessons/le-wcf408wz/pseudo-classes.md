---
title: States and positions: pseudo-classes
version: 1
---

A **pseudo-class** selects elements by something that is not written in the HTML: a state they are in, such as being hovered or focused, or their position among their siblings. It is written with one colon: `a:hover`. Here are the ones that do the most work, in `states.css`:

```css
.event:nth-child(odd) { background: #f4f1ea; }
.event:not(.cancelled) h2 { color: #2f6f4e; }
.event:has(.note) { border-left: 4px solid #7a5c00; }
.more:hover { text-decoration: none; }
.more:focus-visible { outline: 3px solid #7a5c00; }
```

## Position: `:nth-child()`

```
ana@laptop:~/site$ probe states.html style .event background-color
article.event  background-color: rgb(244, 241, 234)
article.event.featured  background-color: rgba(0, 0, 0, 0)
article.event.cancelled  background-color: rgb(244, 241, 234)
ana@laptop:~/site$ probe states.html style '.event h2' color style .event border-left-width
h2  color: rgb(47, 111, 78)
h2  color: rgb(47, 111, 78)
h2  color: rgb(0, 0, 0)
article.event  border-left-width: 4px
article.event.featured  border-left-width: 0px
article.event.cancelled  border-left-width: 0px
```

`.event:nth-child(odd)` gave a background to the **first and third** articles, and the reason deserves care. `:nth-child()` counts **all** the element's siblings, not only the ones with the class. Inside `<main>`, the `<h1>` is child 1 and the intro paragraph child 2, so the articles are children 3, 4 and 5, and the odd ones are 3 and 5. The selector reads as "an element that is an odd-numbered child, and also has the class `event`". When you mean "every other event", put the events in their own container, which is what a list or a `<div>` of cards is for.

## Logic: `:not()`, `:is()`, `:has()`

`.event:not(.cancelled) h2` coloured the headings of the two events that are not cancelled, and left the third at the default black. `:not()` takes a selector and matches what it does not. `:is(h1, h2, h3)` matches any one of a list, and keeps long selectors short. And **`:has()`** matches an element by what it contains: `.event:has(.note)` gave a border only to the article with a note inside it. For twenty years CSS could not select a parent by its children, and `:has()` is the answer, available in every major browser since the end of 2023.

## State: `:hover`, `:focus-visible`, `:user-invalid`

```
ana@laptop:~/site$ probe states.html style .more text-decoration-line hover .more style .more text-decoration-line
a.more  text-decoration-line: underline
a.more  text-decoration-line: none
```

Under the pointer, the link lost its underline. Now the keyboard:

```
ana@laptop:~/site$ probe states.html tab style .more outline-style,outline-width
focus: a "How the swap works"
a.more  outline-style: solid
a.more  outline-width: 3px
```

**`:focus-visible` matched when the link was reached with Tab**, and drew a 3-pixel outline. It matches when the browser judges that a focus ring is needed, which means keyboard focus and not a mouse click, and that is why it is the one to use. **Never remove the focus outline without putting another in its place**: `outline: none` alone makes a page unusable by keyboard, because nobody can see where they are.

Lesson 3 section 08 said CSS can mark a field the browser considers invalid. There are two pseudo-classes for it, and the difference is the whole point:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>Newsletter · Andorinha Books</title>
    <style>
      input { border: 2px solid #767676; }
      input:invalid { background: #fff4f4; }
      input:user-invalid { border-color: #8a1c1c; }
    </style>
  </head>
  <body>
    <main>
      <h1>Newsletter</h1>
      <form action="subscribe">
        <label for="email">Email</label>
        <input id="email" name="email" type="email" required>
        <button>Subscribe</button>
      </form>
    </main>
  </body>
</html>
```

```
ana@laptop:~/site$ probe signup.html style input border-top-color,background-color fill input ana@ press Tab style input border-top-color,background-color
input#email  border-top-color: rgb(118, 118, 118)
input#email  background-color: rgb(255, 244, 244)
input#email  border-top-color: rgb(138, 28, 28)
input#email  background-color: rgb(255, 244, 244)
```

Before anybody typed, the empty required field already matched **`:invalid`**, and was pink. That is a form that greets its reader with an error. **`:user-invalid`** matched only after Ana had typed `ana@` and moved on, and only then did the border turn red. Style errors with `:user-invalid`, and keep the message in words beside the field.
