---
title: Boxoffice, the application under test
version: 1
---

Every lesson of this course tests one application: **boxoffice**, the ticket office of the Vila, a
small theatre in São Paulo. It sells tickets for three shows, sends an e-mail to confirm a new
account and keeps each order moving from reserved to paid to used. It is small enough to read in
one sitting and big enough to be wrong in ten different ways, which is the point: **it carries
defects on purpose**, and the lessons find them one technique at a time. This section gives you
the two things a tester starts from, the requirements and the program, and starts it.

## The requirements

A tester never tests a program against what they imagine it should do. They test it against
something written down, and for boxoffice that is the list below, as the theatre wrote it. Every
case in this course cites one of these ids, and lesson 2 says why that matters.

| id | requirement |
|---|---|
| R1 | The home page lists every show with its date and time, its price and the seats left. Times are São Paulo time. |
| R2 | Anybody can create an account with a name of 1 to 40 characters, an e-mail address no other account uses, and a password of 8 to 64 characters. |
| R3 | A new account receives an e-mail with a link that confirms it, valid for 24 hours. Asking for a new link makes the old one stop working. |
| R4 | Somebody with an account books 1 to 6 tickets per order for one show, while seats last. Booking for a show closes one hour before it starts. |
| R5 | A ticket costs the show's price. Students pay half. A confirmed account, a member, gets 10% off, and an order of 5 or more tickets gets 15% off. Discounts do not add up: the largest one applies. |
| R6 | A new order is reserved. A reserved order can be paid or cancelled; a paid order can be used at the door, or refunded before the show starts. Cancelling or refunding gives the seats back. |
| R7 | Wrong input is answered with a sentence saying what is wrong, never with an error page. |
| R8 | Every page works on a phone screen 360 pixels wide and on a desktop, in current Chrome, Firefox, Safari and Edge. |
| R9 | Every page can be used with the keyboard alone and with a screen reader, to WCAG 2.2 level AA. |

One page is not in the list because the theatre's real system does not have it. **The outbox**,
at `/outbox`, shows every e-mail the application has sent, newest first. In production those
e-mails would leave for real inboxes; in this test build they stop there, so you can read them.
Lesson 22 is about why test environments do that and what it costs.

## The program

Make a directory for it, `boxoffice` in your home directory, and open it in your editor. In a
terminal:

```sh
mkdir ~/boxoffice
cd ~/boxoffice
```

On Windows without WSL, make the folder in File Explorer instead and open a terminal in it. Then
create a new file in that directory, paste the program below into it with the copy button on the
block, and save it. Save it as `boxoffice.py`, exactly that name:

```python
"""boxoffice: the Vila theatre's ticket office, the application this course tests.

Run it with:  python3 boxoffice.py      and open http://127.0.0.1:8000
Everything lives in memory, so stopping it and starting it again resets it.
"""
import html
import os
import random
import secrets
import traceback
from datetime import datetime, timedelta
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import parse_qs, urlparse

VERSION = "1.0"
PORT = int(os.environ.get("BOXOFFICE_PORT", "8000"))
SEED = os.environ.get("BOXOFFICE_SEED")
TOKENS = random.Random(SEED) if SEED else None

ACCOUNTS = {
    "member@example.org": {"name": "Bia Souza", "password": "correct-horse-1", "confirmed": True},
}
LINKS = {}      # confirmation token -> {"email", "expires"}
OUTBOX = []     # every e-mail the application has sent, oldest first
ORDERS = {}     # order number -> order
NEXT = [1001]

# Which action moves an order from which state to which.
MOVES = {
    "pay": ({"reserved"}, "paid"),
    "cancel": ({"reserved"}, "cancelled"),
    "use": ({"paid"}, "used"),
    "refund": ({"paid", "used"}, "refunded"),
}


def now():
    """The current time on this machine's clock, or BOXOFFICE_NOW if it is set."""
    fixed = os.environ.get("BOXOFFICE_NOW")
    moment = datetime.fromisoformat(fixed) if fixed else datetime.now().astimezone()
    return moment.astimezone().replace(tzinfo=None)


# The calendar starts on the day the application starts. Show times are
# São Paulo time, written without a zone.
TODAY = now().date()
SHOWS = {
    "S1": {"title": "The Seagull", "at": f"{TODAY} 20:00", "price": 6000, "seats": 120},
    "S2": {"title": "Hamlet", "at": f"{TODAY + timedelta(7)} 20:00", "price": 8000, "seats": 80},
    "S3": {"title": "The Little Prince", "at": f"{TODAY + timedelta(8)} 16:00", "price": 3000,
           "seats": 200},
}


def money(cents):
    reais = f"{cents // 100:,}".replace(",", ".")
    return f"R$ {reais},{cents % 100:02d}"


def token():
    if TOKENS:
        return "".join(TOKENS.choices("abcdefghjkmnpqrstuvwxyz23456789", k=16))
    return secrets.token_urlsafe(12)


def send(to, subject, body):
    OUTBOX.append({"to": to, "subject": subject, "body": body, "at": now()})


def send_link(email):
    t = token()
    LINKS[t] = {"email": email, "expires": now() + timedelta(hours=24)}
    send(email, "Confirm your account",
         f"Hello {ACCOUNTS[email]['name']},\n\nConfirm your account within 24 hours:\n"
         f"http://127.0.0.1:{PORT}/confirm?token={t}\n")


def discount(student, member, tickets):
    """The percentage off an order. Discounts do not add up; the largest one applies."""
    if student:
        return 50
    off = 0
    if member:
        off += 10
    if tickets >= 5:
        off += 15
    return off


def page(title, body, status=200):
    return status, f"""<!doctype html>
<html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{title} · Vila theatre</title>
<style>body{{font-family:sans-serif;margin:1rem}} table.shows{{width:760px}}
td,th{{text-align:left;padding:.3rem}}</style></head>
<body><h1>{title}</h1>
{body}
<p><a href="/">Shows</a> · <a href="/signup">Sign up</a> · <a href="/outbox">Outbox</a></p>
<footer>boxoffice {VERSION}</footer></body></html>
"""


def home(q):
    rows = "".join(
        f"<tr><td>{s['title']}</td><td>{s['at']}</td><td>{money(s['price'])}</td>"
        f"<td>{s['seats']}</td><td><a href=\"/book?show={k}\">Book</a></td></tr>"
        for k, s in SHOWS.items())
    return page("Shows", "<table class=\"shows\"><tr><th>Show</th><th>When</th>"
                f"<th>Price</th><th>Seats left</th><th></th></tr>{rows}</table>")


def signup_form(q, msg=""):
    return page("Sign up", f"<p class=\"msg\">{msg}</p>" + """<form method="post" action="/signup">
<p><label for="name">Name</label> <input id="name" name="name"></p>
<p><label for="email">E-mail</label> <input id="email" name="email"></p>
<p><label for="password">Password</label> <input id="password" name="password" type="password"></p>
<p><button>Create account</button></p></form>""")


def signup(f):
    name, email, password = f.get("name", ""), f.get("email", "").lower(), f.get("password", "")
    if not 1 <= len(name) <= 40:
        return signup_form({}, "Name must be 1 to 40 characters.")
    if "@" not in email or "." not in email.split("@")[-1]:
        return signup_form({}, "That is not an e-mail address.")
    if email in ACCOUNTS:
        return signup_form({}, "There is already an account with that e-mail.")
    if not 8 <= len(password) <= 64:
        return signup_form({}, "Password must be 8 to 64 characters.")
    ACCOUNTS[email] = {"name": name, "password": password, "confirmed": False}
    send_link(email)
    sent = f"Account created. We sent a link to {html.escape(email)}."
    return page("Account created", f"<p class=\"msg\">{sent}</p>")


def confirm(q):
    link = LINKS.get(q.get("token", ""))
    if not link or now() > link["expires"]:
        return page("Confirm", "<p class=\"msg\">This link is not valid.</p>", 400)
    ACCOUNTS[link["email"]]["confirmed"] = True
    return page("Confirm", "<p class=\"msg\">Your account is confirmed.</p>")


def resend(f):
    email = f.get("email", "").lower()
    if email in ACCOUNTS and not ACCOUNTS[email]["confirmed"]:
        send_link(email)
    return page("Confirm", "<p class=\"msg\">If that account exists, we sent a new link.</p>")


def outbox(q):
    mails = "".join(
        f"<article><h2>{html.escape(m['subject'])}</h2><p>To: {html.escape(m['to'])} · "
        f"{m['at']:%Y-%m-%d %H:%M}</p><pre>{html.escape(m['body'])}</pre></article>"
        for m in reversed(OUTBOX))
    return page("Outbox", mails or "<p>No e-mail has been sent.</p>")


def book_form(q, msg=""):
    show = q.get("show", "S1")
    options = "".join(
        f"<option value=\"{k}\"{' selected' if k == show else ''}>{s['title']}</option>"
        for k, s in SHOWS.items())
    return page("Book", f"<p class=\"msg\">{msg}</p>" + f"""<form method="post" action="/book">
<p><label for="email">E-mail</label> <input id="email" name="email"></p>
<p><label for="show">Show</label> <select id="show" name="show">{options}</select></p>
<p><input name="quantity" placeholder="Tickets (1 to 6)"></p>
<p><label><input type="checkbox" name="student"> Student (half price)</label></p>
<p><button>Book</button></p></form>""")


def book(f):
    email, show = f.get("email", "").lower(), f.get("show", "")
    if email not in ACCOUNTS:
        return book_form(f, "Sign up before you book.")
    if show not in SHOWS:
        return book_form(f, "There is no such show.")
    quantity = int(f.get("quantity", ""))
    if not 1 <= quantity < 6:
        return book_form(f, "You can book 1 to 6 tickets.")
    s = SHOWS[show]
    if now() > datetime.fromisoformat(s["at"]) - timedelta(hours=1):
        return book_form(f, "Booking for this show has closed.")
    if quantity > s["seats"]:
        return book_form(f, f"Only {s['seats']} seats are left.")
    off = discount("student" in f, ACCOUNTS[email]["confirmed"], quantity)
    total = s["price"] * quantity * (100 - off) // 100
    s["seats"] -= quantity
    number = NEXT[0]
    NEXT[0] += 1
    ORDERS[number] = {"email": email, "show": show, "quantity": quantity,
                      "off": off, "total": total, "state": "reserved"}
    return order({"id": str(number)}, f"Order {number} reserved.")


def order(q, msg=""):
    o = ORDERS.get(int(q.get("id", "0") or 0))
    if not o:
        return page("Order", "<p class=\"msg\">There is no such order.</p>", 404)
    buttons = "".join(f"<button name=\"action\" value=\"{a}\">{a.title()}</button> "
                      for a in MOVES)
    return page(f"Order {q['id']}", f"""<p class="msg">{msg}</p>
<p>{SHOWS[o['show']]['title']}, {o['quantity']} ticket(s), {o['off']}% off:
<strong>{money(o['total'])}</strong></p>
<p>State: <strong>{o['state']}</strong></p>
<form method="post" action="/order">
<input type="hidden" name="id" value="{q['id']}">{buttons}</form>""")


def act(f):
    o = ORDERS.get(int(f.get("id", "0") or 0))
    if not o:
        return page("Order", "<p class=\"msg\">There is no such order.</p>", 404)
    allowed, target = MOVES.get(f.get("action", ""), (set(), ""))
    if o["state"] not in allowed:
        return order(f, f"An order that is {o['state']} cannot be {f.get('action', '')}ed.")
    o["state"] = target
    if target in ("cancelled", "refunded"):
        SHOWS[o["show"]]["seats"] += o["quantity"]
    return order(f, f"Order is now {target}.")


def health(q):
    return 200, f"ok boxoffice {VERSION}\n"


GET = {"/": home, "/signup": signup_form, "/confirm": confirm, "/outbox": outbox,
       "/book": book_form, "/order": order, "/health": health}
POST = {"/signup": signup, "/resend": resend, "/book": book, "/order": act}


class Handler(BaseHTTPRequestHandler):
    def answer(self, routes, fields):
        route = routes.get(urlparse(self.path).path)
        try:
            status, body = route(fields) if route else page("Not found", "", 404)
        except Exception:
            status, body = 500, "<pre>" + html.escape(traceback.format_exc()) + "</pre>"
        data = body.encode()
        self.send_response(status)
        kind = "text/plain" if body.startswith("ok") else "text/html"
        self.send_header("Content-Type", kind + "; charset=utf-8")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def do_GET(self):
        q = {k: v[0] for k, v in parse_qs(urlparse(self.path).query).items()}
        self.answer(GET, q)

    def do_POST(self):
        size = int(self.headers.get("Content-Length", 0))
        f = {k: v[0] for k, v in parse_qs(self.rfile.read(size).decode()).items()}
        self.answer(POST, f)


if __name__ == "__main__":
    print(f"boxoffice {VERSION} on http://127.0.0.1:{PORT}  (Ctrl-C stops it)")
    ThreadingHTTPServer(("127.0.0.1", PORT), Handler).serve_forever()
```

You do not need to read it to test it, and most testers never see the code of what they test. It
is here whole for two reasons. The course gives you everything it uses, so nothing depends on a
download that may have moved. And lesson 13 reads one function of it, `discount`, to show what a
unit test is.

Three settings are read from the environment, and the course uses each once. `BOXOFFICE_PORT`
changes the port from 8000. `BOXOFFICE_NOW` pins the application's clock to a moment you choose,
which lesson 13 calls a fake clock and lesson 21 uses to show a defect that only exists on some
machines. `BOXOFFICE_SEED` makes the confirmation links come out the same on every run.

## Starting it

In the terminal, in `~/boxoffice`:

```
ana@laptop:~/boxoffice$ python3 boxoffice.py
boxoffice 1.0 on http://127.0.0.1:8000  (Ctrl-C stops it)
```

The terminal now belongs to the server, and every request it answers adds a line below that one.
**Leave it open** and open the address it printed, `http://127.0.0.1:8000`, in your browser. You
should see a page called Shows with a table of three: The Seagull tonight at 20:00, Hamlet a week
from today and The Little Prince the day after that, at 16:00. The dates come from the day you
start the program, so yours are not the ones in this course's transcripts.

When a lesson asks you to check something from the terminal, open a **second** terminal and type
there. The first thing to ask is whether the server is up at all:

```
ana@laptop:~$ curl http://127.0.0.1:8000/health
ok boxoffice 1.0
```

`curl` sends one request and prints the answer, and that line is the whole of `/health`'s answer.
Lesson 8 builds a smoke test on it.

**To reset the application, stop it and start it again.** Ctrl-C in its terminal stops it;
`python3 boxoffice.py` starts it with three shows, full seats, no orders and one account, the
member `member@example.org` with the password `correct-horse-1`. Nothing survives a restart,
and every lesson that books or signs up assumes you started from there.
