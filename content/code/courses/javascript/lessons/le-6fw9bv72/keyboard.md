---
title: The keyboard, and why a button is a button
version: 1
---

Some people never use a mouse: they move through a page with Tab and press Enter or Space to act,
or a screen reader does it for them. **An interface that only answers clicks shuts them out**, and
the fix is mostly to use the right element:

```html
<!doctype html>
<div class="fake" onclick="console.log('div clicked')">Lend (a div)</div>
<button class="real">Lend (a button)</button>
<script>
  document.querySelector(".real").addEventListener("click", () => console.log("button clicked"));
  document.addEventListener("keydown", (event) => {
    console.log("keydown:", JSON.stringify(event.key), event.code, "on", document.activeElement.tagName);
  });
</script>
```

```
ana@dev:~/js$ page keys.html --do 'press Tab' --do 'press Enter' --do 'press Space'
-- press Tab
keydown: "Tab" Tab on BODY
-- press Enter
keydown: "Enter" Enter on BUTTON
button clicked
-- press Space
keydown: " " Space on BUTTON
button clicked
```

The page has a `<div>` with a click handler, styled to look like a button, and a real `<button>`.
`page` pressed Tab once, from the top of the page:

- **focus went straight to the `<button>`. The `<div>` was skipped**, because a `<div>` is not
  focusable, so a keyboard user can never reach it;
- Enter on the button and Space on the button **both fired its `click` listener**. The browser turns
  those keys into a click on a button for you; on a `<div>` it does neither, even when it has focus.

**Use `<button>` for anything that acts, and `<a href>` for anything that goes somewhere.** Both come
with focus, keyboard activation and the right announcement to a screen reader. Making a `<div>`
behave the same takes a `tabindex`, a `role`, and key handling you write yourself, and it is still
easy to get wrong. The `front-quality` course, lessons 11 and 12, takes keyboard navigation and ARIA
further.

## Reading keys

`keydown` fires for every key, on the focused element, and bubbles like a click. **`event.key` is
what the key means**, `"Enter"` or `" "` for Space or `"a"`, and depends on the keyboard layout;
**`event.code` is which physical key it was**, `Space` or `KeyA`, whatever the layout. Use `key` for
text and commands such as Escape to close; use `code` for something tied to a key's position, such as
the movement keys of a game.
