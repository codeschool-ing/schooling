---
title: The keyboard fixes
version: 1
---

Four changes make the booking page work from the keyboard, and they go into a third file,
`book3.html`, beside the other two. In `~/boxoffice/static`, `nano book3.html`:

```html
<!-- boxoffice/static/book3.html -->
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
  .wrong { border: 2px solid #d00; }
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
  <p><label for="customer">Your name</label><br><input id="customer"></p>
  <button class="book">Book</button>
</form>
<p id="result"></p>
</main>
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

Against `book2.html`, the changes are these:

```
ana@nft:~/boxoffice/static$ diff book2.html book3.html
1c1
< <!-- boxoffice/static/book2.html -->
---
> <!-- boxoffice/static/book3.html -->
12,14c12,16
<   *:focus { outline: none; }
<   .book { display: inline-block; padding: .6rem 1.4rem; background: #7a1f2b; color: #fff;
<           cursor: pointer; }
---
>   :focus-visible { outline: 3px solid #1a5fb4; outline-offset: 2px; }
>   .skip { position: absolute; left: -999px; }
>   .skip:focus { left: 1rem; top: 1rem; background: #fff; padding: .4rem; }
>   .book { padding: .6rem 1.4rem; border: 0; background: #7a1f2b; color: #fff;
>           font: inherit; cursor: pointer; }
18a21
> <a class="skip" href="#main">Skip to the booking form</a>
20a24
> <main id="main" tabindex="-1">
23c27
< <form id="book">
---
> <form id="book" onsubmit="event.preventDefault(); book()">
26,27c30,31
<   <p><label for="customer">Your name</label><br><input id="customer" tabindex="1"></p>
<   <div class="book" onclick="book()">Book</div>
---
>   <p><label for="customer">Your name</label><br><input id="customer"></p>
>   <button class="book">Book</button>
29a34
> </main>
```

- **The focus is visible again.** `*:focus { outline: none; }` is gone, and `:focus-visible` draws
  a 3-pixel blue ring, as the previous section explained.
- **Book is a `<button>`.** It is focusable, it has the role *button*, and it answers Enter and
  Space with no code for either, because the browser gives a button all of that. It sits inside
  the form, so pressing it submits the form; `onsubmit` stops the browser's own submission and
  calls `book()` instead. A bonus of using the form: Enter in the name field books as well.
- **No positive `tabindex`.** The name field takes its place in document order.
- **A skip link and a `<main>`.** The link is the first stop and jumps past the logo and the
  navigation; `<main>` is the target, with `tabindex="-1"` so that it can receive the focus. The
  `.skip` rules keep it off screen until it is focused.

The class name `.wrong` and the red border are still there. That is defect 8, and it belongs to
lesson 15.

## The same script, after

Run `python3 seed.py` in `~/boxoffice` again, so the seats `tab.js` books are free, then:

```
ana@nft:~/a11y$ node tab.js http://localhost:8000/book3.html
Tab order:
  1. link "Skip to the booking form"
  2. link "What's on"
  3. link "Prices"
  4. link "Access"
  5. combobox "Show"
  6. spinbutton "Seat": "1"
  7. textbox "Your name"
  8. button "Book"
  9. (focus left the page)
Enter on the skip link, then Tab: combobox "Show"
Keyboard, Enter on Book: Booked: seat 20, booking 295113.
Mouse, click on Book: Booked: seat 21, booking 295114.
```

**Eight stops, in reading order, each with an outline**, ending with the button. The skip link is
first, and Enter on it puts the next Tab on the Show field, past the three header links. The
keyboard books seat 20 and the mouse books seat 21, and the two lines finally say the same thing.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 400\" role=\"img\" data-fig=\"l14-tab-order\" aria-label=\"The tab order drawn over two wireframes of the booking page. On the left, book2.html: stop 1 is the name field at the bottom of the form, because of tabindex 1; stops 2 to 4 are the three header links; 5 is Show and 6 is Seat; the Book div is never reached, and no stop shows a focus outline. On the right, book3.html: stop 1 is the skip link, 2 to 4 the links, 5 Show, 6 Seat, 7 the name field and 8 the Book button, in reading order, each with a visible outline.\"><text x=\"176.0\" y=\"24.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper-dim)\">book2.html</text><rect x=\"16.0\" y=\"38.0\" width=\"320.0\" height=\"340.0\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"30.0\" y=\"76.0\" width=\"110.0\" height=\"26.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"85.0\" y=\"89.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">boxoffice</text><text x=\"65.0\" y=\"118.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">What's on</text><text x=\"140.0\" y=\"118.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">Prices</text><text x=\"208.0\" y=\"118.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">Access</text><text x=\"30.0\" y=\"164.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">Book a seat</text><text x=\"30.0\" y=\"186.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">Show</text><rect x=\"30.0\" y=\"194.0\" width=\"180.0\" height=\"20.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"30.0\" y=\"228.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">Seat</text><rect x=\"30.0\" y=\"236.0\" width=\"180.0\" height=\"20.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"30.0\" y=\"270.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">Your name</text><rect x=\"30.0\" y=\"278.0\" width=\"180.0\" height=\"20.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><rect x=\"30.0\" y=\"314.0\" width=\"70.0\" height=\"26.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"65.0\" y=\"327.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Book</text><circle cx=\"230.0\" cy=\"288.0\" r=\"9\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></circle><text x=\"230.0\" y=\"288.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">1</text><circle cx=\"65.0\" cy=\"136.0\" r=\"9\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></circle><text x=\"65.0\" y=\"136.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">2</text><circle cx=\"140.0\" cy=\"136.0\" r=\"9\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></circle><text x=\"140.0\" y=\"136.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">3</text><circle cx=\"208.0\" cy=\"136.0\" r=\"9\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></circle><text x=\"208.0\" y=\"136.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">4</text><circle cx=\"230.0\" cy=\"204.0\" r=\"9\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></circle><text x=\"230.0\" y=\"204.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">5</text><circle cx=\"230.0\" cy=\"246.0\" r=\"9\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></circle><text x=\"230.0\" y=\"246.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">6</text><text x=\"176.0\" y=\"362.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">Book: never reached</text><text x=\"544.0\" y=\"24.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper-dim)\">book3.html</text><rect x=\"384.0\" y=\"38.0\" width=\"320.0\" height=\"340.0\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"398.0\" y=\"48.0\" width=\"170.0\" height=\"20.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></rect><text x=\"483.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">Skip to the booking form</text><rect x=\"398.0\" y=\"76.0\" width=\"110.0\" height=\"26.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"453.0\" y=\"89.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">boxoffice</text><text x=\"433.0\" y=\"118.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">What's on</text><text x=\"508.0\" y=\"118.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">Prices</text><text x=\"576.0\" y=\"118.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">Access</text><text x=\"398.0\" y=\"164.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">Book a seat</text><text x=\"398.0\" y=\"186.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">Show</text><rect x=\"398.0\" y=\"194.0\" width=\"180.0\" height=\"20.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"398.0\" y=\"228.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">Seat</text><rect x=\"398.0\" y=\"236.0\" width=\"180.0\" height=\"20.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"398.0\" y=\"270.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">Your name</text><rect x=\"398.0\" y=\"278.0\" width=\"180.0\" height=\"20.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><rect x=\"398.0\" y=\"314.0\" width=\"70.0\" height=\"26.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"433.0\" y=\"327.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Book</text><circle cx=\"588.0\" cy=\"58.0\" r=\"9\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></circle><text x=\"588.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">1</text><circle cx=\"433.0\" cy=\"136.0\" r=\"9\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></circle><text x=\"433.0\" y=\"136.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">2</text><circle cx=\"508.0\" cy=\"136.0\" r=\"9\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></circle><text x=\"508.0\" y=\"136.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">3</text><circle cx=\"576.0\" cy=\"136.0\" r=\"9\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></circle><text x=\"576.0\" y=\"136.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">4</text><circle cx=\"598.0\" cy=\"204.0\" r=\"9\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></circle><text x=\"598.0\" y=\"204.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">5</text><circle cx=\"598.0\" cy=\"246.0\" r=\"9\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></circle><text x=\"598.0\" y=\"246.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">6</text><circle cx=\"598.0\" cy=\"288.0\" r=\"9\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></circle><text x=\"598.0\" y=\"288.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">7</text><circle cx=\"488.0\" cy=\"327.0\" r=\"9\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></circle><text x=\"488.0\" y=\"327.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">8</text><text x=\"544.0\" y=\"362.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">eight stops, in reading order</text></svg>", "caption": "Where Tab goes, before and after the keyboard fixes. On the left the order starts at the bottom and never reaches Book."}
```

And the automated audit, which said 0 for `book2.html` as well, says 0 again:

```
ana@nft:~/a11y$ node audit.js http://localhost:8000/book3.html
0 violations; to review by hand: none
```

**That repeated zero is the lesson in one line**: the audit could not see the difference between
the page a keyboard user cannot finish and the page they can. Only the tab walk saw it.
