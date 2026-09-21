---
title: `python -m venv`, and the directory you never commit
version: 1
---

```sh
python3 -m venv .venv
```

```text
.venv/
  bin/          activate  python  python3  pip  pip3
  lib/python3.11/site-packages/
  pyvenv.cfg
```

Three seconds, no network, no configuration. `.venv` is the conventional name — a dot so it is
hidden, and the same in every project so that tooling finds it.

## `pyvenv.cfg`

```ini
home = /usr/local/bin
include-system-site-packages = false
version = 3.11.15
executable = /usr/bin/python3.11
```

The whole of what an environment *is*. `home` and `executable` say which interpreter it borrows —
**an environment contains no Python of its own**, only a link to one — and
`include-system-site-packages = false` is the line that makes the isolation.

That last one explains a common surprise: an environment created with `--system-site-packages`
can see the machine's libraries as well, which is occasionally what you want and never the
default.

## Activating

```sh
. .venv/bin/activate        # bash, zsh
.venv\Scripts\activate      # Windows
deactivate
```

```text
$ which python
/tmp/project/.venv/bin/python
$ python -c "import sys; print(sys.prefix)"
/tmp/project/.venv
```

`activate` is a shell script that edits `PATH` and sets `VIRTUAL_ENV`. It is not magic and it is
not required: `.venv/bin/python script.py` works with nothing activated, and that is what a cron
job or a systemd unit should use, because neither of those has a shell that ran your `activate`.

## The directory is never committed

```text
# .gitignore
.venv/
```

It holds compiled extensions built for one operating system and one processor, absolute paths in
its scripts, and a copy of every library. It is a **build artefact**, reproduced in seconds from
a text file, and committing it puts hundreds of megabytes into a history that can never lose
them.

## Deleting and rebuilding

```sh
rm -rf .venv && python3 -m venv .venv && python -m pip install -r requirements.txt
```

The answer to almost every "it works on my machine" about dependencies. An environment is
disposable on purpose; treating it as precious is how it accumulates the thing that makes it
different from everybody else's.
