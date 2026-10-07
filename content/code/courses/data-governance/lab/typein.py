#!/usr/bin/env python3
"""Run a command on a terminal and type answers at its password prompts.

    python3 typein.py ANSWER [ANSWER...] -- COMMAND [ARG...]

psql's \\password, like every program that asks for a secret, reads it from
the terminal and not from standard input, so a pipe cannot answer it. The
capture scripts use this instead of a person: each time the program prints a
line ending in a colon, the next answer is typed, unechoed, as a person would.
What the program printed is passed through, so a transcript shows the prompts
and never the answers.
"""
import os
import pty
import sys
import time

sep = sys.argv.index("--")
answers, cmd = sys.argv[1:sep], sys.argv[sep + 1:]
pid, fd = pty.fork()
if pid == 0:
    os.execvp(cmd[0], cmd)
buf = b""
out = sys.stdout.buffer
while True:
    try:
        chunk = os.read(fd, 1024)
    except OSError:
        break
    if not chunk:
        break
    out.write(chunk.replace(b"\r\n", b"\n"))
    out.flush()
    buf += chunk
    if answers and buf.rstrip().endswith(b":"):
        time.sleep(0.1)
        os.write(fd, answers.pop(0).encode() + b"\n")
        buf = b""
_, status = os.waitpid(pid, 0)
sys.exit(os.waitstatus_to_exitcode(status))
