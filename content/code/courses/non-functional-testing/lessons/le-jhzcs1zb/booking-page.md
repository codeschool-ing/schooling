---
title: The booking page
version: 1
---

The four lessons of this third audit one page and repair it. **It is the box office's booking
page, and it is written badly on purpose**: eight defects of the kind a real team ships every
week, each one invisible to somebody who uses a mouse and can see the screen. It is plain HTML
with a small script, and the box office from lesson 1 serves it: `app.py` hands out any file
under `~/boxoffice/static/`, and the script on the page talks to the same `/shows` and
`/bookings` the load tests used.

Make the directory and open the first file:

```sh
mkdir -p ~/boxoffice/static && cd ~/boxoffice/static
nano logo.svg
```

The logo is a picture of a word, which matters in a moment:

```xml
<!-- boxoffice/static/logo.svg -->
<svg xmlns="http://www.w3.org/2000/svg" width="200" height="48" viewBox="0 0 200 48">
  <rect width="200" height="48" rx="6" fill="#7a1f2b"/>
  <text x="100" y="31" font-size="20" font-weight="bold" fill="#fff"
        text-anchor="middle">boxoffice</text>
</svg>
```

Then `nano book.html`, and the page itself. The copy button takes the whole file without the
notes, and the notes name each defect with the success criterion it fails.

```schooling-example
{"language": "html", "file": "boxoffice/static/book.html", "parts": [{"code": "<!-- boxoffice/static/book.html -->\n<!doctype html>\n<html>\n<head>\n<meta charset=\"utf-8\">\n<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">\n<title>Book a seat</title>", "note": "The head of an ordinary page, with a title and a viewport. **Defect 1**: `<html>` has no `lang`, so a screen reader guesses which language to speak the page in, and guesses with the user's own settings (3.1.1 Language of Page, A)."}, {"code": "<style>\n  body { font-family: sans-serif; max-width: 36rem; margin: 2rem auto; color: #222; }\n  nav a { margin-right: 1rem; color: #7a1f2b; }\n  .note { color: #999; }\n  *:focus { outline: none; }\n  .book { display: inline-block; padding: .6rem 1.4rem; background: #7a1f2b; color: #fff;\n          cursor: pointer; }\n  .wrong { border: 2px solid #d00; }\n</style>", "note": "**Defect 2**: the note is `#999` on white, a pale grey that looks tidy and is hard to read (1.4.3 Contrast, AA). **Defect 3**: `*:focus { outline: none; }` deletes the ring that shows which control has the keyboard (2.4.7 Focus Visible, AA). `.wrong` is the red border the script puts on a field left empty."}, {"code": "</head>\n<body>\n<img src=\"logo.svg\" width=\"200\" height=\"48\">\n<nav><a href=\"/shows\">What's on</a> <a href=\"/prices\">Prices</a> <a href=\"/access\">Access</a></nav>\n<h1>Book a seat</h1>\n<p class=\"note\">Seats are held for ten minutes. The price includes the booking fee.</p>", "note": "**Defect 4**: the logo is an image with no `alt`, and its only content is a word (1.1.1 Non-text Content, A). The three links lead to pages this small box office does not have; they are there because a real header has links, and lesson 14 tabs through them."}, {"code": "<form id=\"book\">\n  <p><label for=\"show\">Show</label><br><select id=\"show\"></select></p>\n  <p><label for=\"seat\">Seat</label><br><input id=\"seat\" type=\"number\" min=\"1\" max=\"300\" value=\"1\"></p>\n  <p>Your name<br><input id=\"customer\" tabindex=\"1\"></p>\n  <div class=\"book\" onclick=\"book()\">Book</div>\n</form>\n<p id=\"result\"></p>", "note": "**Defect 5**: \"Your name\" is text beside the field, not a `<label>` tied to it, so the field has no name (1.3.1 Info and Relationships, 4.1.2 Name, Role, Value, both A). **Defect 6**: `tabindex=\"1\"` sends the keyboard to that field before anything else on the page (2.4.3 Focus Order, A). **Defect 7**: Book is a `<div>` with a click handler. It looks like a button and answers a mouse, but it cannot take the focus and has no role (2.1.1 Keyboard, 4.1.2, both A)."}, {"code": "<script>\nfetch(\"/shows\").then(r => r.json()).then(shows => {\n  for (const s of shows) document.getElementById(\"show\").add(new Option(`${s.title}, ${s.day}`, s.id));\n});\nasync function book() {\n  const name = document.getElementById(\"customer\");\n  name.classList.toggle(\"wrong\", name.value.trim() === \"\");\n  if (name.value.trim() === \"\") return;\n  const answer = await fetch(\"/bookings\", { method: \"POST\", body: JSON.stringify({\n    show_id: document.getElementById(\"show\").value,\n    seat: document.getElementById(\"seat\").value, customer: name.value }) });\n  const body = await answer.json();\n  document.getElementById(\"result\").textContent =\n    answer.ok ? `Booked: seat ${body.seat}, booking ${body.id}.` : `Not booked: ${body.error}.`;\n}\n</script>\n</body>\n</html>", "note": "The script fills the list of shows from `/shows` and sends the booking to `POST /bookings`, the same endpoint lesson 1 tested with `curl`. **Defect 8**: an empty name turns the field's border red and says nothing else, so the error exists only as a colour (1.4.1 Use of Color, 3.3.1 Error Identification, both A)."}]}
```

## Serving it

Start the box office the way lesson 1 does, from `~/boxoffice`, in a terminal of its own:

```sh
cd ~/boxoffice && python3 seed.py && python3 app.py
```

The fresh database matters for lessons 14 and 15, whose scripts book particular seats. From the
second terminal, ask for the two files. `-D -` prints the headers and `-o /dev/null` throws the
body away; `curl -I` would send a `HEAD` request, which this small server does not answer.

```
ana@nft:~/boxoffice$ curl -s -D - -o /dev/null localhost:8000/book.html
HTTP/1.1 200 OK
Server: BaseHTTP/0.6 Python/3.12.3
Date: Sat, 10 Oct 2026 07:42:35 GMT
Content-Type: text/html; charset=utf-8
Content-Length: 1907
Server-Timing: db;dur=0.0, pay;dur=0.0, total;dur=1.0

ana@nft:~/boxoffice$ curl -s -D - -o /dev/null localhost:8000/logo.svg
HTTP/1.1 200 OK
Server: BaseHTTP/0.6 Python/3.12.3
Date: Sat, 10 Oct 2026 07:42:35 GMT
Content-Type: image/svg+xml
Content-Length: 299
Server-Timing: db;dur=0.0, pay;dur=0.0, total;dur=0.6
```

The page arrives as `text/html` and the logo as `image/svg+xml`, the two types `app.py` knows for
those suffixes. To see the page in your own browser, restart the server with
`BOXOFFICE_HOST=0.0.0.0` as lesson 1 explains and open `book.html` at the VM's address. It looks
fine. That is the point: **every defect on the list is a defect for somebody else.**

## The eight defects

| | defect | who meets it | criterion |
|---|---|---|---|
| 1 | no `lang` on `<html>` | a screen reader user, whose reader may speak English text with Portuguese rules | 3.1.1 (A) |
| 2 | grey note, `#999` on white | anybody with low vision, or on a phone in sunlight | 1.4.3 (AA) |
| 3 | focus outline removed | every keyboard user, who can no longer see where they are | 2.4.7 (AA) |
| 4 | logo without `alt` | a screen reader user, who hears a file name or nothing | 1.1.1 (A) |
| 5 | name field without a label | a screen reader user, who reaches a text field with no name and no question | 1.3.1, 4.1.2 (A) |
| 6 | `tabindex="1"` | a keyboard user, sent to the bottom of the form first | 2.4.3 (A) |
| 7 | Book is a `<div>` | everybody without a mouse: there is no way to press it | 2.1.1, 4.1.2 (A) |
| 8 | error shown only as a red border | anybody who does not see red as red, and every screen reader user | 1.4.1, 3.3.1 (A) |

Six of the eight are level A, the floor. **None of them breaks the page for its author**, which is
why none of them is caught by a functional test: the seat is booked when the author clicks Book.
Lesson 13 hands the page to the automated tools and counts how many of the eight they find.
