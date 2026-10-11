---
title: An error that can be heard
version: 1
---

Defect 8 is the red border, and it fails twice. For someone who does not see red as red, the
field looks the same before and after, which is *1.4.1 Use of Color*. For a screen reader user,
nothing happened at all: the tree did not change, so the reader had nothing to say, and the user
presses Book, hears nothing, and does not know whether a seat was booked. That is *3.3.1 Error
Identification*, level A: an error that is detected is identified to the user **in text**.

## Live regions

A screen reader reads what the user moves to. A message that appears somewhere else on the page,
while the focus stays where it was, goes unread unless the page asks for it to be announced. **A
live region is how the page asks**: an element marked so that the browser tells assistive
technology whenever its content changes.

| markup | how it is announced | for |
|---|---|---|
| `role="status"`, or `aria-live="polite"` | when the reader has finished what it is saying | a result, a count, "booked" |
| `role="alert"`, or `aria-live="assertive"` | straight away, interrupting | an error the user must deal with now |

*4.1.3 Status Messages*, level AA since WCAG 2.1, is the criterion behind both: a message that
reports a result without moving the focus has to be announced through a role or property like
these. **The region must already be in the page, empty, when the message arrives.** A live region
inserted together with its text is often not announced at all, because there was no region to
watch until that moment.

## book4.html

The fix goes into a fourth file. `nano book4.html` in `~/boxoffice/static`:

```html
<!-- boxoffice/static/book4.html -->
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Book a seat</title>
<style>
  body { font-family: sans-serif; max-width: 36rem; margin: 2rem auto; color: #222; }
  nav a { margin-right: 1rem; color: #7a1f2b; }
  .note { color: #767676; }
  :focus-visible { outline: 3px solid #1a5fb4; outline-offset: 2px; }
  .skip { position: absolute; left: -999px; }
  .skip:focus { left: 1rem; top: 1rem; background: #fff; padding: .4rem; }
  .book { padding: .6rem 1.4rem; border: 0; background: #7a1f2b; color: #fff;
          font: inherit; cursor: pointer; }
  [aria-invalid="true"] { border: 2px solid #d00; }
  .error { color: #b00; font-weight: bold; }
</style>
</head>
<body>
<a class="skip" href="#main">Skip to the booking form</a>
<img src="logo.svg" width="200" height="48" alt="boxoffice">
<nav><a href="/shows">What's on</a> <a href="/prices">Prices</a> <a href="/access">Access</a></nav>
<main id="main" tabindex="-1">
<h1>Book a seat</h1>
<p class="note">Seats are held for ten minutes. The price includes the booking fee.</p>
<form id="book" onsubmit="event.preventDefault(); book()">
  <p><label for="show">Show</label><br><select id="show"></select></p>
  <p><label for="seat">Seat</label><br><input id="seat" type="number" min="1" max="300" value="1"></p>
  <p><label for="customer">Your name</label><br>
     <input id="customer" autocomplete="name" aria-describedby="customer-error">
     <span id="customer-error" class="error" role="alert"></span></p>
  <button class="book">Book</button>
</form>
<p id="result" role="status"></p>
</main>
<script>
fetch("/shows").then(r => r.json()).then(shows => {
  for (const s of shows) document.getElementById("show").add(new Option(`${s.title}, ${s.day}`, s.id));
});
async function book() {
  const name = document.getElementById("customer");
  const missing = name.value.trim() === "";
  name.setAttribute("aria-invalid", missing);
  document.getElementById("customer-error").textContent =
    missing ? "Error: type the name the tickets are for." : "";
  if (missing) return name.focus();
  const answer = await fetch("/bookings", { method: "POST", body: JSON.stringify({
    show_id: document.getElementById("show").value,
    seat: document.getElementById("seat").value, customer: name.value }) });
  const body = await answer.json();
  document.getElementById("result").textContent =
    answer.ok ? `Booked: seat ${body.seat}, booking ${body.id}.` : `Not booked: ${body.error}.`;
}
</script>
</body>
</html>
```

Against `book3.html`:

```
ana@nft:~/boxoffice/static$ diff book3.html book4.html
1c1
< <!-- boxoffice/static/book3.html -->
---
> <!-- boxoffice/static/book4.html -->
17c17,18
<   .wrong { border: 2px solid #d00; }
---
>   [aria-invalid="true"] { border: 2px solid #d00; }
>   .error { color: #b00; font-weight: bold; }
30c31,33
<   <p><label for="customer">Your name</label><br><input id="customer"></p>
---
>   <p><label for="customer">Your name</label><br>
>      <input id="customer" autocomplete="name" aria-describedby="customer-error">
>      <span id="customer-error" class="error" role="alert"></span></p>
33c36
< <p id="result"></p>
---
> <p id="result" role="status"></p>
41,42c44,48
<   name.classList.toggle("wrong", name.value.trim() === "");
<   if (name.value.trim() === "") return;
---
>   const missing = name.value.trim() === "";
>   name.setAttribute("aria-invalid", missing);
>   document.getElementById("customer-error").textContent =
>     missing ? "Error: type the name the tickets are for." : "";
>   if (missing) return name.focus();
```

- An empty `<span role="alert">` sits beside the field from the start, and the script writes the
  error into it. The message begins with the word **"Error:"**, so the colour is no longer the
  only thing that carries it, and it says what to do, which is *3.3.3 Error Suggestion* at AA.
- `aria-describedby` ties the message to the field, so it is the field's **description** as well
  as an announcement: a user who tabs back to the field later hears it again.
- `aria-invalid` is set on the field while the name is missing. It is a state, so the reader can
  announce the field as invalid, and the red border now hangs off the same attribute in the CSS,
  so what is seen and what is heard cannot disagree.
- The focus moves to the field, where the user has to type.
- `<p id="result" role="status">` does the same for the result: "Booked: seat 20" is announced
  politely, without moving the focus.

## The tree, after

```
ana@nft:~/a11y$ node tree.js http://localhost:8000/book4.html
- link "Skip to the booking form":
  - /url: "#main"
- img "boxoffice"
- navigation:
  - link "What's on":
    - /url: /shows
  - link "Prices":
    - /url: /prices
  - link "Access":
    - /url: /access
- main:
  - heading "Book a seat" [level=1]
  - paragraph: Seats are held for ten minutes. The price includes the booking fee.
  - paragraph:
    - text: Show
    - combobox "Show":
      - option "Hamlet, 2027-10-02" [selected]  (and 19 more)
  - paragraph:
    - text: Seat
    - spinbutton "Seat": "1"
  - paragraph:
    - text: Your name
    - textbox "Your name"
    - alert
  - button "Book"
  - status

After Book with no name, the tree gains:
    - alert: "Error: type the name the tickets are for."
```

The empty `alert` and `status` are there on load, which is what makes them live regions rather
than late arrivals. **After the empty submission the tree gains the alert with its text**, which
is the line a screen reader turns into speech. Two things this transcript does not show, because
`ariaSnapshot()` does not print them: the `aria-invalid` state on the field, and its description.
Both are in the tree; checking that a real reader announces them is what the charter in the next
section is for.

And the automated audit, once more:

```
ana@nft:~/a11y$ node audit.js http://localhost:8000/book4.html
0 violations; to review by hand: none
```

Zero, as it was for `book2.html` and `book3.html`: three pages that are very different to use, and
identical to the tool.
