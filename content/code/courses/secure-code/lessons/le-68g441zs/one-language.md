---
title: One language, named on the first page
version: 1
---

Secure coding is about **the exact call**. "Use a parameterised query" is advice; the difference
between `cursor.execute(sql % name)` and `cursor.execute(sql, (name,))` is the lesson, and it is
one comma and a pair of brackets. Pseudocode cannot show that difference, so this course picks one
language and says so here: **Python 3, with the Flask web framework, SQLite as the database and
pytest for the tests.**

Python because it reads closest to pseudocode for somebody who writes another language, and because
the libraries this course needs come with it or are one `pip install` away. Flask because it is
small enough that every line of an application fits on the page, and nothing happens that you did
not write. SQLite because it is part of Python's standard library, so there is no database server
to install.

::: track security
In your track the `python` course comes later than this one. You do not need it first: every
program here is short, shown whole and explained line by line, and reading it is enough to follow
the argument. Typing it out and running it is what makes the argument stick.
:::

::: track devsecops
Your track asked you to choose an automation language before this course. If you chose Python,
this is your language. If you chose Go or JavaScript, read the programs here as a second language
you understand but do not write every day; the table below says what each safe call is called in
yours.
:::

::: track *
If Python is not your language, you can still follow every lesson: each program is short, shown
whole and explained line by line. The table below says what the safe calls are called elsewhere.
:::

### What carries across

**The flaws are the same in every language, and so are the defences.** Only the spelling changes.
The table maps the calls this course uses to their equivalents in Go and in JavaScript on Node.js.
It is a vocabulary to look things up in, not a set of recordings: none of the Go or JavaScript was
run for this course.

| what you need | Python (this course) | Go | JavaScript (Node.js) |
|---|---|---|---|
| a query with parameters | `cur.execute("… WHERE id = ?", (pid,))` | `db.Query("… WHERE id = $1", pid)` | `db.query("… WHERE id = $1", [pid])` (pg) |
| HTML escaped by default | Jinja2 templates in Flask | `html/template` | the framework's templates (React escapes text) |
| run a program without a shell | `subprocess.run([prog, arg])` | `exec.Command(prog, arg)` | `child_process.execFile(prog, [arg])` |
| a random token | `secrets.token_urlsafe(32)` | `crypto/rand` | `crypto.randomBytes(32)` |
| a password hash | `argon2-cffi`, `bcrypt` | `golang.org/x/crypto/argon2` | `argon2`, `bcrypt` packages |
| compare secrets in constant time | `hmac.compare_digest` | `subtle.ConstantTimeCompare` | `crypto.timingSafeEqual` |

### What does not carry across

Frameworks differ in **what they do for you without being asked**, and that half does not
translate. Flask escapes HTML in its templates and does not protect forms against cross-site
request forgery; Django does both; Express does neither. Each lesson says which half of a defence
Flask gives you and which half you write, so that in another framework you know what question to
ask of its documentation.
