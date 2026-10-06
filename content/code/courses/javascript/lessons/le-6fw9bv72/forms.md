---
title: Forms
version: 1
---

A form gathers fields and sends them together. **Listen for `submit` on the form, not `click` on its
button**: `submit` also fires when somebody presses Enter in a field, and it fires only after the
browser has checked the fields:

```html
<!doctype html>
<form id="loan">
  <label>Reader <input name="reader" required minlength="3"></label>
  <label>Copies <input name="copies" type="number" min="1" max="5" value="1"></label>
  <button>Lend</button>
</form>
<script>
  const form = document.querySelector("#loan");

  form.addEventListener("submit", (event) => {
    event.preventDefault();
    const data = new FormData(form);
    console.log("submitted:", JSON.stringify(Object.fromEntries(data)));
  });

  form.addEventListener("invalid", (event) => {
    console.log("invalid:", event.target.name, "-", event.target.validationMessage);
  }, { capture: true });

  form.elements.reader.addEventListener("input", (e) => console.log("input:", e.target.value));
  form.elements.reader.addEventListener("change", (e) => console.log("change:", e.target.value));
</script>
```

```
ana@dev:~/js$ page form.html --do 'click button'
-- click button
invalid: reader - Please fill out this field.
```

```
ana@dev:~/js$ page form.html --do 'fill [name=reader] an' --do 'click button'
-- fill [name=reader] an
-- click button
input: an
change: an
invalid: reader - Please lengthen this text to 3 characters or more (you are currently using 2 characters).
```

```
ana@dev:~/js$ page form.html --do 'focus [name=reader]' --do 'press a' --do 'press n' --do 'press a' --do 'press Tab' --do 'fill [name=copies] 3' --do 'click button'
-- focus [name=reader]
-- press a
input: a
-- press n
input: an
-- press a
input: ana
-- press Tab
change: ana
-- fill [name=copies] 3
-- click button
submitted: {"reader":"ana","copies":"3"}
```

## The browser checks first

`required` and `minlength="3"` on the reader field, and `min`/`max` on the copies, are **constraint
validation**: rules the browser checks before it fires `submit`. The first two runs never reached the
script's `submit` listener. The browser fired `invalid` on the field instead, with a
`validationMessage` it wrote itself, and showed that message beside the field. **Checking in HTML
costs nothing and works before any of your code runs**, which is why it comes first; the server must
check again anyway, because a request can be made without the page.

## Reading every field at once

`new FormData(form)` collects every named field, and `Object.fromEntries` (lesson 5) turned it into a
plain object. **Every value came back a string, `"3"` included**, the lesson 2 rule about form fields;
convert before calculating.

## `input` and `change`

Typed one key at a time, the reader field fired **`input` after every key**, with the value so far,
and **`change` once, when focus left the field**. Use `input` for something that reacts as the user
types, such as a search box, and `change` for something that should wait until they have finished.

## Your own rules

```html
<!doctype html>
<form id="loan">
  <input name="reader" value="bia">
  <button>Lend</button>
</form>
<script>
  const blocked = new Set(["bia"]);
  const form = document.querySelector("#loan");
  const reader = form.elements.reader;

  form.addEventListener("submit", (event) => {
    event.preventDefault();
    reader.setCustomValidity(blocked.has(reader.value) ? "this reader has a book overdue" : "");
    if (!form.reportValidity()) {
      console.log("refused:", reader.validationMessage);
      return;
    }
    console.log("lent to", reader.value);
  });
</script>
```

```
ana@dev:~/js$ page custom.html --do 'click button' --do 'fill [name=reader] ana' --do 'click button'
-- click button
refused: this reader has a book overdue
-- fill [name=reader] ana
-- click button
```

`setCustomValidity` adds a rule the HTML cannot express: this reader has a book overdue. The first
submit was refused, as intended. **The second, with a good name, printed nothing at all**: the custom
message was still set, so the browser refused the form before the `submit` listener could run and
clear it. A message set with `setCustomValidity` stays until something clears it:

```
ana@dev:~/js$ page custom-fixed.html --do 'click button' --do 'fill [name=reader] ana' --do 'click button'
-- click button
refused: this reader has a book overdue
-- fill [name=reader] ana
-- click button
lent to ana
```

One line fixed it: **clear the custom message on `input`**, so each edit starts from valid and the
check runs again on submit.
