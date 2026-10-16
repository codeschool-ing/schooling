---
title: Generating data with a short script
version: 1
---

A tester who needs five accounts can sign up five times by hand, and should, once: it is how the
sign-up form gets tested. The sixth time it is typing, not testing, and by the fiftieth the typing
is where the mistakes are. **Generated data is data a program invents to a rule you write down, so
that it comes out the same every time, in any quantity, and with nobody's details in it.** This
section gives you a program that does it for boxoffice, runs it, and reads what it made.

## The program

It does three things: invents a number of accounts, saves them in a CSV file so you know exactly
what was created, and signs each one up in boxoffice through the same form a browser posts. Create
a new file in your `boxoffice` directory, paste the program into it, and save it.
Save it as `make_accounts.py`, exactly that name:

```python
"""make_accounts.py: invent test accounts, save them as CSV and sign them up in boxoffice.

    python3 make_accounts.py 5        five accounts, into accounts.csv and into boxoffice
"""
import csv
import random
import re
import sys
from urllib.parse import urlencode
from urllib.request import urlopen

FIRST = ["Ana", "Bruno", "Caio", "Débora", "Enzo", "Fernanda", "Gustavo", "Helena", "Iara", "João"]
LAST = ["Almeida", "Barbosa", "Cardoso", "Duarte", "Esteves", "Farias", "Gonçalves", "Machado"]
LETTERS = "abcdefghijkmnpqrstuvwxyz23456789"

count = int(sys.argv[1]) if len(sys.argv) > 1 else 5
rng = random.Random(1)                  # the same seed makes the same accounts on every run

rows = []
for n in range(1, count + 1):
    first, last = rng.choice(FIRST), rng.choice(LAST)
    rows.append({
        "name": f"{first} {last}",
        "email": f"test{n:03d}@example.org",       # example.org belongs to nobody
        "password": "".join(rng.choices(LETTERS, k=rng.randint(8, 16))),
    })

with open("accounts.csv", "w", newline="", encoding="utf-8") as f:
    writer = csv.DictWriter(f, fieldnames=["name", "email", "password"])
    writer.writeheader()
    writer.writerows(rows)

for row in rows:
    form = urlencode(row).encode()
    with urlopen("http://127.0.0.1:8000/signup", data=form) as answer:
        page = answer.read().decode()
    message = re.search(r'class="msg">([^<]*)', page).group(1)
    print(f"{row['email']}  {message}")
```

Nothing in it is outside Python's standard library. **The names** are drawn from two short lists of
Brazilian first names and surnames, with accents, because a name field that has only ever seen
`Test User` has never been asked about `Débora` or `Gonçalves`. **The e-mail addresses** are
numbered, so no two collide, and they are all at `example.org`, a domain reserved for examples
that no customer can own an address at. **The passwords** are 8 to 16 characters from a set
that leaves out letters easily confused with digits, inside the 8 to 64 that R2 allows.

The line that makes it a test tool rather than a toy is `random.Random(1)`. A random generator
started from the same **seed** produces the same sequence every time, so this program invents the
same five accounts today, tomorrow and on Rui's machine. Section 05 of this lesson is about why
that matters.

## Running it

With boxoffice 1.1 running in one terminal, run the program in another, in the `boxoffice`
directory:

```
ana@laptop:~/boxoffice$ python3 make_accounts.py 5
test001@example.org  Account created. We sent a link to test001@example.org.
test002@example.org  Account created. We sent a link to test002@example.org.
test003@example.org  Account created. We sent a link to test003@example.org.
test004@example.org  Account created. We sent a link to test004@example.org.
test005@example.org  Account created. We sent a link to test005@example.org.
```

Each line is an address and the message boxoffice answered with, the same sentence the sign-up
page shows in a browser. The file it saved is the record of what was created:

```
ana@laptop:~/boxoffice$ cat accounts.csv
name,email,password
Caio Barbosa,test001@example.org,d2rngr6nv2yi
Débora Barbosa,test002@example.org,aat8ngpahqrhh
Débora Machado,test003@example.org,7p77dwzjz69s
Gustavo Duarte,test004@example.org,j9r8n5rznxm6
Fernanda Barbosa,test005@example.org,xdf4mzrj5vuwfha
```

Names repeat, three Barbosas among five people, because the program draws each name independently;
the addresses never do, because they are numbered. Both are decisions in the program, and both
are visible in this file before anybody has to discover them in boxoffice.

Every new account gets a confirmation e-mail, so the outbox now holds five of them. In the
browser, open `http://127.0.0.1:8000/outbox`; from the terminal, count them:

```
ana@laptop:~/boxoffice$ curl -s http://127.0.0.1:8000/outbox | grep -c '<h2>Confirm your account</h2>'
5
```

## What generated data is not

**It is not designed data.** The names here are all valid, between 1 and 40 characters, because the
program was written to sign people up. The values that find defects, a name of exactly 40
characters and one of 41, an address with no dot after the `@`, are chosen by the techniques of
lesson 4, and a random generator almost never lands on them by chance. A program can produce those
too, but only once a person has decided what they are.

**It is not realistic by default.** Real customers have names of one word and of six, addresses at
domains that look like typos, and a habit of pasting a space at the end of a field. A generator
produces exactly the variety it was written to produce. When realism matters, the next section's
source, a copy of production made safe, is the one that has it.
