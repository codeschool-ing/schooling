---
title: When the lab does not work
version: 1
---

A lab that fails on the first evening is where a course gets abandoned, so the four failures below
were reproduced on purpose on the recording machine. Each one has a message that says what is
wrong, if you know how to read it.

### The environment is not active

A new terminal starts without the virtual environment. Python is there, Flask is not, because
Flask was installed into `~/sc/.venv` and nowhere else:

```
(.venv) ana@vm:~/sc$ deactivate
ana@vm:~/sc$ python3 -c 'import flask'
Traceback (most recent call last):
  File "<string>", line 1, in <module>
    import flask
ModuleNotFoundError: No module named 'flask'
```

**The prompt is the tell**: no `(.venv)` at its start. `cd ~/sc` and `. .venv/bin/activate`, and
the same command works. Two more failures belong to Debian and Ubuntu and were not reproduced here.
If `python3 -m venv` complains about `ensurepip`, the `python3-venv` package is missing: install it,
delete `.venv` and create it again. If pip refuses with a message about an **externally managed
environment**, it ran outside the virtual environment, against the system's own Python. Activate
`.venv` and try again, and never reach for `sudo pip`.

### Flask cannot find the application

`flask --app app` means *import the module `app`*, from the folder you are in. Run from the wrong
folder, there is no `app.py` to import:

```
(.venv) ana@vm:~/sc$ flask --app app run
Usage: flask run [OPTIONS]
Try 'flask run --help' for help.

Error: Could not import 'app'.
```

The fix is `cd ~/sc/cancel`. Every lesson's folder holds its own `app.py`, so the folder you are in
decides which application starts.

### Port 5000 is taken

Only one program at a time can listen on a port. The usual cause is an application from earlier
still running in another terminal; with one already started, a second one says so:

```
(.venv) ana@vm:~/sc/cancel$ flask --app app run
 * Serving Flask app 'app'
 * Debug mode: off
Address already in use
Port 5000 is in use by another program. Either identify and stop that program, or start the server with a different port.
```

On macOS the same message goes on to name a cause that surprises people: since macOS 12 the
**AirPlay Receiver** listens on port 5000, so the port is taken before you start anything. That
line was not recorded here, because the recording machine runs Linux. Either switch the receiver
off in the system settings, or give Flask another port with `--port 5001` and use that number
wherever a lesson writes 5000.

### The tests find nothing, or the wrong thing

pytest collects files named `test_*.py` or `*_test.py` and, inside them, functions whose names
start with `test`. A file saved as `tests_app.py` is never opened, and a function called
`check_cancel` is never run. If `pytest` reports fewer tests than the lesson shows, compare the
names before anything else.

### And if it is still broken

Delete the lesson's folder and build it again from the listings: they are short, and every file
the lessons use is printed whole. For the environment itself, `rm -rf ~/sc/.venv` and repeat the
`python3 -m venv` and `pip install` steps; your lesson folders are untouched by that.
