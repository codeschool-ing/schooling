---
title: When the setup fails
version: 1
---

Setting up is where most people give up on a course like this, usually over one line of output
that looked like a catastrophe and was a small thing. These are the failures that come up while
following the last two sections, each with what it prints and what fixes it. Every one of them was
produced on purpose, on the machine the transcripts come from.

## `uv: command not found`

The terminal that ran `pipx ensurepath` was still open:

```
ana@laptop:~$ uv --version
bash: line 1: uv: command not found
```

`pipx ensurepath` wrote the new `PATH` into `~/.bashrc`, and a terminal reads that file once, when
it opens. **Open a new terminal**, or run `source ~/.bashrc` in this one. If a new terminal still
cannot find it, `ls ~/.local/bin` says whether `pipx install uv` finished at all.

## `No module named pytest`

A new terminal, the project's directory, and the suite:

```
ana@laptop:~/shipquote$ python -m pytest -q
/usr/bin/python: No module named pytest
```

The path at the start of the line gives it away: that is the system's Python, which has no pytest
and should not have one. On a stock Ubuntu 24.04 there is no plain `python` outside a virtual
environment at all, and the same mistake answers that `python` is not found. Either way, the
virtual environment is not active in this terminal. **Run
`source .venv/bin/activate` in `~/shipquote`**, once per terminal, and `python` means the
environment's own again. `which python` answers which one you have:
`/home/ana/shipquote/.venv/bin/python` is the right one.

## A file that lost its indentation

Here `shipquote/quote.py` has one line pasted with two spaces where there should be four, and the
suite does not even start:

```
ana@laptop:~/shipquote$ python -m pytest -q
ImportError while loading conftest '/home/ana/shipquote/tests/conftest.py'.
tests/conftest.py:9: in <module>
    from shipquote.app import Handler
shipquote/app.py:9: in <module>
    from . import money, quote
E     File "/home/ana/shipquote/shipquote/quote.py", line 25
E       zone = zone_of(cep)
E                          ^
E   IndentationError: unindent does not match any outer indentation level
```

Read it from the bottom. `IndentationError` is the cause, and the line above it names the file and
the line, `quote.py`, line 25. Everything above that is the chain of imports that reached the file:
`conftest.py` imports `app.py`, which imports `quote.py`, so **a mistake in one file stops every
test**, including the ones that never use it. Copy the file again with the button on its block.

## `Author identity unknown`

The first `git commit` on a machine where git was never told who you are:

```
ana@laptop:~/shipquote$ git commit -m "shipquote as the course begins"
Author identity unknown

*** Please tell me who you are.

Run

  git config --global user.email "you@example.com"
  git config --global user.name "Your Name"

to set your account's default identity.
Omit --global to set the identity only in this repository.

fatal: unable to auto-detect email address (got 'ana@laptop.(none)')
```

git refuses rather than guessing, and says exactly what to run. The two `git config --global`
lines of section 03 are the fix, once per machine. Run the commit again afterwards.

## `Address already in use`

Section 10 starts the server by hand on port 8080. Start it a second time while the first is still
running, in another terminal or in the background, and the second one stops at once:

```
ana@laptop:~/shipquote$ SHIPQUOTE_PORT=8080 python -m shipquote.app
Traceback (most recent call last):
  File "<frozen runpy>", line 203, in _run_module_as_main
  File "<frozen runpy>", line 88, in _run_code
  File "/home/ana/shipquote/shipquote/app.py", line 67, in <module>
    main()
    ~~~~^^
  File "/home/ana/shipquote/shipquote/app.py", line 61, in main
    server = ThreadingHTTPServer(("127.0.0.1", port), Handler)
  File "/usr/lib/python3.13/socketserver.py", line 457, in __init__
    self.server_bind()
    ~~~~~~~~~~~~~~~~^^
  File "/usr/lib/python3.13/http/server.py", line 140, in server_bind
    socketserver.TCPServer.server_bind(self)
    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~^^^^^^
  File "/usr/lib/python3.13/socketserver.py", line 478, in server_bind
    self.socket.bind(self.server_address)
    ~~~~~~~~~~~~~~~~^^^^^^^^^^^^^^^^^^^^^
OSError: [Errno 98] Address already in use
ana@laptop:~/shipquote$ ss -ltnp | grep 8080
LISTEN 0      5          127.0.0.1:8080       0.0.0.0:*    users:(("python",pid=6178,fd=3))        
```

Only one program can listen on a port. Find the first one with `ss -ltnp | grep 8080`, which names
the process, and stop it, or press Ctrl-C in the terminal where it runs.

## When uv cannot download a Python

`uv venv -p 3.13` on a machine with no Python 3.13 downloads one. On a network that refuses the
download, a school's or a company's, it stops with an error naming the address it could not reach.
**Every lesson works on any Python from 3.11 on**, so use the one Ubuntu ships instead:
`uv venv -p 3.12`. The first line of every pytest transcript then names 3.12 where the course
names 3.13, and nothing else changes until lesson 5, whose CI wants all three versions; that lesson
says what to do with fewer.

## The count is not 31

The suite ran and said something other than `31 passed`. A smaller number usually means a file is
missing, or was saved under another name: pytest only collects files whose names start with
`test_`. `python -m pytest --collect-only -q` lists every test it found, one per line, with its
file, and the one that is missing from the list is the file to look at.
