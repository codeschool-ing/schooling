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
import subprocess
import signal
import sys
import time

HOST = "vm"
PROMPT = re.compile(r"^(?:(?P<user>[a-z][a-z0-9]*)@" + HOST +
                    r":(?P<cwd>[^\s$#]*)(?P<sigil>[$#])(?: |$)|(?P<bare>\$) )(?P<cmd>.*)$")
# PowerShell's prompt. It is typed into one pwsh kept for the whole run.
PSPROMPT = re.compile(r"^PS (?P<cwd>/\S*)> (?P<cmd>.*)$")
SENTINEL = "@@REPLAY@@"
MARK = 'printf "@@REP""LAY@@ %s %s\\n" "$?" "$PWD"'
PASSWORDS = {"ana": "ana-lab-password", "bruno": "practice", "carla": "practice"}
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
            # Python ignores SIGPIPE and a child inherits that; a terminal's shell
            # does not, and `grep ... | head` must die quietly as it does there.
            signal.signal(signal.SIGPIPE, signal.SIG_DFL)
            os.chdir(home(user))
            argv = ["/bin/bash", "--noprofile", "--norc", "-i"]
            if os.environ.get("REPLAY_SSH"):
                # Another machine: a guest with systemd and cgroup v2, reached by
                # ssh as the user the prompt names, with a terminal of its own.
                argv = os.environ["REPLAY_SSH"].split() + ["-tt", f"{user}@127.0.0.1", "env",
                        "LANG=C.UTF-8", "TERM=linux", f"COLUMNS={cols}", "PAGER=cat",
                        "SYSTEMD_PAGER=", "bash", "--noprofile", "--norc", "-i"]
            elif user != "root":
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
            if self._answers and (tail.endswith("? ") or tail.endswith(": ")):
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


class Pwsh:
    """One pwsh, as ana. Commands go in through a pipe, which is how `-Command -`
    reads them, and come out on a pty, so that tables are as wide as a terminal
    and not as wide as nothing. A marker line after each command says where it
    ended; the transcripts in this course hold one statement line per prompt."""

    MARK = '[Console]::Out.WriteLine("@@REP" + "LAY@@ 0 " + $PWD.Path)'

    def __init__(self, cols):
        rd, self.wr = os.pipe()
        pid, fd = pty.fork()
        if pid == 0:
            signal.signal(signal.SIGPIPE, signal.SIG_DFL)
            os.dup2(rd, 0)
            os.chdir(home("ana"))
            env = {"HOME": home("ana"), "USER": "ana", "LOGNAME": "ana", "SHELL": "/bin/bash",
                   "TERM": "dumb", "LANG": "C.UTF-8", "TZ": os.environ.get("TZ", "UTC"),
                   "PATH": "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"}
            os.execvpe("/usr/sbin/runuser", ["runuser", "-u", "ana", "--", "pwsh", "-NoLogo",
                                              "-NoProfile", "-Command", "-"], env)
        os.close(rd)
        import fcntl, struct, termios
        fcntl.ioctl(fd, termios.TIOCSWINSZ, struct.pack("HHHH", 50, cols, 0, 0))
        self.pid, self.fd, self.cwd = pid, fd, home("ana")
        self.run("$PSStyle.OutputRendering = 'PlainText'")

    def run(self, cmd, timeout=60):
        os.write(self.wr, (cmd + "\n" + self.MARK + "\n").encode())
        buf, end = b"", time.time() + timeout
        pat = re.compile(re.escape(SENTINEL.encode()) + rb" \d+ (.*?)\r?\n")
        while time.time() < end:
            m = pat.search(buf)
            if m:
                self.cwd = m.group(1).decode()
                out = buf[:m.start()].decode(errors="replace").replace("\r\n", "\n")
                # The host puts a blank line before and after a table; the
                # transcripts were trimmed of both.
                lines = out.split("\n")
                while lines and not lines[0].strip():
                    lines.pop(0)
                while lines and not lines[-1].strip():
                    lines.pop()
                return "\n".join(lines) + ("\n" if lines else ""), 0
            r, _, _ = select.select([self.fd], [], [], 0.2)
            if r:
                buf += os.read(self.fd, 65536)
        return buf.decode(errors="replace") + "\n[replay: TIMEOUT]", -1

    def cd(self, path):
        if path and path != self.cwd:
            self.run(f"Set-Location '{path}'")

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


def shquote(text):
    return "'" + text.replace("'", "'\\''") + "'"


def incomplete(cmd):
    """Whether bash would print PS2 and wait for more after this much of a command."""
    m = re.search(r"<<-?\s*['\"]?(\w+)['\"]?", cmd)
    if m and not re.search(r"^\s*" + m.group(1) + r"\s*$", cmd.split("\n", 1)[1] if "\n" in cmd else "", re.M):
        return True  # a here-document still waiting for its last line
    if cmd.rstrip().endswith("\\") or cmd.rstrip().endswith("|"):
        return True
    p = subprocess.run(["bash", "-n", "-c", cmd], capture_output=True, text=True)
    return "unexpected end of file" in p.stderr or "unexpected EOF" in p.stderr


def steps(body):
    """Split a transcript into (prompt line, user, cwd, command, expected output)."""
    res, cur = [], None
    for ln in body:
        m = PSPROMPT.match(ln)
        if m:
            if cur:
                res.append(cur)
            cur = [ln, "@pwsh", m.group("cwd"), m.group("cmd"), []]
            continue
        m = PROMPT.match(ln)
        if m:
            if cur:
                res.append(cur)
            user = m.group("user")
            cur = [ln, user, m.group("cwd"), m.group("cmd"), []]
        elif cur is not None and ln.startswith(">") and not cur[4] and incomplete(cur[3]):
            cur[3] += "\n" + ln[2:]
            cur[0] += "\n" + ln
        elif cur is not None:
            cur[4].append(ln)
    if cur:
        res.append(cur)
    return res


def is_transcript(lang, body):
    return lang == "" and any(PROMPT.match(ln) or PSPROMPT.match(ln) for ln in body)


def screen(cmd):
    words = cmd.strip().split()
    if not words:
        return False
    first = words[1] if words[0] in ("sudo",) and len(words) > 1 else words[0]
    if first == "passwd" and any(w.startswith("-") for w in words):
        return False  # -S, -l, -u: a question about the password, not a prompt for one
    return first in SCREEN or cmd.strip() in SCREEN or cmd.strip() in WAITS or "less" in re.split(r"[|\s]+", cmd)[-1:]


class Machine:
    def __init__(self, cols):
        self.cols, self.shells, self.stack = cols, {}, [("ana", True)]
        self.pwsh = None
        self.quiet_jobs = False

    def shell(self, user):
        if user not in self.shells:
            self.shells[user] = Shell(user, self.cols)
            if self.quiet_jobs:
                self.shells[user].run("set +m")
        return self.shells[user]

    def step(self, user, cwd, cmd, answers=(), expect=()):
        if user == "@pwsh":
            if self.pwsh is None:
                self.pwsh = Pwsh(self.cols)
            self.pwsh.cd(cwd)
            return self.pwsh.run(cmd)
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
        if self.pwsh:
            self.pwsh.close()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("files", nargs="+")
    ap.add_argument("--write", action="store_true")
    ap.add_argument("--only", default="", help="write only these fence numbers; every fence still runs")
    ap.add_argument("--setup", action="store_true", help="run `sh` fences instead of skipping them")
    ap.add_argument("--setup-home", action="store_true",
                    help="run only the `sh` fences that start in the student's home (`cd ~/…`, "
                         "`mkdir -p ~/…`): from lesson 9 on, a lesson also shows `sh` fences that "
                         "are examples to read, not steps to take")
    ap.add_argument("--cols", type=int, default=100)
    ap.add_argument("--materialize", action="store_true",
                    help="a `cat NAME` whose file is missing writes NAME from the transcript first, "
                         "as the student is told to, and makes it executable")
    ap.add_argument("--quiet", action="store_true", help="print only fences that differ")
    ap.add_argument("--select", default="",
                    help="run only these transcript numbers (setup fences still run): the ones "
                         "a section captured on another machine, with REPLAY_SSH")
    ap.add_argument("--no-job-control", action="store_true",
                    help="`set +m` in every shell: a load started in the background by a setup "
                         "block then ends without a `[1]+ Done` landing in the next transcript")
    a = ap.parse_args()
    only = {int(x) for x in a.only.split(",") if x}
    select = {int(x) for x in a.select.split(",") if x}
    mach, n, differ = Machine(a.cols), 0, 0
    mach.quiet_jobs = a.no_job_control
    try:
        for path in a.files:
            text = open(path).read()
            lines, fs = fences(text)
            edits = []
            for start, end, lang, body in fs:
                home_first = bool(body) and re.match(r"^(cd|mkdir)( -p)? (~|/tmp)", body[0])
                if lang == "sh" and (a.setup or (a.setup_home and home_first)):
                    sh = mach.shell("ana")
                    out, st = sh.run("{\n" + "\n".join(body) + "\n}", timeout=900)
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
                if select and n not in select:
                    continue
                got, manual = [], False
                # A prompt in the middle of a line is output with no final newline
                # followed by the next prompt; a bare `read` waits for the keyboard.
                # Neither can be typed into a pipe and kept in step.
                if any(re.search(r"\S(ana|root|bruno|carla|dora|demo)@" + HOST + r":\S*[$#] ", l) for l in body) or \
                        any(re.match(r"^read\b[^<|]*$", st_[3].strip()) for st_ in steps(body)):
                    print(f"## [{n}] {path}:{start} MANUAL (typed input, or output with no newline)")
                    continue
                for prompt, user, cwd, cmd, expect in steps(body):
                    got.append(prompt)
                    if screen(cmd) or any(l.startswith("^C") or l.startswith("^Z") for l in expect):
                        manual = True
                        break
                    mc = re.match(r"^cat ([\w.-]+\.(?:sh|py|txt|ps1))$", cmd.strip())
                    if a.materialize and mc and expect and user != "@pwsh":
                        sh = mach.shell(user or "ana")
                        if cwd:
                            sh.cd(cwd)
                        name = mc.group(1)
                        body_text = "\n".join(expect) + "\n"
                        sh.run(f"[ -e {name} ] || {{ printf '%s' {shquote(body_text)} > {name}; chmod +x {name}; }}")
                    answers = [m.group(1) for m in (re.search(r"[?:] (y|n|yes|no)$", l) for l in expect) if m]
                    out, st = mach.step(user, cwd, cmd, answers, expect)
                    if st == -1 and "[replay: TIMEOUT]" in out:
                        manual = True
                        break
                    printed = out != ""
                    out = "\n".join(l.rstrip().expandtabs(8) for l in out.split("\n"))
                    if out.endswith("\n"):
                        out = out[:-1]
                    if printed:
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
