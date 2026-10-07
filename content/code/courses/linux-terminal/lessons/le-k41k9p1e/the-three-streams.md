---
title: Three streams, and why two of them look the same
version: 2
---

## First, the files this lesson reads

Every command in this lesson reads lesson 3's `~/work`, and two files in it are new: a day of a web
server's log, `logs/access.log`, twelve hundred lines of it, and a year of sales, `data/sales.csv`.
A real log carries real people's addresses, so these are made by a short program instead. Copy the
whole block into the terminal; it writes the program to `make-data.py` and runs it:

```sh
cd ~/work
cat > make-data.py <<'END'
#!/usr/bin/env python3
"""Write the two files lesson 8 reads: a day of a web server's log, and a year of sales.

The same seed gives the same files on every machine, so your numbers match the page's."""
import random

r = random.Random(8)

# (method, path, how often), and who asks for it
pages = [("GET", "/health", 24), ("GET", "/", 22), ("POST", "/api/orders", 12),
         ("GET", "/static/app.js", 9), ("GET", "/static/app.css", 9), ("GET", "/index.html", 6),
         ("GET", "/favicon.ico", 4), ("GET", "/api/users", 4), ("PUT", "/api/users", 3),
         ("DELETE", "/api/orders", 2), ("POST", "/api/orders/new", 2), ("GET", "/admin", 1),
         ("POST", "/api/reports", 2)]
agents = ["Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 Chrome/131.0 Safari/537.36",
          "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 Safari/18.1",
          "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)",
          "curl/8.5.0", "python-requests/2.32.3"]
codes = [200] * 86 + [201] * 5 + [404] * 3 + [302] * 2 + [304] * 2 + [500] * 2

t = 6 * 3600 + 60  # 06:01:00
with open("logs/access.log", "w") as log:
    for _ in range(1200):
        t += r.randint(1, 59)
        when = f"14/Sep/2026:{t // 3600:02}:{t // 60 % 60:02}:{t % 60:02} +0000"
        method, path, _ = r.choices(pages, weights=[p[2] for p in pages])[0]
        ip = r.choice(["10.0.1."] * 6 + ["198.51.100."] * 3 + ["203.0.113."]) + str(r.randint(2, 40))
        code = r.choice([401, 403]) if path == "/admin" else r.choice(codes)
        size = r.randint(300, 999) if path.startswith("/static") else r.randint(200, 24000)
        ms = r.randint(3001, 6000) if path == "/api/reports" else r.randint(5, 300)
        agent = "kube-probe/1.29" if path == "/health" else r.choice(agents)
        log.write(f'{ip} - - [{when}] "{method} {path} HTTP/1.1" {code} {size} "{agent}" {ms}\n')

with open("data/sales.csv", "w") as sales:
    sales.write("region,rep,quarter,units,revenue\n")
    for quarter in ["Q1", "Q2", "Q3", "Q4"]:
        for region, reps in [("north", "ana bruno"), ("south", "carla diego"),
                             ("east", "elena felipe"), ("west", "gabriel helena")]:
            for rep in reps.split():
                units = r.randint(20, 400)
                sales.write(f"{region},{rep},{quarter},{units},{units * r.randint(40, 130)}\n")
END
python3 make-data.py
```

**You do not need to read the program yet**; by the end of lesson 9 you could write one like it.
What matters now is that it starts from a fixed seed, so it writes the same bytes on every machine
and every number on these pages is the number yours will print. `sha256sum` proves it, one
fingerprint per file, and yours should match these to the last character:

```
ana@vm:~/work$ sha256sum logs/access.log data/sales.csv
4f78595dfc41e21c0a33fb42785b91ed9cf724952850093324658fbb2daaeb91  logs/access.log
79775975672c3b0589a68e166bf50bd008a23d6579c4152e119018870a755759  data/sales.csv
```

## The three streams

Lesson 6 section 13 gave you the numbers. This is what they are for.

Every program starts with three connections already open, and it does not have to ask for any of
them:

| | | |
|---|---|---|
| `0` | **stdin** | where input comes from. Your keyboard, a file, another program |
| `1` | **stdout** | where its **results** go |
| `2` | **stderr** | where its **complaints** go |

**Both `1` and `2` land on your screen by default**, which is why they look like one thing. They are
not, and the whole of the next section depends on knowing it.

Here is the difference, visible:

```
ana@vm:~/work$ ls logs nosuchdir
ls: cannot access 'nosuchdir': No such file or directory
logs:
access.log
app.log
app.log.1
empty.log
error.log
today.log
ana@vm:~/work$ ls logs nosuchdir > out.txt
ls: cannot access 'nosuchdir': No such file or directory
ana@vm:~/work$ cat out.txt
logs:
access.log
app.log
app.log.1
empty.log
error.log
today.log
```

One command, two destinations. `> out.txt` captured the listing and **the error stayed on the
screen**, because `>` redirects stdout and nothing else.

That is not a quirk; it is the design. The results go somewhere a program can read them; the
complaints go where a person can see them. A pipeline that swallowed its own error messages would
be much harder to debug than one that does not.

## And notice what changed shape

Look at those two outputs again. On the screen, `ls` printed the five names **across the line, in
columns**. In the file, it printed them **one per line**.

**`ls` asks whether its output is a terminal, and formats accordingly** — the `isatty()` question
from lesson 6. Columns are for people; one per line is for programs.

This matters more than it looks. It means:

- `ls | wc -l` counts files correctly, because `ls` switched to one per line for the pipe;
- and it means the thing you saw on screen is not always the thing the next command received.

Most tools do not do this. `ls`, `grep` (colour), and `ps` (width) are the three you will meet that
do. **When a pipeline behaves differently from what you saw, this is the first thing to suspect.**

## Where the streams actually go

`$FDPID` is the `tail` from lesson 6 section 13, started with
`tail -f logs/app.log > /tmp/out.txt 2>/tmp/err.txt & FDPID=$!`; start it again to look for
yourself:

```
ana@vm:~/work$ ls -l /proc/$FDPID/fd
total 0
lr-x------ 1 ana ana 64 Sep 15 07:23 0 -> /dev/null
l-wx------ 1 ana ana 64 Sep 15 07:23 1 -> /tmp/out.txt
l-wx------ 1 ana ana 64 Sep 15 07:23 2 -> /tmp/err.txt
```

That is lesson 6's transcript, and it is worth a second look now that the numbers mean something.
**Redirection is not a feature of the program.** The program writes to descriptor 1; the shell
decided what descriptor 1 was, before the program started, in lesson 6 section 03's gap between
`fork` and `exec`.

Which is why `>` works on every command ever written, including ones whose authors never thought
about files.

## Reading from stdin

Most of the tools in this lesson take a filename **or** read stdin if you do not give them one:

```
wc -l logs/app.log        # from a file
wc -l < logs/app.log      # from stdin, redirected by the shell
cat logs/app.log | wc -l  # from stdin, through a pipe
```

All three count the same thing. The difference is only who opens the file:

```
ana@vm:~/work$ wc -l logs/app.log
30 logs/app.log
ana@vm:~/work$ wc -l < logs/app.log
30
```

**`wc` printed the filename in the first and not in the second**, because in the second it never
knew one. That is a small thing that catches people out in scripts: the output format changed
because of how the input arrived.

**A `-` as a filename means stdin** in many tools, which is how you mix the two:

```
ana@vm:~/work$ printf "header\n" > /tmp/h.txt; printf "body\n" | cat /tmp/h.txt -
header
body
```

A file, then whatever was piped in, in that order — because that is the order the arguments are
in.
