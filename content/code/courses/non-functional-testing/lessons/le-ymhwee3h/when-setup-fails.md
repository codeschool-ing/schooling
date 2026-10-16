---
title: When the setup fails
version: 1
---

Most people who give up on a course like this one give up here, on an error message about a
machine they have not finished building. These are the failures that actually happen, in the
order you would meet them, with what each one means.

**The virtual machine will not start, and the message mentions virtualisation, VT-x, AMD-V or
SVM.** The processor's virtualisation support is switched off in the computer's firmware. It is a
setting in the BIOS or UEFI menu, usually under *Advanced* or *CPU configuration*, and many laptops
ship with it off. No program can turn it on for you. On Windows, Hyper-V and WSL can also hold it,
and then VirtualBox runs slowly or not at all; Multipass on Windows uses Hyper-V itself and avoids
the fight.

**`multipass launch` says there is not enough memory, or the computer crawls once it starts.**
Four gigabytes for the VM is on top of what your own system uses. On a computer with 8 GB in
total, close the browser tabs you do not need, or launch with `--memory 3G --cpus 2`: every lesson
still works, more slowly.

**`multipass launch` times out.** The first launch downloads an Ubuntu image of several hundred
megabytes, and a slow connection takes longer than the default wait. `multipass launch` accepts
`--timeout 1800`; give it that and let it finish.

**`apt-get` says it could not get a lock.** Ubuntu runs its own updates for the first minutes
after a machine boots, and only one program may install packages at a time. Wait until
`pgrep -c apt` prints `0` and run the command again. Deleting the lock file is the advice you will
find online, and it is how a package database gets corrupted.

**`apt-get` says `Unable to locate package`.** Either `sudo apt-get update` was skipped, or the
machine is not Ubuntu 24.04. `grep PRETTY /etc/os-release` settles which; the package names in this
course are the ones 24.04 uses.

**The server says `Address already in use`.** Another program already listens on port 8000, and
almost always it is an earlier `app.py` you forgot in another terminal:

```
ana@nft:~/boxoffice$ python3 app.py
Traceback (most recent call last):
  File "/home/ana/boxoffice/app.py", line 106, in <module>
    server = ThreadingHTTPServer((host, 8000), Box)
             ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/usr/lib/python3.12/socketserver.py", line 457, in __init__
    self.server_bind()
  File "/usr/lib/python3.12/http/server.py", line 136, in server_bind
    socketserver.TCPServer.server_bind(self)
  File "/usr/lib/python3.12/socketserver.py", line 473, in server_bind
    self.socket.bind(self.server_address)
OSError: [Errno 98] Address already in use
```

Find it with `ss -ltnp 'sport = :8000'`, which names the process, and stop it with `Ctrl+C` in its
own terminal, or `kill` and the process id `ss` printed.

**`curl` prints nothing at all.** The `-s` flag that keeps progress bars out of the transcripts
also hides curl's own errors, so a server that is not running looks like a server that answered
with nothing. `echo $?` after it prints curl's exit code, and `-sS` keeps the silence but shows the
error:

```
ana@nft:~/boxoffice$ curl -s localhost:8000/health; echo "exit $?"
exit 7
ana@nft:~/boxoffice$ curl -sS localhost:8000/health
curl: (7) Failed to connect to localhost port 8000 after 0 ms: Couldn't connect to server
```

Exit code 7 means nothing was listening: the server is stopped, or it is running on a different
machine, which happens when the second terminal was opened on your own computer rather than with
`multipass shell nft`.

**Python reports an `IndentationError` or a `SyntaxError` in a file you pasted.** Some terminals
add spaces or drop a line when a long paste arrives through them. Open the file with `nano`, go to
the line number in the message with `Ctrl+_`, and compare it with the lesson. Copying with the
button in the block's corner, rather than selecting with the mouse, avoids most of it.

**`sqlite3.OperationalError: unable to open database file`.** The server was started from a
directory other than `~/boxoffice`, so `data/boxoffice.db` is not where it looks. `cd ~/boxoffice`
first; every command in the performance lessons assumes it.

**And when nothing else works**, delete the machine and build it again: `multipass delete --purge
nft` in your computer's terminal, then the commands of this lesson again. It feels like giving up,
and it is what professionals do with a machine whose state nobody can explain any more. Your
`~/boxoffice` goes with it, which is why every file you need is printed in a lesson.
