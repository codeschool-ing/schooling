#!/usr/bin/env python3
"""Type lines into an interactive psql, and print what the screen showed.

    python3 session.py DBNAME [psql options...] < lines

Each line of stdin is typed at the prompt as a person would type it. psql runs
in a pseudo-terminal, so the prompt is psql's own (`shop=#`, `shop=*#` inside
a transaction) and so is every word it prints. What this adds is layout: one
blank line between one command's output and the next prompt, which is how the
course lays a session out, and nothing else. The banner psql prints on start is
kept when the first line of stdin is `#banner`.
"""
import os, pty, re, select, sys, time

PROMPT = re.compile(rb'(?:^|\n)([A-Za-z0-9_]+[=\-*(\'"!]*\*?[#>] )$')

def read_until_prompt(fd, timeout=600):
    buf = b''
    end = time.time() + timeout
    while time.time() < end:
        r, _, _ = select.select([fd], [], [], 0.2)
        if r:
            try:
                chunk = os.read(fd, 65536)
            except OSError:
                return buf, None
            if not chunk:
                return buf, None
            buf += chunk
            m = PROMPT.search(buf)
            if m:
                # make sure nothing else is coming
                r, _, _ = select.select([fd], [], [], 0.3)
                if not r:
                    return buf[:m.start(1)], m.group(1).decode()
    raise SystemExit('session.py: no prompt after %ds; got:\n%s' % (timeout, buf.decode(errors='replace')))

def main():
    args = sys.argv[1:]
    lines = sys.stdin.read().split('\n')
    if lines and lines[-1] == '':
        lines.pop()
    banner = bool(lines) and lines[0] == '#banner'
    if banner:
        lines = lines[1:]
    env = dict(os.environ, PAGER='', PSQL_PAGER='', COLUMNS='400', LINES='400')
    pid, fd = pty.fork()
    if pid == 0:
        os.execvpe('psql', ['psql', '-n', '-P', 'pager=off'] + args, env)
    out, prompt = read_until_prompt(fd)
    out = out.replace(b'\r\n', b'\n').decode()
    if banner:
        sys.stdout.write(out if out.endswith('\n\n') else out + '\n')
    gap = False
    for line in lines:
        if gap:
            sys.stdout.write('\n')
        os.write(fd, line.encode() + b'\n')
        out, nprompt = read_until_prompt(fd)
        text = out.replace(b'\r\n', b'\n').decode()
        echo = line + '\n'
        if text.startswith(echo):
            text = text[len(echo):]
        text = text.rstrip('\n')
        sys.stdout.write(prompt + line + '\n')
        if text:
            sys.stdout.write(text + '\n')
        gap = bool(text)
        prompt = nprompt
        if prompt is None:
            break
    if prompt is not None:
        os.write(fd, b'\\q\n')
    try:
        os.waitpid(pid, 0)
    except ChildProcessError:
        pass

main()
