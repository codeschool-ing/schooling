#!/usr/bin/env python3
"""Type lines at an interactive client through a pipe, and print the session.

  session.py COMMAND...   < lines

COMMAND is the client as the lesson shows it, with `docker exec -it`; it is run
with `-i` alone, because a capture has no terminal. Each line of stdin is sent
on its own, and the next is not sent until the client has answered: for mongosh
and cqlsh that is the next prompt they print, followed by half a second of
quiet (an error reaches the pipe after the prompt that follows it, and belongs
to the line before); redis-cli prints no prompt through a pipe, so each line is
followed by an ECHO of a marker the transcript leaves out, and the prompt shown
is the host:port the client was connected to, as redis-cli draws it.

The transcript is what a terminal would hold, without colours: prompt, line,
answer. A line `#sleep N` waits N seconds and is not shown.
"""
import os, re, select, subprocess, sys, time

argv = sys.argv[1:]
shown = " ".join(argv)
cmd = [a for a in argv if a != "-it"]
if "-it" in argv:
    cmd.insert(cmd.index("exec") + 1, "-i")
tool = next((t for t in ("mongosh", "redis-cli", "cqlsh") if t in cmd), None)
if tool is None:
    sys.exit("session.py: no mongosh, redis-cli or cqlsh in " + shown)

lines = sys.stdin.read().split("\n")
if lines and lines[-1] == "":
    lines.pop()

if tool == "cqlsh":
    cmd += ["--tty", "--no-color"]
if tool == "redis-cli":
    cmd += ["--no-raw"]

proc = subprocess.Popen(cmd, stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                        stderr=subprocess.STDOUT, bufsize=0)
fd = proc.stdout.fileno()
out = sys.stdout

def read_for(seconds):
    """Everything the client writes until it has been quiet for `seconds`."""
    buf = b""
    while True:
        r, _, _ = select.select([fd], [], [], seconds)
        if not r:
            return buf
        chunk = os.read(fd, 65536)
        if not chunk:
            return buf
        buf += chunk

if tool in ("mongosh", "cqlsh"):
    PROMPT = re.compile(r"(?:^|(?<=\n)|(?<=> ))((?:[\w-]+ )?(?:\[[^\]\n]+\] )?[\w-]+> |cqlsh(?::[\w]+)?> |   \.\.\. )")

    def until_prompt(timeout=600):
        buf = b""
        start = time.time()
        while time.time() - start < timeout:
            buf += read_for(0.5)
            text = buf.decode("utf-8", "replace")
            if PROMPT.search(text) and text.endswith(("> ", "... ")):
                buf += read_for(0.5)
                return buf.decode("utf-8", "replace")
            if proc.poll() is not None:
                buf += read_for(0.2)
                return buf.decode("utf-8", "replace")
        sys.exit("session.py: no prompt from %s in %ds" % (tool, timeout))

    def split(text):
        """(output, prompt): the last prompt in text, and everything else."""
        ms = list(PROMPT.finditer(text))
        if not ms:
            return text, ""
        m = ms[-1]
        return text[:m.start(1)] + text[m.end(1):], m.group(1)

    first = until_prompt()
    banner, prompt = split(first)
    out.write(banner)
    for line in lines:
        if line.startswith("#sleep "):
            time.sleep(float(line.split()[1]))
            continue
        out.write(prompt + line + "\n")
        out.flush()
        proc.stdin.write((line + "\n").encode())
        proc.stdin.flush()
        if line.strip() in ("exit", "quit", "exit;", "quit;"):
            break
        text = until_prompt()
        answer, prompt = split(text)
        out.write(answer)
    proc.stdin.close()
    proc.wait()
else:
    host, port = "127.0.0.1", "6379"
    for i, a in enumerate(cmd):
        if a == "-h": host = cmd[i + 1]
        if a == "-p": port = cmd[i + 1]
    db = ""
    def prompt_now():
        return "%s:%s%s%s> " % (host, port, db, "(TX)" if queued else "")
    MARK = "@@session-mark@@"
    queued = False
    for line in lines:
        if line.startswith("#sleep "):
            time.sleep(float(line.split()[1]))
            continue
        out.write(prompt_now() + line + "\n")
        out.flush()
        word = line.strip().split(" ")[0].upper()
        if word in ("EXIT", "QUIT"):
            break
        if word == "MULTI":
            queued = True
        if queued:
            # inside MULTI an ECHO would be queued too: wait for quiet instead
            proc.stdin.write((line + "\n").encode())
            proc.stdin.flush()
            text = read_for(1.0).decode("utf-8", "replace")
            if word in ("EXEC", "DISCARD"):
                queued = False
            out.write(text)
            continue
        proc.stdin.write((line + "\nECHO " + MARK + "\n").encode())
        proc.stdin.flush()
        buf = b""
        start = time.time()
        while MARK.encode() + b'"\n' not in buf and MARK.encode() + b"\n" not in buf:
            if time.time() - start > 600:
                sys.exit("session.py: no answer from redis-cli")
            r, _, _ = select.select([fd], [], [], 1)
            if r:
                chunk = os.read(fd, 65536)
                if not chunk:
                    break
                buf += chunk
        text = buf.decode("utf-8", "replace")
        text = re.sub(r'"?%s"?\n' % re.escape(MARK), "", text)
        out.write(text)
        # what redis-cli itself would now draw: the database after a SELECT,
        # and the node a cluster redirect moved the connection to
        if word == "SELECT" and text.strip() == "OK":
            n = line.split()[1]
            db = "" if n == "0" else "[%s]" % n
        m = re.findall(r"-> Redirected to slot \[\d+\] located at ([^:\s]+):(\d+)", text)
        if m:
            host, port = m[-1]
    proc.stdin.close()
    proc.wait()
