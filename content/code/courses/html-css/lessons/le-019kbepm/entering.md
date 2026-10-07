---
title: Animating something that appears
version: 2
---

Section 05 said `display` cannot be transitioned: there is no value between `none` and `block`. That used to make it impossible to fade in something that appears by changing its `display`, a toast, a dropdown, a dialog, and it is the case that matters most. Two recent features fix it:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Andorinha Books</title>
    <style>
      body { margin: 16px; font-family: system-ui, sans-serif; }
      .toast {
        display: none;
        opacity: 0;
        transition: opacity 400ms linear, display 400ms allow-discrete;
      }
      .toast.open { display: block; opacity: 1; }
      @starting-style {
        .toast.open { opacity: 0; }
      }
    </style>
  </head>
  <body>
    <button type="button" onclick="document.querySelector('.toast').classList.toggle('open')">Save</button>
    <p class="toast" role="status">Saved to your list.</p>
  </body>
</html>
```

**`@starting-style`** says what an element's styles were **before it was displayed**. Without it, an element that goes from `display: none` to `block` has no previous style to transition from, so it just appears at its final opacity. With it, the browser transitions from `opacity: 0` to 1. **`transition-behavior: allow-discrete`**, written here as `display 400ms allow-discrete` inside the shorthand, lets `display` take part in the transition: on the way out it waits until the opacity has finished before switching to `none`, so the fade-out is seen too.

The button toggles the class `open` with one line of JavaScript, which the `javascript` course explains. 200 ms after a click, with the `@starting-style` block and then in `nostart.html`, a copy with that whole block deleted:

```
ana@laptop:~/site$ probe starting.html click button at 200 style .toast display,opacity
p.toast.open  display: block
p.toast.open  opacity: 0.5
ana@laptop:~/site$ probe nostart.html click button at 200 style .toast display,opacity
p.toast.open  display: block
p.toast.open  opacity: 1
```

With it, the toast is **halfway**, opacity **0.5**, the middle of a 400 ms linear fade. Without it, it is already at **1**, 200 ms early: it appeared at once, with no transition, although the transition was declared.

Both are recent, so check their support for the browsers your readers use before relying on the fade. A browser without them still shows and hides the toast, it just does not fade, which is the right way for an effect to degrade. The `<dialog>` element and the `popover` attribute are animated in exactly this way.
