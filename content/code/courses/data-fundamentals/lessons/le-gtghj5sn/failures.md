---
title: Three failures that look the same
version: 1
---

**From the machine that asked, a crashed machine, a cut network and a machine that is only slow all
look like one thing: no reply yet.** The tool for deciding that a reply is not coming is a timeout,
and a timeout tells you how long you waited. It does not tell you what happened.

The three, as they happen on the other side:

- a crash: the process or the whole machine has stopped;
- a network partition: both machines are fine and the link between them is cut, so neither can
  reach the other;
- a slow node: the machine is alive and working, and it is overloaded, or paused, or waiting on
  a disk that is failing.

## Three pretend nodes

The program below plays two nodes on your own machine. On port 8001 a node that answers, three
seconds late. On port 8002 a node that accepts the connection and then never says anything, which
is what a process that has hung looks like. Port 8003 has nothing listening on it at all. Save it as
`nodes.py`:

```python
# spread/nodes.py
import socket
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer


class Slow(BaseHTTPRequestHandler):
    def do_GET(self):
        time.sleep(3)                       # alive, and three seconds late
        self.send_response(200)
        self.end_headers()
        self.wfile.write(b"ST06 has 4 bicycles\n")

    def log_message(self, *args):
        pass


stuck = socket.socket()                     # accepts a connection, never answers
stuck.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
stuck.bind(("127.0.0.1", 8002))
stuck.listen()
ThreadingHTTPServer(("127.0.0.1", 8001), Slow).serve_forever()
```

And a client that asks each of the three, giving up after the number of seconds it is told. Save it
as `probe.py`:

```python
# spread/probe.py
import sys
import urllib.request

timeout = float(sys.argv[1])
for name, port in (("slow", 8001), ("stuck", 8002), ("stopped", 8003)):
    try:
        url = f"http://127.0.0.1:{port}/"
        with urllib.request.urlopen(url, timeout=timeout) as reply:
            print(f"{name:8} answered: {reply.read().decode().strip()}")
    except Exception as error:
        print(f"{name:8} {type(error).__name__}: {error}")
```

Start `python nodes.py` in a second terminal, in `~/roda/spread`. It prints nothing and keeps
running until you press Ctrl+C. Then, in the first terminal, probe with a one-second timeout and
with a five-second one:

```
ana@lab:~/roda/spread$ python probe.py 1
slow     TimeoutError: timed out
stuck    TimeoutError: timed out
stopped  URLError: <urlopen error [Errno 111] Connection refused>
ana@lab:~/roda/spread$ python probe.py 5
slow     answered: ST06 has 4 bicycles
stuck    TimeoutError: timed out
stopped  URLError: <urlopen error [Errno 111] Connection refused>
```

With one second, the slow node and the hung one print the same line, `TimeoutError: timed out`. One
of them would have answered in two more seconds and the other never will, and the client cannot
tell which is which. With five seconds the slow node answers, and the hung one still times out, and
nothing in that line says whether it would answer at ten seconds or at all.

The third line is different, and the difference sharpens the point. A machine that is running, with
nothing on that port, answers at once: `Connection refused` is a reply. A machine that is switched off, or on the far side
of a cut link, sends nothing back, and the client is left with a timeout again.

## Choosing a timeout

There is no right value, only two ways to be wrong. Too short, and a node that was only slow is
declared dead: its work is handed to others, which are now busier, and if it was a leader, a
follower is promoted while the old leader is still working. Too long, and every real failure keeps
somebody waiting for the full time before anything is done about it. The usual practice is to watch
how long replies take when everything is healthy and set the timeout comfortably above the slowest
of them, then let a person decide what "comfortably" means for that system.

## Heartbeats

Waiting for a request to fail is a slow way to find a dead machine, so most systems also send
**heartbeats**: every node sends a small "still here" message to the others, or to a coordinator,
every second or so. A node that misses several in a row is **presumed** dead, and its work is
given to the others.

Presumed is the honest word. The node may be alive on the other side of a partition, still serving
the clients that can reach it, still believing it is the leader. That is the split brain of section
06, and deciding what a system should do about it is where lesson 10 starts.

When you are done, press Ctrl+C in the second terminal to stop `nodes.py`.
