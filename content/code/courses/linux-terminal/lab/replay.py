#!/usr/bin/env python3
"""Re-run the transcripts of linux-terminal and compare them with the prose.

THE AUTHOR'S TOOL. The loader reads nothing under lab/, and no lesson names it.

A transcript is an untagged fence whose lines start with a prompt —
`ana@vm:~/work$ `, `root@vm:~# ` or a bare `$ `. Each command is typed into a
real interactive bash on a pseudo-terminal, as the user the prompt names, in
the directory the prompt names, and what it prints is compared with what the
fence says it printed.

    sudo python3 replay.py FILE.md ...            # report the fences that differ
    sudo python3 replay.py --write FILE.md ...    # paste the new output in place
    sudo python3 replay.py --setup FILE.md ...    # run a section's `sh` fences first

Shells are kept for the whole run, so a variable set in one fence is there in
the next, as it is for a student reading the sections in order. `sudo -i`,
`sudo -iu <user>`, `su - <user>` and `exit` switch between those shells rather
than nesting them. A fence holding a command that takes the screen (an editor,
a pager, top) is reported as MANUAL and never rewritten.

Machine-dependent values — process ids, dates, timings — differ on every run.
--write rewrites what it is given, so give it the fences that need it
(`--only N,M` by the index this tool prints) and read the diff before keeping it.
"""

import argparse
import difflib
import os
import pty
import re
import select
import signal
import sys
import time

HOST = "vm"
PROMPT = re.compile(r"^(?:(?P<user>[a-z][a-z0-9]*)@" + HOST +
                    r":(?P<cwd>[^\s$#]*)(?P<sigil>[$#])(?: |$)|(?P<bare>\$) )(?P<cmd>.*)$")
SENTINEL = "@@REPLAY@@"
MARK = 'printf "@@REP""LAY@@ %s %s\\n" "$?" "$PWD"'
PASSWORDS = {"ana": "ana-lab-password", "bruno": "bruno-lab-password", "carla": "practice"}
SCREEN = {"top", "htop", "vim", "vi", "nano", "emacs", "less", "more", "watch",
          "vimtutor", "passwd", "mc", "ssh", "sudoedit", "visudo", "crontab -e"}
# Commands that read the keyboard when given no file.
WAITS = {"cat", "bash", "sh", "wc", "sort", "tr", "read"}


def home(user):
    return "/root" if user == "root" else f"/home/{user}"


class Shell:
    """One interactive bash on a pty, as one user."""

    def __init__(self, user, cols):
        self.user = user
        env = {"HOME": home(user), "USER": user, "LOGNAME": user, "SHELL": "/bin/bash",
               "TERM": "linux", "LANG": "C.UTF-8", "TZ": os.environ.get("TZ", "UTC"),
               "PATH": "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin",
               "PAGER": "cat", "MANPAGER": "cat", "SYSTEMD_PAGER": "", "COLUMNS": str(cols)}
        if user != "root":
            # /etc/environment's, which a login on Ubuntu reads through PAM.
            env["PATH"] = ("/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:"
                           "/usr/games:/usr/local/games:/snap/bin")
        pid, fd = pty.fork()
        if pid == 0:
            os.chdir(home(user))
            argv = ["/bin/bash", "--noprofile", "--norc", "-i"]
            if user != "root":
                argv = ["/usr/sbin/runuser", "-u", user, "--", "/bin/bash"] + argv[1:]
            os.execvpe(argv[0], argv, env)
        self.pid, self.fd, self.cwd, self._answered, self._answers = pid, fd, home(user), False, []
        self._raw(f"bind 'set enable-bracketed-paste off'; bind 'set disable-completion on'; stty -echo cols {cols} rows 50; PS2='> '; "
                  f"PROMPT_COMMAND='{MARK}'; unset HISTFILE; cd ~\n")
        self._read_until_prompt(10)
        # The transcripts in this course were taken from a shell whose output is
        # not a terminal: `ls` prints one name a line and quotes nothing. Output
        # goes through a pipe to the pty; a password prompt still reaches the pty.
        self.run("exec > >(exec cat) 2>&1")
        # What an interactive login on Ubuntu reads: the system's bashrc, which
        # brings command-not-found, then the user's own.
        self.run(". /etc/bash.bashrc >/dev/null 2>&1; [ -f ~/.bashrc ] && . ~/.bashrc >/dev/null 2>&1; "
                 "PROMPT_COMMAND='" + MARK + "'; unset HISTFILE")
        self.cwd = home(user)

    def _raw(self, text):
        os.write(self.fd, text.encode())

    def _read_until_prompt(self, timeout):
        buf, end = b"", time.time() + timeout
        pat = re.compile(re.escape(SENTINEL.encode()) + rb" (\d+) (.*?)\r?\n")
        while True:
            m = pat.search(buf)
            if m:
                return buf[:m.start()].decode(errors="replace"), int(m.group(1)), m.group(2).decode()
            left = end - time.time()
            if left <= 0:
                # Interrupt it and wait for the prompt, so the next command's
                # output is not this one's.
                os.write(self.fd, b"\x03")
                end2 = time.time() + 10
                while not pat.search(buf) and time.time() < end2:
                    r, _, _ = select.select([self.fd], [], [], 0.2)
                    if r:
                        buf += os.read(self.fd, 65536)
                m = pat.search(buf)
                if m:
                    self.cwd = m.group(2).decode()
                return buf.decode(errors="replace") + "\n[replay: TIMEOUT]", -1, self.cwd
            tail = buf[-60:].decode(errors="replace")
            if self._answers and tail.endswith("? "):
                ans = self._answers.pop(0)
                os.write(self.fd, (ans + "\n").encode())
                buf += (ans + "\n").encode()  # what the terminal would have echoed
                continue
            if tail.endswith(f"password for {self.user}: ") and not self._answered:
                self._answered = True
                os.write(self.fd, (PASSWORDS.get(self.user, "") + "\n").encode())
            elif tail.endswith("Password: ") and not self._answered:
                self._answered = True
                os.write(self.fd, b"\n")
            r, _, _ = select.select([self.fd], [], [], min(left, 0.2))
            if r:
                try:
                    buf += os.read(self.fd, 65536)
                except OSError:
                    return buf.decode(errors="replace") + "\n[replay: SHELL GONE]", -1, self.cwd

    def run(self, cmd, timeout=30, answers=()):
        self._answered = False
        self._answers = list(answers)
        self._raw(cmd + "\n")
        out, status, cwd = self._read_until_prompt(timeout)
        self.cwd = cwd
        out = re.sub(r"^[^\n]*?@" + HOST + r":[^\n]*?[$#] ", "", out)
        out = re.sub(r"\x1b\[[0-9;?]*[A-Za-z]|\x1b\][^\x07]*\x07", "", out).replace("\r\n", "\n").replace("\r", "")
        # A command with continuation lines leaves one PS2 per line it read.
        extra = cmd.count("\n")
        while extra and out.startswith("> "):
            out, extra = out[2:], extra - 1
        return out, status

    def cd(self, path):
        path = path.replace("~", home(self.user), 1) if path.startswith("~") else path
        if path and path != self.cwd:
            self.run(f"cd {path!r}")

    def close(self):
        try:
            os.kill(self.pid, signal.SIGKILL)
        except ProcessLookupError:
            pass


def fences(text):
    """(start, end, lang, lines) for every fence, end exclusive of the closing line."""
    lines = text.split("\n")
    out, i = [], 0
    while i < len(lines):
        m = re.match(r"^(\s*)```(\S*)\s*$", lines[i])
        if m:
            j = i + 1
            while j < len(lines) and not re.match(r"^\s*```\s*$", lines[j]):
                j += 1
            out.append((i + 1, j, m.group(2), lines[i + 1:j]))
            i = j + 1
        else:
            i += 1
    return lines, out


def steps(body):
    """Split a transcript into (prompt line, user, cwd, command, expected output)."""
    res, cur = [], None
    for ln in body:
        m = PROMPT.match(ln)
        if m:
            if cur:
                res.append(cur)
            user = m.group("user")
            cur = [ln, user, m.group("cwd"), m.group("cmd"), []]
        elif cur is not None and ln.startswith("> ") and not cur[4]:
            cur[3] += "\n" + ln[2:]
            cur[0] += "\n" + ln
        elif cur is not None:
            cur[4].append(ln)
    if cur:
        res.append(cur)
    return res


def is_transcript(lang, body):
    return lang == "" and any(PROMPT.match(ln) for ln in body)


def screen(cmd):
    words = cmd.strip().split()
    if not words:
        return False
    first = words[1] if words[0] in ("sudo",) and len(words) > 1 else words[0]
    return first in SCREEN or cmd.strip() in SCREEN or cmd.strip() in WAITS or "less" in re.split(r"[|\s]+", cmd)[-1:]


class Machine:
    def __init__(self, cols):
        self.cols, self.shells, self.stack = cols, {}, [("ana", True)]

    def shell(self, user):
        if user not in self.shells:
            self.shells[user] = Shell(user, self.cols)
        return self.shells[user]

    def step(self, user, cwd, cmd, answers=(), expect=()):
        user = user or self.stack[-1][0]
        c = cmd.strip()
        if re.match(r"^sudo\b", c) and user != "root" and c not in ("sudo -k", "sudo -v"):
            # Whether sudo asks for the password depends on when it last did,
            # which is the session's history and not the command's. Ask exactly
            # where the transcript shows it asking.
            pre = self.shell(user)
            asks = bool(expect) and expect[0].startswith("[sudo] password for")
            pre.run("sudo -k" if asks else "sudo -v")
        m = re.match(r"^(?:sudo -i(?:u (\w+))?|sudo su -(?: (\w+))?|su - (\w+)|sudo -s)$", c)
        if m:
            # Becoming somebody else opens a second shell; here it is a shell of
            # its own, kept apart. What the first shell would have printed — sudo
            # asking for the password, unless it remembers — comes from `sudo -v`.
            out, st = "", 0
            if c.startswith("sudo"):
                sh = self.shell(user)
                if cwd:
                    sh.cd(cwd)
                out, st = sh.run("sudo -v")
            login = c != "sudo -s"
            self.stack.append((m.group(1) or m.group(2) or m.group(3) or "root", login))
            return out, st
        if c in ("exit", "logout") and len(self.stack) > 1:
            _, login = self.stack.pop()
            return ("logout\n" if login else ""), 0
        sh = self.shell(user)
        if cwd:
            sh.cd(cwd)
        if c.startswith("newgrp"):
            # A new shell starts inside this one and has never heard of the marker.
            sh._raw(cmd + "\n")
            time.sleep(0.5)
            return sh.run("PROMPT_COMMAND='" + MARK + "'; unset HISTFILE", answers=answers)
        return sh.run(cmd, answers=answers)

    def close(self):
        for s in self.shells.values():
            s.close()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("files", nargs="+")
    ap.add_argument("--write", action="store_true")
    ap.add_argument("--only", default="", help="write only these fence numbers; every fence still runs")
    ap.add_argument("--setup", action="store_true", help="run `sh` fences instead of skipping them")
    ap.add_argument("--cols", type=int, default=100)
    ap.add_argument("--quiet", action="store_true", help="print only fences that differ")
    a = ap.parse_args()
    only = {int(x) for x in a.only.split(",") if x}
    mach, n, differ = Machine(a.cols), 0, 0
    try:
        for path in a.files:
            text = open(path).read()
            lines, fs = fences(text)
            edits = []
            for start, end, lang, body in fs:
                if lang == "sh" and a.setup:
                    sh = mach.shell("ana")
                    out, st = sh.run("{\n" + "\n".join(body) + "\n}")
                    print(f"# {path}:{start} setup ran, status {st}" + (f"\n{out}" if out.strip() else ""))
                    if re.search(r"^#.*\blog out\b", "\n".join(body), re.I | re.M):
                        # The block ends by telling the student to sign in again, so a
                        # group added to them applies: start every shell afresh.
                        mach.close()
                        mach.shells = {}
                    continue
                if not is_transcript(lang, body):
                    continue
                n += 1
                got, manual = [], False
                for prompt, user, cwd, cmd, expect in steps(body):
                    got.append(prompt)
                    if screen(cmd) or any(l.startswith("^C") or l.startswith("^Z") for l in expect):
                        manual = True
                        break
                    answers = [m.group(1) for m in (re.search(r"\? (y|n|yes|no)$", l) for l in expect) if m]
                    out, st = mach.step(user, cwd, cmd, answers, expect)
                    if st == -1 and "[replay: TIMEOUT]" in out:
                        manual = True
                        break
                    out = "\n".join(l.rstrip().expandtabs(8) for l in out.split("\n"))
                    if out.endswith("\n"):
                        out = out[:-1]
                    if out:
                        got.extend(out.split("\n"))
                want = [l.rstrip() for l in body]
                if manual:
                    print(f"## [{n}] {path}:{start} MANUAL (a command that takes the screen)")
                    continue
                if got == want:
                    if not a.quiet:
                        print(f"## [{n}] {path}:{start} same")
                    continue
                differ += 1
                print(f"## [{n}] {path}:{start} DIFFERS")
                for d in difflib.unified_diff(want, got, "prose", "replay", lineterm="", n=1):
                    print("   " + d)
                if not only or n in only:
                    edits.append((start, end, got))
            if a.write and edits:
                for start, end, got in reversed(edits):
                    lines[start:end] = got
                open(path, "w").write("\n".join(lines))
    finally:
        mach.close()
    print(f"# {n} transcripts, {differ} differ")


if __name__ == "__main__":
    main()
