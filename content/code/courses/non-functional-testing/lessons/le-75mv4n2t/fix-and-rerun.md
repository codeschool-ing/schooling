---
title: Fixing what it found, and running it again
version: 1
---

The four fixes are small, and **each one is the first item on the menu axe printed**: a `lang`,
a real `alt`, a real `<label>`, a darker grey. They go into a new file, `book2.html`, so that
`book.html` stays broken for lessons 14 and 15 to compare against. In `~/boxoffice/static`,
`nano book2.html`:

```html
<!-- boxoffice/static/book2.html -->
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
  *:focus { outline: none; }
  .book { display: inline-block; padding: .6rem 1.4rem; background: #7a1f2b; color: #fff;
          cursor: pointer; }
  .wrong { border: 2px solid #d00; }
</style>
</head>
<body>
<img src="logo.svg" width="200" height="48" alt="boxoffice">
<nav><a href="/shows">What's on</a> <a href="/prices">Prices</a> <a href="/access">Access</a></nav>
<h1>Book a seat</h1>
<p class="note">Seats are held for ten minutes. The price includes the booking fee.</p>
<form id="book">
  <p><label for="show">Show</label><br><select id="show"></select></p>
  <p><label for="seat">Seat</label><br><input id="seat" type="number" min="1" max="300" value="1"></p>
  <p><label for="customer">Your name</label><br><input id="customer" tabindex="1"></p>
  <div class="book" onclick="book()">Book</div>
</form>
<p id="result"></p>
<script>
fetch("/shows").then(r => r.json()).then(shows => {
  for (const s of shows) document.getElementById("show").add(new Option(`${s.title}, ${s.day}`, s.id));
});
async function book() {
  const name = document.getElementById("customer");
  name.classList.toggle("wrong", name.value.trim() === "");
  if (name.value.trim() === "") return;
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

`diff` shows the five lines that changed, the comment with the file's name among them:

```
ana@nft:~/boxoffice/static$ diff book.html book2.html
1c1
< <!-- boxoffice/static/book.html -->
---
> <!-- boxoffice/static/book2.html -->
3c3
< <html>
---
> <html lang="en">
11c11
<   .note { color: #999; }
---
>   .note { color: #767676; }
19c19
< <img src="logo.svg" width="200" height="48">
---
> <img src="logo.svg" width="200" height="48" alt="boxoffice">
26c26
<   <p>Your name<br><input id="customer" tabindex="1"></p>
---
>   <p><label for="customer">Your name</label><br><input id="customer" tabindex="1"></p>
```

- `lang="en"` tells the browser, and every screen reader, which language to speak.
- `alt="boxoffice"` is **the word in the picture**, because a logo's text alternative is the text it
  shows. It is not "logo", and not a description of the colours.
- `<label for="customer">` ties the words to the field, so the field has a name, and clicking the
  words puts the cursor in it.
- `#767676` is the lightest grey that reaches 4.5:1 on white, as lesson 12 computed.

Audit it:

```
ana@nft:~/a11y$ node audit.js http://localhost:8000/book2.html
0 violations; to review by hand: none
```

## Zero, and what zero means

**Zero violations means that every rule axe could run passed.** It does not mean the page
conforms to WCAG 2.2 AA, and the four defects still in `book2.html` are the proof: the `<div>`
still cannot be reached from the keyboard, the focus is still invisible, the `tabindex` still
scrambles the order, and the error is still only red. A tester who reports this run as "the page
is accessible" has reported something the tool never said.

## As a gate in the suite

The exit code turns the audit into a step a pipeline can fail on. Run it over every page, the way
a CI job would:

```
ana@nft:~/a11y$ for page in book.html book2.html; do node audit.js http://localhost:8000/$page > /dev/null && echo "$page passes" || echo "$page fails"; done
book.html fails
book2.html passes
```

This is what the platform this course is served on does with its own interface. Its suite opens
every screen, in both themes, signed in and signed out, and runs axe with the same five tags
`audit.js` uses. On its first run it found that a locked course card, drawn with reduced
opacity, took its own text to 4.09:1 in the dark theme and 3.32:1 in the light one: a colour
nobody chose, produced by an effect nobody thought of as a colour. **That is the defect a gate is
for**: one nobody would have looked for, caught on the commit that introduced it, before a
student met it.

Three habits keep a gate honest:

- **Audit the states, not only the page as it loads.** A form after a failed submit, a menu
  opened, a dialog shown: each is a different document, and axe sees only the one that existed
  when `analyze()` ran.
- **Never silence a rule to get to green.** `AxeBuilder` can disable a rule or exclude an element,
  and occasionally that is right, for a third-party widget you have reported upstream, say. Every
  exclusion is a sentence in the test saying why, or it is a hole.
- **Print `incomplete`, and give it to somebody.** A run with nothing to review is a statement
  about this page; a run with twelve items to review and a green tick is a run that passed work to
  nobody.
