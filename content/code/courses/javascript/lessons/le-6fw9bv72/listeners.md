---
title: Listening for events
version: 1
---

**`addEventListener(type, listener)` asks the browser to call `listener` each time an event of that
type happens on that element.** The listener receives an **event object** describing what happened:

```html
<!doctype html>
<button id="lend">Lend</button>
<script>
  const button = document.querySelector("#lend");

  function onLend(event) {
    console.log(event.type, event.target.id, event.currentTarget === button);
  }
  button.addEventListener("click", onLend);
  button.addEventListener("click", () => console.log("second listener"), { once: true });
</script>
```

```
ana@dev:~/js$ page listen.html --do 'click #lend' --do 'click #lend'
-- click #lend
click lend true
second listener
-- click #lend
click lend true
```

- `event.type` is the kind of event, `click`. **`event.target` is the element where it happened**,
  here the button; `event.currentTarget` is the element whose listener is running, which is the same
  button now and will not always be, as the next section shows;
- an element can have **any number of listeners for the same event**, and they run in the order they
  were added. The second ran on the first click only, because `{ once: true }` removes a listener
  after its first call.

## Removing a listener

```html
<!doctype html>
<button id="lend">Lend</button>
<script>
  const button = document.querySelector("#lend");
  let clicks = 0;
  function onLend() {
    clicks += 1;
    console.log("click", clicks);
    if (clicks === 2) button.removeEventListener("click", onLend);
  }
  button.addEventListener("click", onLend);
</script>
```

```
ana@dev:~/js$ page remove.html --do 'click #lend' --do 'click #lend' --do 'click #lend'
-- click #lend
click 1
-- click #lend
click 2
-- click #lend
```

`removeEventListener` with **the same function** stopped the third click. That is the rule lesson 7
spent a section on: the browser compares the function you pass with `===`, so a listener written
inline as an arrow, or made with `bind` at the call, cannot be removed later. Keep it in a name, as
`onLend` is here, if you will need to remove it.

## `onclick` and its kind

You will also see `button.onclick = fn` and `onclick="…"` written in HTML. Both are older. **An
`on…` property holds one listener**, so assigning a second replaces the first, and the HTML form puts
code in a string inside the markup. `addEventListener` has neither limit, and it is what this course
uses; the keyboard section uses the HTML form once, on purpose, to show something about a `<div>`.
