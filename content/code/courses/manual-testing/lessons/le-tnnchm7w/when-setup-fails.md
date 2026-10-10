---
title: When the setup fails
version: 1
---

Setting up is where most people give up on a course like this, usually over one line of output
that looked like a catastrophe and was a small thing. These are the failures that come up while
following the last two sections, each with what it prints and what fixes it. The Linux ones were
produced on purpose on the machine the transcripts come from; the Windows one was not run, and
says so.

## `can't open file`

The terminal is not in the directory where `boxoffice.py` was saved:

```
ana@laptop:~$ python3 boxoffice.py
python3: can't open file '/home/ana/boxoffice.py': [Errno 2] No such file or directory
```

The path in the message is where Python looked, and the prompt says the same thing: `~`, the home
directory, and not `~/boxoffice`. **Run `cd ~/boxoffice` first.** If the error persists in the
right directory, the file was saved under another name; on Windows, Notepad likes to save it as
`boxoffice.py.txt`, which File Explorer hides unless you turn on file name extensions.

## `python3` opens a shop, or is not found, on Windows

On Windows, typing `python3` when Python was installed from python.org can open the Microsoft
Store instead of running anything, because Windows ships a shortcut by that name. Type `python
boxoffice.py` or `py boxoffice.py`. If neither is found, the installer ran without **Add python.exe
to PATH**; run it again, choose Modify, and tick it. This was not run for this course.

## `IndentationError`

One line of the program lost its indentation on the way into the editor:

```
ana@laptop:~/boxoffice$ python3 boxoffice.py
  File "/home/ana/boxoffice/boxoffice.py", line 57
    return f"R$ {reais},{cents % 100:02d}"
IndentationError: unexpected indent
```

Python reads indentation as structure, so a line indented by two spaces next to one indented by
four is a different program, or no program at all. The message names the file and the line, but
the line it names is often the one *after* the damage, here line 57, below the line that lost two
spaces. **Copy the whole file again with the button on its block** rather than repairing it by
eye.

## `Address already in use`

The application is already running, in another terminal or one you forgot behind a window, and a
second copy cannot take the same port:

```
ana@laptop:~/boxoffice$ python3 boxoffice.py
boxoffice 1.0 on http://127.0.0.1:8000  (Ctrl-C stops it)
Traceback (most recent call last):
  File "/home/ana/boxoffice/boxoffice.py", line 260, in <module>
    ThreadingHTTPServer(("127.0.0.1", PORT), Handler).serve_forever()
    ~~~~~~~~~~~~~~~~~~~^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
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
```

Read a traceback from the bottom: the last line is the cause, and everything above it is the path
that led there. **Find the other copy and stop it with Ctrl-C.** If you cannot find it, start this
one on another port, `BOXOFFICE_PORT=8001 python3 boxoffice.py`, and use `8001` wherever the course
writes `8000`. Something that is not boxoffice may hold the port too; the same variable is the
way round it.

## `Couldn't connect to server`

Nothing is listening at the address curl or the browser asked:

```
ana@laptop:~/boxoffice$ curl http://127.0.0.1:8000/health
curl: (7) Failed to connect to 127.0.0.1 port 8000 after 0 ms: Couldn't connect to server
```

The server is not running. Either it was never started, or its terminal was closed, which stops
it, or it stopped with an error you have not read yet. **Look at the terminal where you started
it.** A browser says the same thing in its own words, *unable to connect* or *this site can't be
reached*. And check the address: `https` instead of `http` fails too, because boxoffice does not
speak it.

## The page shows something other than this course

Three shows, the seats full, Bia Souza's account and no orders: that is the application just after
it starts. A lesson whose transcript shows order 1001 when yours shows 1004 is a lesson you started
after booking something else. **Stop the application and start it again** before each lesson that
books, and the numbers line up.
