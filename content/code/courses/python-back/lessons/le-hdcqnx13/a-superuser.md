---
title: A superuser, and reading the admin
version: 1
---

Django's admin is a complete back office generated from your models: lists, search, filters, forms
to add and change rows, a history of who changed what. It has been at `/admin/` since lesson 2,
because `startproject` put it in `config/urls.py`. What it needs first is somebody allowed in.

## The first account

A **superuser** is an account with every permission. `createsuperuser` asks for a name, an address
and a password, twice, when you run it at a terminal. The same command takes them all at once,
which is how it ran here, so the transcript could be reproduced:

```
ana@vm:~/agenda$ DJANGO_SUPERUSER_PASSWORD='x9-river-lantern-42' uv run python manage.py createsuperuser --noinput --username ana --email ana@example.org
Superuser created successfully.
```

Type it interactively on your own machine, `uv run python manage.py createsuperuser`, and the
password never appears on screen or in your shell's history. **Lesson 11 is about where the
password went**: not into the database as you typed it.

## Opening it in a browser

The admin is a site for a browser, and your virtual machine has none. Two ways to reach it from the
computer around it, neither run for this course:

- **An SSH tunnel**, if you can already `ssh` into the virtual machine: on your own computer,
  `ssh -L 8000:127.0.0.1:8000 ana@<the machine's address>` keeps a connection open that carries
  your computer's port 8000 to the machine's. Then open `http://127.0.0.1:8000/admin/` in your
  browser, with `runserver` running in the machine as usual.
- **A port-forwarding rule** in VirtualBox's network settings, from your computer's port 8000 to the
  guest's, with `runserver 0.0.0.0:8000` so Django listens beyond the machine itself. Browsing to
  the machine's own address instead, on a bridged network, works too once `ALLOWED_HOSTS` names that
  address, which lesson 15 does properly.

## Reading it in the terminal

So that every screen here is a capture, this lesson reads the admin's pages as text, with **w3m**,
a web browser that runs in a terminal:

```sh
sudo apt install -y w3m
```

A small script fetches a page with curl, keeping the login cookies in a file, and hands the HTML to
w3m to lay out. Save it as `~/.local/bin/page` and make it executable with
`chmod +x ~/.local/bin/page`:

```sh
#!/bin/sh
# ~/.local/bin/page
# Print one of agenda's pages as text, keeping the admin's login cookies.
curl -s -b "$HOME/admin-cookies.txt" -c "$HOME/admin-cookies.txt" \
  "http://127.0.0.1:8000$1" | w3m -dump -T text/html -cols 100
```

`~/.local/bin` is on your `PATH` since lesson 1's `pipx ensurepath`, so `page /admin/` works from
any directory. Asking for the admin without logging in gets a redirect to the login form:

```
ana@vm:~/agenda$ curl -si http://127.0.0.1:8000/admin/ | grep -E "^(HTTP|Location)"
HTTP/1.1 302 Found
Location: /admin/login/?next=/admin/
```

Logging in is lesson 3's CSRF dance: fetch the form to get the cookie, then post the token, the
name and the password with it.

```
ana@vm:~/agenda$ curl -s -c ~/admin-cookies.txt -o /dev/null http://127.0.0.1:8000/admin/login/
ana@vm:~/agenda$ TOKEN=$(grep csrftoken ~/admin-cookies.txt | cut -f7); curl -si -b ~/admin-cookies.txt -c ~/admin-cookies.txt -d "csrfmiddlewaretoken=$TOKEN&username=ana&password=x9-river-lantern-42&next=/admin/" http://127.0.0.1:8000/admin/login/ | grep -E "^(HTTP|Location)"
HTTP/1.1 302 Found
Location: /admin/
```

A **302 to `/admin/`** means the password was accepted and the cookie file now holds a session.
The front page, as w3m lays it out:

```
ana@vm:~/agenda$ page /admin/ | sed -n "/^Site administration/,/^Recent actions/p"
Site administration

      Authentication and Authorization
Model name Add link Change or view list link
  Groups   Add      Change
  Users    Add      Change

Recent actions
```

**Only Django's own app is there**: groups and users. The events app has models and no admin
configuration yet, and the admin shows nothing it was not told about.
