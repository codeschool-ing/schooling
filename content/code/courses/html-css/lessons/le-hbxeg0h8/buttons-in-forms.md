---
title: Buttons in a form
version: 1
---

Lesson 2 ended with a warning that this section explains: **a `<button>` inside a form submits the form, unless it says otherwise.** The `type` attribute of a button has three values:

- `submit`, the default: sends the form.
- `button`: does nothing on its own, for a script to give it a job.
- `reset`: puts every field back to its starting value, which almost nobody wants and which deletes somebody's typing with one mistaken click. Leave it out.

Here is a reserve form with three buttons. The first has no `type`; the second says `type="button"`; the third is the real submit.

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>Reserve · Andorinha Books</title>
  </head>
  <body>
    <main>
      <h1>Reserve a book</h1>
      <form action="reserve" method="get">
        <label for="title">Title</label>
        <input id="title" name="title">
        <button class="check">Check the shelf</button>
        <button type="button" class="check2">Check the shelf (type="button")</button>
        <button type="submit" class="go">Reserve</button>
      </form>
    </main>
  </body>
</html>
```

```
ana@laptop:~/site$ probe buttons.html fill '#title' 'Vidas Secas' send .check2
nothing was sent
ana@laptop:~/site$ probe buttons.html fill '#title' 'Vidas Secas' send .check
GET /reserve?title=Vidas+Secas
```

The `type="button"` sent nothing. The first one, written by somebody who only wanted a button to check the shelf, **sent the whole form**: its missing `type` made it a submit button. A script attached to it would run and then the page would navigate away, which is the bug people meet as "my button reloads the page".

## Enter sends the form too

A form also submits when somebody presses Enter in a single-line text field, if the form has a submit button. This is **implicit submission**, and it is how most people send a search:

```
ana@laptop:~/site$ probe buttons.html fill '#title' 'Vidas Secas' focus '#title' press Enter fetched
reserve?title=Vidas+Secas
```

The browser looks for the form's first submit button and acts as if it had been pressed. That is one more reason the first button in a form should be the real one, or should say `type="button"` if it is not: Enter presses whichever submit button comes first.

## A button says what it does

The text on a submit button is its accessible name, like any button's. *Send the order*, *Reserve*, *Search the shelves* tell the reader what will happen; *Submit* and *OK* tell them that something will. An `<input type="submit" value="…">` also makes a submit button, and you will see it in older code; `<button>` can contain other elements, such as an icon beside the text, which is why it is the one used today.
