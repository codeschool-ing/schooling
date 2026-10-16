---
title: When the setup fails
version: 1
---

Setting up is where most people give up on a course like this, usually over a single line of output
that looked like a catastrophe and was a small thing. These are the failures you are most likely to
meet in this lesson, each with what it prints and what fixes it. Every one was produced on purpose,
on the machine the transcripts come from.

## `uv: command not found`

The terminal that ran `pipx ensurepath` was still open:

```
ana@vm:~$ uv --version
bash: line 1: uv: command not found
```

`pipx ensurepath` wrote the new `PATH` into your shell's start-up files, and a terminal reads those
once, when it opens. **Open a new terminal**, or run `source ~/.bashrc` in this one. If a new
terminal still cannot find it, `ls ~/.local/bin` says whether `pipx install uv` finished at all.

## `Couldn't import Django`

A project directory, and Django's own management script run with the system's Python:

```
ana@vm:~/hello-django$ python3 manage.py check
Traceback (most recent call last):
  File "/home/ana/hello-django/manage.py", line 11, in main
    from django.core.management import execute_from_command_line
ModuleNotFoundError: No module named 'django'

The above exception was the direct cause of the following exception:

Traceback (most recent call last):
  File "/home/ana/hello-django/manage.py", line 22, in <module>
    main()
  File "/home/ana/hello-django/manage.py", line 13, in main
    raise ImportError(
ImportError: Couldn't import Django. Are you sure it's installed and available on your PYTHONPATH environment variable? Did you forget to activate a virtual environment?
ana@vm:~/hello-django$ uv run python manage.py check
System check identified no issues (0 silenced).
```

**Django is installed in the project's `.venv`, not in the system's Python**, and `python3` on its
own is the system's. Django's message guesses right: no virtual environment was active. The fix is
the second command. `uv run` runs a command inside the project's environment, checking it against
the lock file first, so nothing needs activating; every command in this course that runs Python
inside a project starts with it. Activating the environment with `source .venv/bin/activate`, as
`python` lesson 18 does, also works, once per terminal.

## `That port is already in use`

A server started a second time while the first one was still running:

```
ana@vm:~/hello-django$ uv run python manage.py runserver 8000
Watching for file changes with StatReloader
Performing system checks...

System check identified no issues (0 silenced).

You have 18 unapplied migration(s). Your project may not work properly until you apply the migrations for app(s): admin, auth, contenttypes, sessions.
Run 'python manage.py migrate' to apply them.
Error: That port is already in use.
```

Only one program can listen on a port. The first server is still running somewhere, often in
another terminal you forgot about. Go to it and press **Ctrl-C**, or find it with
`ss -ltnp | grep 8000`, which names the process holding the port. The other choice is a different
port, `runserver 8010`, which works and leaves the forgotten server running. The warning about
migrations is real and harmless here: the next section explains it.

## Anything else

**Read what it printed before you search for it.** The last line of a traceback is the cause; the
lines above are how the program got there. A message that names a command to run, like the first
two above, means exactly that. And if a lesson's output differs from yours only in a time, a
process number or a date, nothing is wrong: those change on every run.
