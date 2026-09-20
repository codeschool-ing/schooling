---
format: 5
course: linux-terminal
---

# linux-terminal

**Linux and the Command Line** · `co-7mr8mhy8` · 70 h declared · beginner · 13 lessons · `infra` · **free**

## Reach

In **10 tracks** — `backend`(4), `cloud-engineering`(2), `data`(2), `dba`(3), `devops`(2), `devsecops`(1), `it-support`(4), `networks-infra`(2), `security`(3), `software-architecture`(4).

**Depends on it:** `db-administration`, `docker`, `networks`, `servers-cache`

## Assumes, and leaves ready

**Assumes:** nothing. It is an entry course.

**Leaves ready:** the shell, the filesystem, processes and permissions — for `docker`, `networks`, `db-administration` and `servers-cache`. **`docker` and `networks` between them reach 15 tracks**, so what is left vague here is vague across most of the catalogue.

## Shape

| | |
|---|---|
| declared hours | 70 h |
| lessons | 13 |
| **hours per lesson** | **5.38** |
| section budget | ~150, about 11.5 a lesson — **and 228 are written**; the arithmetic is below |
| sections | **228** — 175 reading, 40 video, 13 practice; counted from `content/` |
| exercises | **949**, counted after the course was written |
| video | estimated, not a target (`C-36`) |
| avatar visible | **~15%** of video runtime, and only in the opening and the closing — the reason is below |

**The exercise row is a measurement and the rest of this table is a design.** It said ~890 with
a floor of 700, and the course came out at 949 across its thirteen lessons — over the estimate
and well clear of the floor, which is the outcome the floor existed to guarantee. The estimate is
superseded rather than wrong, and leaving it would make `check-design` report a 7% overrun for as
long as this course exists, in the column where a real overrun would have to be noticed. The
floor has done its job and is recorded here rather than in the table: **no fewer than 700**, which
is the number that would have meant something if the writing had come in short.

Exercise types: `quiz`, `multiple-choice`, `ordering`, `matching`, `cloze`, `labelling`,
`numeric`, **`expected-output`**. The last one has no grader, which is why the Execution table
below says *publishable degraded* rather than *blocked*: a question nobody checked renders as
`correct: null` and the student is told so, per `EXECUTOR.md`.

## Execution

| | |
|---|---|
| runtime | **shell**, and nothing beyond it |
| browser · database | no · no |
| exercises **blocked** | **0** — publishable degraded |
| exercises that would **improve** | **almost all of the practice.** This is the course the shell sandbox exists for: a command and its output *is* the subject, and every substitute teaches recognition |
| diagrams to draw | ~28 — the filesystem tree, the permission bits, the process tree and lifecycle, the three streams and a pipeline, a unit's dependencies, the cron fields |

## Ageing

**Lowest in the catalogue.** The shell has been stable for decades.

## Sections

Five volumes. **The volumes are a reading device; the lessons and their ids are the contract
with the portal and do not move.** The numbering 01–228 is the path a student walks, in the
order they walk it.

### The video here is a terminal — and the lesson still opens and closes on a face

`web-fundamentals` puts the presenter on screen for about a fifth of its runtime and all of
every opening. **The middle of this course cannot afford that shape and does not want it**, for
a reason that belongs to the subject: what a student needs to see is a prompt, a command being
typed, and the output arriving — the pause between the two included. A face over that is the
decoration `C-30` already refused.

**But a lesson that ends on a maximised terminal ends without anybody saying so.** The screen
goes quiet, the voice stops, and the last thing the student was told is what the command
printed. So the rule is a bracket rather than a ceiling:

| | mode | length |
|---|---|---|
| the **opening** | `full` — presenter, no screen | 60–90 s |
| everything between | **screen only** — a real terminal, real output, voice over it | as long as the demonstration takes |
| the **closing** | `full` — presenter again, for the considerations that are the lesson's own | 30–60 s |

That is what a closing is for and it is not a summary of the sections: it is what the student
should be holding now, what is going to feel wrong tomorrow anyway, and why the next lesson is
the next lesson. It lands **before the drill**, which stays last — you say what was learnt, then
the student practises it.

The bracket costs about **15% of video runtime as avatar**, against `web-fundamentals`' 20–25%.
The earlier figure in this sheet was 8%, and it was 8% because there was no closing: the number
moved because the design did, which is the right direction for a number to move.

**Every lesson gets a demonstration**, and in this course the demonstration is not optional
garnish: the material is a thing people do, and a lesson that never shows it being done teaches
vocabulary. Lesson 1 gets two, because a beginner who has never opened a terminal needs one
before the readings and one after.

### Every command in this course was run

The prose quotes output. **That output is captured from a real command on a real machine, not
written by hand** — a transcript somebody typed from memory is the fastest way to teach a
student a prompt that does not exist and a flag that was removed two releases ago.

The mechanism is `charmbracelet/vhs`: a `.tape` file beside the prose, listing the commands and
the terminal size, and a recording made from it. **The tapes are committed; the GIFs are not.**
Output enters the material as an ordinary code fence, so nothing in the renderer changes and
nothing in the bundle grows — the tape is provenance, kept so the next person can re-run it
against a newer distribution and see what moved.

This is a decision made here, for this course. `TEACHING.md`'s open question — *where
illustration stops being authorable* — is where it belongs once a second course needs it.

### What a section is worth here, and why there are 228 of them

The budget of ~150 came from declared hours at the catalogue's average density. Two numbers
argue it is low.

**The measured precedent.** `web-fundamentals` is the only other designed sheet: 94 sections for
40 declared hours, or 2.35 sections an hour. At that density 70 hours is **164 sections**, not
150 — so the budget was already under the only figure anybody has actually designed against.

**And 228 is counted rather than designed.** This sheet said 223 and enumerated them; the course
was then written, and seven of its thirteen lessons came out against a different arrangement of
sections from the one listed here — five more in total, and, underneath that small difference,
fifty-five section names the sheet did not have. The tables below are now the written course,
which is the only version a student can read. It is the same correction the exercise row got, one
column across: **a number that can be counted is not an estimate, and leaving the estimate makes
the sheet disagree with the catalogue for as long as the course exists.**

**And this course's sections are shorter.** 228 sections in 70 hours is eighteen and a half
minutes each, against `web-fundamentals`' 25.5. That difference is real and it is not padding: a
section there establishes a concept that took five paragraphs to build, and a section here is
frequently one command, its three or four flags that matter, the output it prints, and five
questions. `grep` is not a smaller subject than the CSSOM; it is a subject that reaches the
student in less time, because they can run it. The average also understates the readings, because
26 of the 228 are an opening or a closing and those are ninety seconds apiece.

**The declared hours do not move** — they are on the course card and in the portal — so of the
two ways to absorb 228 sections, this sheet takes the one that does not change the contract.
If the real figure turns out to be 80 hours rather than 70, that is a catalogue change with its
own argument, not something a design sheet gets to decide.

---

## Volume I — Where you are

**Lesson 1 · Linux, Unix and Windows: differences in day-to-day operations** — `le-232xd54k`

| | slug | kind | covers |
|---|---|---|---|
| 01 | `intro` | video | Why the machines that run everything are ones you have never touched — **opening** |
| 02 | `one-family` | reading | Unix, Linux, macOS, BSD: shared ancestry, a clone, and what POSIX promises |
| 03 | `kernel-shell-terminal` | reading | Three words used as one — kernel, shell, terminal emulator — and which of them the prompt belongs to |
| 04 | `getting-a-linux` | reading | WSL, a virtual machine, a container, a live USB, a cloud instance: five ways to have one, and what each costs |
| 05 | `first-contact` | video | A terminal opened and five commands typed, with nothing explained yet — **demonstration** |
| 06 | `the-prompt` | reading | Reading `user@host:~$`: who you are, where you are, and the `#` that means you are root |
| 07 | `shape-of-a-command` | reading | Command, options, arguments; short and long options; why a space is a separator and not decoration |
| 08 | `terminal-keys` | reading | Tab, history, `Ctrl+C`, `Ctrl+D`, `Ctrl+L`, `Ctrl+R` — and that `Ctrl+C` is not copy |
| 09 | `everything-is-a-file` | reading | Devices, sockets and `/proc` behind one interface, and what the idea buys you |
| 10 | `one-tree` | reading | One rooted tree against drive letters: a disk is mounted somewhere, not assigned a letter |
| 11 | `case-and-names` | reading | Case sensitivity, spaces in names, the dot that hides a file, and the extension that decides nothing |
| 12 | `line-endings` | reading | LF against CRLF, and the script that dies saying `$'\r': command not found` |
| 13 | `where-things-live` | reading | A first map — `/etc`, `/home`, `/var`, `/usr`, `/tmp` — against Program Files, Users and AppData |
| 14 | `who-you-are` | reading | Multi-user by design: root, your user, and why you are not the administrator by default |
| 15 | `software-comes-from-a-repository` | reading | No installer downloaded from a website, and updates that do not reboot — the day-to-day difference, before lesson 7 explains the machinery |
| 16 | `the-manual` | reading | `man`, `--help`, `apropos`, `tldr`: how to answer your own question after this course ends |
| 17 | `when-it-goes-wrong` | reading | Reading an error — not found, permission denied, no such file — and the exit status behind it |
| 18 | `windows-side-by-side` | reading | The table, once: paths, separators, permissions, services, packages, shells |
| 19 | `a-first-session` | video | One small real task, start to finish, using only what lesson 1 taught — **demonstration** |
| 20 | `closing` | video | What you can carry out of a first hour at a prompt, and the one thing that will still feel wrong tomorrow — **closing** |
| 21 | `drill` | practice | Fourteen situations: name the piece, read the prompt, say what the error means |

**`getting-a-linux` is the section without which the course does not work**, and a budget-shaped
design would not have it: it teaches no Linux at all. It is here because ten tracks start at this
course, its students are on Windows or a Mac, and a course whose entire practice is typing
commands cannot begin by assuming a machine to type them into. Five options with their costs,
and a recommendation — WSL if you are on Windows, a container if you are not — so the student is
at a prompt by the end of section 4 rather than reading about one for thirteen lessons.

**`terminal-keys` and `line-endings` are the other two a syllabus never lists.** The first is the
difference between a student who is fluent and one who retypes every path; `Ctrl+C` in particular
is actively mistaught by every other program they have used. The second is a fault that produces
an error message naming a character you cannot see, and it arrives the first time somebody edits
a script on Windows — which, for this audience, is most of them.

**Lesson 2 · Distributions: Ubuntu/Debian, RHEL, Rocky, Alma and SUSE** — `le-072kcf6w`

| | slug | kind | covers |
|---|---|---|---|
| 22 | `intro` | video | One kernel, a hundred distributions, and why the answer matters at three in the morning — **opening** |
| 23 | `what-a-distribution-is` | reading | Kernel, userland, package manager, defaults and policy: the four things being bundled |
| 24 | `the-families` | reading | Debian, Red Hat, SUSE, Arch and the independents — the tree drawn once |
| 25 | `debian-ubuntu` | reading | Debian, Ubuntu and what sits below them |
| 26 | `rhel-and-the-rebuilds` | reading | RHEL, CentOS, CentOS Stream, Rocky and Alma: what happened, and which one you are on now |
| 27 | `suse` | reading | SUSE Linux Enterprise, openSUSE Leap and Tumbleweed |
| 28 | `alpine-and-containers` | reading | musl and busybox: why the image is 5 MB and why your command behaves differently in it |
| 29 | `release-models` | reading | Fixed, LTS and rolling; version numbers that mean something and ones that do not |
| 30 | `lifecycles` | reading | Support windows, end of life, and the upgrade somebody will have to do |
| 31 | `what-actually-differs` | reading | Package manager, service names, config paths, firewall tool, SELinux against AppArmor, default shell |
| 32 | `which-am-i-on` | reading | `/etc/os-release`, `uname -a`, `hostnamectl` — and checking first as a reflex |
| 33 | `choosing` | video | Three real situations, three different answers — **demonstration** |
| 34 | `closing` | video | Why you do not have to choose a distribution, and what to check first when you arrive on somebody's machine — **closing** |
| 35 | `drill` | practice | Given a symptom or a command that failed, name the family |

**`alpine-and-containers` is the section this lesson would have skipped**, and it is the one its
students meet first: `docker` depends on this course, and the base image in every tutorial they
will read is Alpine. It is where `sh` is not bash, `apk` is not `apt`, and a binary built
elsewhere refuses to run for a reason — musl — that has nothing to do with anything else in the
lesson.

## Volume II — The tree

**Lesson 3 · The filesystem, absolute and relative paths** — `le-sv9gbq1q`

| | slug | kind | covers |
|---|---|---|---|
| 36 | `intro` | video | A tree with one root, and the address of everything in it — **opening** |
| 37 | `fhs` | reading | The hierarchy, directory by directory, and what each one is actually for |
| 38 | `absolute-relative` | reading | A leading `/` or not, and what "the current directory" means |
| 39 | `dot-dotdot-tilde` | reading | `.`, `..`, `~`, `-` and `~someone` |
| 40 | `moving-and-looking` | reading | `pwd`, `cd`, `ls`, and the flags worth having in your fingers |
| 41 | `reading-ls-long` | reading | `ls -l` field by field — the densest line in the course, decoded before permissions arrive |
| 42 | `file-operations` | reading | `cp`, `mv`, `rm`, `mkdir`, `rmdir`, `touch`; `-r`, `-i`, and the respect `rm -rf` is owed |
| 43 | `looking-inside` | reading | `cat`, `less`, `head`, `tail`, `file`, `wc`, `stat` |
| 44 | `finding` | reading | `find` by name, time, size and type, `-exec`, and `locate` |
| 45 | `globbing` | reading | `*`, `?`, `[…]`, brace expansion — and that the shell expands them before the command sees anything |
| 46 | `links` | reading | Inodes, hard links and symlinks, and the link that points at nothing |
| 47 | `mounts` | reading | Mounting, `df`, `lsblk`, `/mnt` and `/media`; a second disk arriving as a directory |
| 48 | `disk-usage` | reading | `du`, what is actually taking the space, and `df` disagreeing with it |
| 49 | `hidden-and-special` | reading | Dotfiles, `/proc` and `/sys`, `/dev/null`, `/dev/zero`, `/dev/urandom` |
| 50 | `archives` | reading | `tar`, `gzip`, `zip`: the three-flag incantation explained instead of memorised |
| 51 | `a-walk` | video | A tour of a real root directory, opening things — **demonstration** |
| 52 | `closing` | video | The tree as a map you now carry, and the handful of commands worth trusting your fingers to — **closing** |
| 53 | `drill` | practice | Resolve paths, predict a glob, say where a file belongs |

**Lesson 4 · Permissions, owners, groups, sudo and umask** — `le-chtj4bkk`

| | slug | kind | covers |
|---|---|---|---|
| 54 | `intro` | video | Twelve bits that decide everything — **opening** |
| 55 | `user-group-other` | reading | Three audiences, three bits each, and which one applies to you |
| 56 | `reading-the-mode` | reading | `-rwxr-xr--` character by character, including the first one |
| 57 | `octal` | reading | 755 and 644, and the arithmetic that produces them |
| 58 | `chmod` | reading | Symbolic and numeric, `-R`, and what recursion does to directories |
| 59 | `directory-bits` | reading | What `x` means on a directory — and the readable directory you cannot enter |
| 60 | `chown-chgrp` | reading | Ownership, and why giving a file away needs root |
| 61 | `groups` | reading | Primary and supplementary, `id`, `groups`, and the group as the unit of sharing |
| 62 | `umask` | reading | The mask that decides what a new file is born with |
| 63 | `special-bits` | reading | setuid, setgid and the sticky bit: why `/tmp` needs one and `passwd` the other |
| 64 | `root-and-sudo` | reading | root, `su`, `sudo`, `sudoers` — and why `sudo` beats logging in as root |
| 65 | `sudo-in-practice` | reading | `sudo -i`, the redirect that still fails under sudo, `sudo !!`, and the password timeout |
| 66 | `acl-and-mac` | reading | Where twelve bits run out: `getfacl`/`setfacl`, and SELinux and AppArmor named honestly |
| 67 | `permission-denied` | video | Five denials, each diagnosed to its actual cause — **demonstration** |
| 68 | `closing` | video | Permissions as a question about audiences, and the denial you should now be able to name out loud — **closing** |
| 69 | `drill` | practice | Given a mode and a user, say what happens |

**`sudo-in-practice` exists because of one line**: `sudo echo x > /root/f` fails, and it fails for
a reason — the redirect is the shell's, and the shell is not root — that a student cannot derive
from anything in `root-and-sudo`. It is the most common first sudo mistake there is, and every
answer to it online is a fix without an explanation.

## Volume III — The system, running

**Lesson 5 · Users, services and systemd** — `le-ew9j8tcf`

| | slug | kind | covers |
|---|---|---|---|
| 70 | `intro` | video | Who is on the machine, and what is running when nobody is — **opening** |
| 71 | `what-a-user-is` | reading | `/etc/passwd`, UID, shell and home; the system users that are not people |
| 72 | `shadow-and-passwords` | reading | `/etc/shadow`, hashing, `passwd`, and password ageing |
| 73 | `managing-users` | reading | `useradd`/`adduser`, `usermod`, `userdel`, `groupadd` — and the home directory that stays behind |
| 74 | `login-and-sessions` | reading | Login against interactive shells, `who`, `w`, `last`, and which startup file runs when |
| 75 | `ssh` | reading | Reaching another machine: keys over passwords, `~/.ssh`, and the fingerprint it asks you about |
| 76 | `what-a-service-is` | reading | A program that outlives your session, and the daemon it used to be called |
| 77 | `init-and-pid-1` | reading | What starts everything: SysV init, Upstart, systemd, and why there was an argument |
| 78 | `systemctl` | reading | start, stop, restart, reload, enable, disable, status — the six verbs, and that enable is not start |
| 79 | `reading-status` | reading | `systemctl status` line by line: active, enabled, the PID, and the log lines at the bottom |
| 80 | `unit-files` | reading | `[Unit]`, `[Service]`, `[Install]`; where they live, which copy wins, and `systemctl edit` |
| 81 | `journalctl` | reading | `-u`, `-f`, `--since`, `-p`, and a log that survives a reboot |
| 82 | `targets-and-boot` | reading | Targets instead of runlevels, `systemd-analyze`, and the machine that will not come up |
| 83 | `a-service-that-fails` | video | A unit written, broken, and read back out of the journal — **demonstration** |
| 84 | `closing` | video | The machine as somewhere other people and other programs also are, whether or not you are logged in — **closing** |
| 85 | `drill` | practice | Read a status, choose a verb, find the log |

**`ssh` is in a lesson whose title does not mention it**, deliberately. Nothing else in this
course is where it fits, every machine these students will meet is reached over it, and `networks`
— which owns it properly — is downstream of here and absent from four of the ten tracks that start
here. It is one section: keys, the agent, the fingerprint prompt and what it is for. Config files,
tunnels and hardening are not.

**Lesson 6 · Processes: ps, top, htop, kill, jobs and signals** — `le-8zh2kqda`

| | slug | kind | covers |
|---|---|---|---|
| 86 | `intro` | video | A program is a file; a process is a file that is happening — **opening** |
| 87 | `what-a-process-is` | reading | PID, PPID, the process table, and what a process owns |
| 88 | `lifecycle` | reading | fork, exec, exit, wait — and the parent that has to collect |
| 89 | `states` | reading | Running, sleeping, stopped, zombie and uninterruptible, read off the state column |
| 90 | `ps` | reading | `ps aux` and `ps -ef`, the two dialects, and the columns that matter |
| 91 | `pstree-and-parents` | reading | The tree, orphans, and reparenting to PID 1 |
| 92 | `top-and-htop` | reading | The live view, and what the load average is really counting |
| 93 | `signals` | reading | Numbered messages: TERM, KILL, HUP, INT, STOP — and which ones a program can refuse |
| 94 | `kill` | reading | `kill`, `killall`, `pkill`, and why `-9` is the last resort rather than the first |
| 95 | `jobs` | reading | Foreground and background, `&`, `Ctrl+Z`, `bg`, `fg`, `jobs` |
| 96 | `surviving-the-hangup` | reading | `nohup`, `disown`, and `screen`/`tmux` named for the SSH session that drops |
| 97 | `priority` | reading | `nice` and `renice` — and what a priority is not |
| 98 | `file-descriptors` | reading | 0, 1, 2 and `/proc/<pid>/fd`; `lsof`, and the deleted file still holding the disk |
| 99 | `exit-status` | reading | `$?`, the conventions, and the 130 that means somebody pressed `Ctrl+C` |
| 100 | `a-runaway` | video | Finding and stopping a process that is eating the machine — **demonstration** |
| 101 | `closing` | video | Processes as the thing you can always go and look at when nothing else explains it — **closing** |
| 102 | `drill` | practice | Read a `ps` line, choose a signal, explain a state |

**Lesson 7 · Package managers: apt, dnf/yum and zypper** — `le-gkrq1aza`

| | slug | kind | covers |
|---|---|---|---|
| 103 | `intro` | video | Where everything on this machine came from — **opening** |
| 104 | `what-a-package-is` | reading | An archive plus a list of promises: the metadata, the local database people forget, and why versions look the way they do |
| 105 | `repositories` | reading | A web server with an index, `signed-by` as the whole of repository security, and why `update` is not `upgrade` |
| 106 | `apt-day-to-day` | reading | Reading the paragraph `apt` prints before the prompt; `-y` and when not to use it; unpacking against setting up; `apt` against `apt-get` |
| 107 | `finding-things` | reading | Four questions with one command each: by name, by description, what a package put on the disk, and what put this file here |
| 108 | `dependencies` | reading | What a package declares, seeing the relationships before you commit, and the four ways they go wrong |
| 109 | `dpkg-underneath` | reading | The layer that does exactly what you say, half-installed as a state you will actually meet, and the repair |
| 110 | `remove-and-purge` | reading | Three commands that do three different things, the mark that drives `autoremove`, and the rpm side |
| 111 | `versions-and-holds` | reading | `apt policy` and the number in front of the URL: holding, installing a specific version, and pinning when a hold is not enough |
| 112 | `dnf-and-yum` | reading | `yum` is `dnf`: the repository file, finding, installing with its dependency, and `rpm` underneath |
| 113 | `zypper` | reading | SUSE's — repositories, finding, installing, which package owns a file, and removing |
| 114 | `a-rosetta-stone` | reading | The daily commands in three dialects, the four differences that are not spelling, and how to read one you have never seen |
| 115 | `outside-the-distribution` | reading | Third-party repositories, Snap and Flatpak, language package managers, a binary from a release page, and containers as the other answer |
| 116 | `a-broken-install` | video | Half installed, and the one command that finishes it — **demonstration** |
| 117 | `closing` | video | The manager knows what it did, and the habit is to ask it rather than guess — **closing** |
| 118 | `drill` | practice | Choose the command, read the failure, decide the source |

**`outside-the-distribution` is the section that keeps the lesson honest.** Everything before it
describes a system where software is signed, versioned and removable; the student's actual next
step is a README telling them to pipe a URL into a shell. Naming the three packaging systems and
ranking the options by risk is the difference between a rule they will break silently and a
judgement they can make.

## Volume IV — Text, pipes and scripts

**Lesson 8 · Text: grep, sed, awk, cut, sort, uniq, pipes and redirection** — `le-k41k9p1e`

| | slug | kind | covers |
|---|---|---|---|
| 119 | `intro` | video | Small programs, joined end to end — **opening** |
| 120 | `the-three-streams` | reading | Three streams, why two of them look the same on a terminal, where they actually go, and reading from stdin |
| 121 | `redirection` | reading | `>` emptying the file first, redirecting errors, both to one place, and why the order of `2>&1` matters |
| 122 | `pipes` | reading | Four processes running at the same time, `$?` after a pipeline, reduce first, and what a pipe is not |
| 123 | `looking-at-a-file` | reading | `head`, `tail`, `cat` and `less` — and the order to look in before processing anything |
| 124 | `grep` | reading | The six flags that cover almost everything, `-c` counting lines rather than matches, context, and the exit status being the point |
| 125 | `regular-expressions` | reading | The useful half: one character, how many, where, alternatives and groups — and the one that catches everybody |
| 126 | `cut` | reading | `-d` being one character and not a string, `-c` for fixed-width text, the header problem, and where `cut` stops being enough |
| 127 | `sort` | reading | Sorting by a field, `-u` and the thing it does not do, the locale that makes `sort` disagree with itself, and big files |
| 128 | `uniq` | reading | `-c` being the whole point, `-d` against `-u`, `-i` and `-f`, and the ordering trap in full |
| 129 | `counting` | reading | `wc -l` counting newlines, `-c` against `-m`, and counting things that are not lines |
| 130 | `tr` | reading | Characters rather than words: case, one for another, `-d` to delete, `-s` to squeeze runs |
| 131 | `sed` | reading | `s` and the separator being whatever you type, addresses, changing every line, and editing in place |
| 132 | `awk` | reading | The shape of a program, the built-in variables, arithmetic, and the associative array that replaces `sort | uniq -c` |
| 133 | `joining-files` | reading | `paste`, `join`, `comm`, `diff` and `split` |
| 134 | `xargs` | reading | Packing as many arguments as it can, `-I` for the one that is not last, the failure and the fix, and `find -exec` as the alternative |
| 135 | `a-real-question` | video | What is slow? Four commands and twenty seconds — **demonstration** |
| 136 | `closing` | video | Reduce first, sort before uniq, and know when to stop and write a script — **closing** |
| 137 | `drill` | practice | Predict the output, name the flag, say which tool the job wants |

**Lesson 9 · Bash scripting: variables, conditionals, loops and functions** — `le-82pt20zt`

| | slug | kind | covers |
|---|---|---|---|
| 138 | `intro` | video | The one-liner becomes a file with a name — **opening** |
| 139 | `a-file-with-a-name` | reading | The shebang, `/bin/sh` not being bash, running against sourcing, and where to put it |
| 140 | `variables` | reading | No spaces around the `=`, everything being a string, braces for where the name ends, and shell against environment variables |
| 141 | `quoting` | reading | What double quotes actually stop, the whitespace that goes with them, the empty variable that is the dangerous one, and the rule |
| 142 | `arguments` | reading | `"$@"` against `$@` against `"$*"`, `shift`, checking you were given something, and `$0` not being a name |
| 143 | `exit-status` | reading | `set -euo pipefail`, what each of the three does, and the four places `set -e` does nothing at all |
| 144 | `conditionals` | reading | `if` taking a command rather than a condition, `[` being a program, `&&` and `||`, and formatting |
| 145 | `comparing-things` | reading | Emptiness, quotes that are not advice here, `[[ ]]` being bash rather than a command, and regular expressions |
| 146 | `case` | reading | The option parser every script ends up with, and where it stops being enough |
| 147 | `loops` | reading | The list is usually a glob, the two glob surprises, ranges, `while` and `until` — and never looping over `ls` |
| 148 | `reading-input` | reading | `-r` for backslashes, `IFS=` for whitespace, the subshell that is the invisible one, and the missing last line |
| 149 | `arrays` | reading | `"${arr[@]}"` with the quotes, growing one, filling one from a glob, passing one to a command, and associative arrays |
| 150 | `functions` | reading | A function as a small script that shares your variables, `local`, returning a value, and what functions cannot do |
| 151 | `substitution` | reading | `$( )` and `$(( ))`, which look alike and are not related; stripped trailing newlines, and backticks |
| 152 | `parameter-expansion` | reading | Cutting paths apart without calling `basename`: extensions, defaults and requirements, replacing, length, slicing and case |
| 153 | `traps-and-temp-files` | reading | `mktemp`, the cleanup that does not happen, `trap`, the signals it catches, and `trap … ERR` for a message |
| 154 | `debugging` | reading | `bash -n` before you run it, `shellcheck` as the important one, `bash -x` when it runs but does the wrong thing, and `PS4` |
| 155 | `a-real-script` | video | Sixty lines, and every piece of it from this lesson — **demonstration** |
| 156 | `closing` | video | Quote everything, `set -euo pipefail`, run shellcheck — **closing** |
| 157 | `drill` | practice | Say what the script does, find the quoting bug, name the expansion |

**`quoting` and `exit-status` are the two sections that make the rest survive contact.**
Unquoted variables and a script that keeps going after a failed command are not stylistic
preferences: between them they are most of the shell scripts that have ever destroyed something.
`set -e` gets its own paragraph on where it does *not* fire, because taught as a magic line it
produces confidence without cover.

**Lesson 10 · An overview of PowerShell for Windows environments** — `le-3sfw2p12`

| | slug | kind | covers |
|---|---|---|---|
| 158 | `intro` | video | The pipeline carries objects, not text — **opening** |
| 159 | `objects-not-text` | reading | What that buys, what it costs, and where this lesson stands against the four before it |
| 160 | `verb-noun` | reading | Finding a command you do not know: `Get-Help`, named parameters that can be shortened, and a cross-platform surprise in the aliases |
| 161 | `the-pipeline` | reading | One object at a time rather than all at once, `$_`, the three different jobs `Select-Object` does, and where the objects come from |
| 162 | `filtering` | reading | `Where-Object`, operators that are words, which side the collection is on, and the comparison that quietly answers wrongly — measured |
| 163 | `sorting-and-grouping` | reading | `Sort-Object`, `Group-Object` and `Measure-Object` — `sort | uniq -c` with the sort built in, and why not `$x.Count` |
| 164 | `formatting` | reading | `Format-*` as the end of the pipeline and never the middle, asking for text when you want text, and `Write-Host` not being output |
| 165 | `variables-and-types` | reading | Conversion happening in the direction the left operand decides, strings, objects that are not strings that look like things, and the special variables |
| 166 | `collections` | reading | Arrays and hashtables, the count that is not there, and two more things worth knowing |
| 167 | `control-flow` | reading | `if`, `foreach` and `switch` — and `Set-StrictMode`, which is the one that turns a typo into an error |
| 168 | `functions` | reading | `param` being the difference, returning values, taking pipeline input, scope, and where functions live |
| 169 | `providers` | reading | The same cmdlets over the filesystem, the environment and — on Windows — the registry; and `Select-String` as `grep` |
| 170 | `errors` | reading | Two different kinds of failure: `try`/`catch`/`finally`, `throw`, and `$?` against `$LASTEXITCODE` |
| 171 | `talking-to-windows` | reading | The half of PowerShell this machine does not have: services, CIM and WMI, the registry, remoting, Active Directory |
| 172 | `a-rosetta-stone` | reading | Moving around, text and data, processes and shell constructs side by side — and the four rules that produce the table |
| 173 | `one-question` | video | The same log, the same answer, a different shape — **demonstration** |
| 174 | `closing` | video | Objects, the cast at the boundary, and four ways to look things up — **closing** |
| 175 | `drill` | practice | Translate the pipeline, name the cmdlet, say what the comparison returns |

## Volume V — Keeping it running

**Lesson 11 · Performance: CPU, memory, disk and I/O** — `le-pfg45b4t`

| | slug | kind | covers |
|---|---|---|---|
| 176 | `intro` | video | Four resources, and the numbers that mean something else — **opening** |
| 177 | `four-resources` | reading | Utilisation against saturation, errors as the third thing, and the one number that is not on the list |
| 178 | `load-average` | reading | What is being averaged, comparing it to the core count, the three numbers as a direction, and where it misleads badly |
| 179 | `cpu` | reading | Throwing the first line away, the seven columns that say where it went, per core, and `top` for one screen |
| 180 | `memory` | reading | The cache not being used memory, per process, `/proc/meminfo`, and when it really is memory |
| 181 | `swap` | reading | What swap is for, the columns, `swappiness`, no swap at all, and what to actually do about it |
| 182 | `out-of-memory` | reading | Exit 137 and the evidence in the log, which process gets chosen, preventing it, and what to do when you find one |
| 183 | `disk-space` | reading | Full with space free, full with the file deleted, finding the space, and three checks in order |
| 184 | `disk-io` | reading | The columns that matter, `%util` having stopped meaning saturation, reads against writes against flushes, and the write cliff |
| 185 | `which-process` | reading | `pidstat`, `/proc/PID/io`, `iotop` — and why this is the question you ask last |
| 186 | `network` | reading | What is listening and to whom, the two queues, errors and drops, and per-connection detail |
| 187 | `containers-lie` | reading | Why every tool in this lesson reads the host's number, what actually works, and the first question on a modern machine |
| 188 | `sampling-and-counters` | reading | Counters, rates and averages — the three ways a number lies, why the first line is wrong, and what to record before you need it |
| 189 | `a-method` | reading | Sixty seconds, the decision written out, four questions to ask first, and fixing the measurement before the machine |
| 190 | `an-investigation` | video | Load 1.39, and a disk at ninety three per cent — **demonstration** |
| 191 | `closing` | video | Compare load to cores, read available, read await — **closing** |
| 192 | `drill` | practice | Read the output, say what is saturated, name the next command |

**`oom` and `disk-space` are the two that get skipped and then cost a night.** A process that
vanished with no error in its own log, and `df` saying the disk is full while `du` says it is
not, are both events with one cause and no obvious place to look — the journal for the first,
a deleted file still held open for the second, which is why `file-descriptors` in lesson 6 is
where it is.

**Lesson 12 · Terminal editors: Vim, Nano and Emacs** — `le-p2b3v94d`

| | slug | kind | covers |
|---|---|---|---|
| 193 | `intro` | video | The joke about not being able to leave, taken seriously — **opening** |
| 194 | `why-a-terminal-editor` | reading | Five times you do not get to choose, what is actually on the machine, and what this lesson does about it |
| 195 | `nano` | reading | The ten commands that matter, searching, leaving, two flags worth knowing, and what nano cannot do |
| 196 | `vim-modes` | reading | The one idea: which modes you will use, how you know which one you are in, the six ways into insert, and `Esc` being far away |
| 197 | `vim-moving` | reading | Characters, words, lines, screens and the file; `f`, which changes how you move; and the two marks you get free |
| 198 | `vim-editing` | reading | Operators and motions as a grammar, text objects as the other half, and yank and put |
| 199 | `vim-search-and-replace` | reading | Searching that wraps and says so, patterns being regular expressions, case, and substitute — `sed` with a view |
| 200 | `vim-files` | reading | Writing and quitting, `:w` telling you what it wrote, new files, when you cannot write, and several files at once |
| 201 | `vim-config` | reading | Ten lines worth having and where they go, `:set` at runtime, two things that are not configuration, and the plugin question |
| 202 | `vim-survival` | reading | The four commands, and the four screens that stop you — including the swap file and the one that is the terminal rather than vim |
| 203 | `emacs` | reading | No modes and a different idea instead: the minimum, leaving, what it is actually for, and where it leaves you |
| 204 | `which-one` | reading | The three side by side, and an answer that is not a personality: two reasons for vim that are not aesthetic, two for nano that are not laziness |
| 205 | `the-editor-you-get` | reading | `$EDITOR` and `$VISUAL`, what happens when neither is set, `visudo` and `sudoedit`, and the chain in full |
| 206 | `remote-editing` | reading | Four ways to edit a file on another machine, and which to use |
| 207 | `a-first-edit` | video | Open, find, change, write, leave — **demonstration** |
| 208 | `closing` | video | Nano is an answer, and four vim commands are not optional — **closing** |
| 209 | `drill` | practice | Name the keystroke, escape the screen, say which editor the situation leaves you |

**`the-editor-you-get` is the section this lesson exists for.** A student who never
chooses an editor will still be dropped into one by `crontab -e` or `visudo` — and `visudo` in
particular is a program you cannot safely abandon halfway, on a file that can lock you out of
your own machine.

**Lesson 13 · Scheduling tasks: cron and systemd timers** — `le-0xex3wqd`

| | slug | kind | covers |
|---|---|---|---|
| 210 | `intro` | video | Something has to happen at three in the morning and you will not be there — **opening** |
| 211 | `what-runs-things-later` | reading | Five things that run something later, the one you should not write, and which of them is on this machine |
| 212 | `crontab` | reading | `crontab -e` and the editor you did not choose, `-r` sitting next to `-e`, and where it actually lives |
| 213 | `the-five-fields` | reading | The five fields read until they are obvious, the rule that is an OR and surprises everybody, and the shortcuts |
| 214 | `where-cron-lives` | reading | Six places a job can be — `/etc/crontab`, `/etc/cron.d`, the `run-parts` directories — and which one to use |
| 215 | `the-environment` | reading | What cron actually gives you, three fixes in order of how well they work, testing it the way cron will run it, and the percent sign that is not one |
| 216 | `output-and-failure` | reading | The line that hides everything, `MAILTO`, how to know it ran, and the failure nobody catches |
| 217 | `time-zones-and-dst` | reading | Whose three in the morning, `CRON_TZ` failing silently, the two nights a year it goes wrong, and what to do |
| 218 | `anacron-and-at` | reading | The machine that was off, how anacron fits with cron, and `at` for the job that runs once |
| 219 | `systemd-timers` | reading | A timer is two files and one of them you already know: the service, the timer, installing one, and checking it first |
| 220 | `oncalendar` | reading | `systemd-analyze calendar`, the syntax and its shorthands, both day fields differing from cron, and what it does when the answer is nothing |
| 221 | `monotonic-and-persistent` | reading | Counting from an event rather than a clock, `Persistent=true` for the one that catches up, and `RandomizedDelaySec=` |
| 222 | `listing-and-debugging` | reading | Everything scheduled on this machine, `systemctl list-timers`, did it run, and a checklist for when it did not |
| 223 | `overlap-and-locking` | reading | The job still running when the next one starts: `flock`, the exit status that is the trap, why not a PID file, and what systemd gets free |
| 224 | `cron-or-timer` | reading | The two side by side, the answer for the machine you are actually on, when to break that rule, and the third answer |
| 225 | `a-job-that-survives` | reading | Nine things a scheduled job needs whatever started it, the shape they take, and the rule underneath all nine |
| 226 | `a-real-job` | video | One job, scheduled, and watched until it ran — **demonstration** |
| 227 | `closing` | video | Five fields, two files, and the nine things the job still needs — **closing** |
| 228 | `drill` | practice | Read the schedule, say when it fires, name what the job is missing |

**`output-and-failure` and `listing-and-debugging` close the course**, and it is the one a syllabus never has room for. A
scheduled job's failure mode is silence: it does not error where anybody is looking, and the
first sign is the thing it was supposed to produce not existing. Naming the pattern — a job that
reports success somewhere, and an alert when the report stops — is what separates a student who
can write a cron line from one who can be trusted with it.

---

## Exercises

| where | how many |
|---|---|
| in each of the 175 reading sections | 4–6 |
| in each of the 13 practice sections, all `drillable` | 12–16 |
| **counted after the course was written** | **949** |

**About a fifth of them want to be `expected-output`** — here is a command, say what it prints —
and that type has no grader. `EXECUTOR.md` settles what happens: the question is asked, the
answer is recorded, and the verdict is `correct: null`, which the interface already renders as
*not checked*. The alternative is to write those two hundred questions as `multiple-choice`
instead, which teaches recognising an output rather than predicting one, and this sheet declines
to do that for the whole fifth. **A mix:** the ones where recognition is genuinely the skill —
reading `ls -l`, reading `systemctl status`, reading `top` — stay multiple-choice, because
reading IS the task. The ones where the student should be able to produce the answer stay
`expected-output` and wait for the executor.

## What C-37 cost this sheet, counted once

There was no earlier design to compare against: this sheet went from a budget to 223 sections in
one pass, and the writing came out at 228. So the count below is of sections that a design working to ~150 would not have
written — each checked by asking what a student would not know at the end of the course without
it, rather than whether the lesson felt full.

| added | lesson | what would have been missing |
|---|---|---|
| `getting-a-linux` | 1 | a machine to practise on — the course's own precondition |
| `terminal-keys` | 1 | Tab, history and `Ctrl+C`; the difference between fluent and typing every path |
| `line-endings` | 1 | an error message naming a character you cannot see |
| `the-manual` | 1 | how to answer a question this course did not cover |
| `alpine-and-containers` | 2 | the distribution its students meet first, through `docker` |
| `lifecycles` | 2 | that a version stops getting security updates on a date somebody chose |
| `links` | 3 | symlinks, and the broken one |
| `disk-usage` | 3 | `du`, separately from `df`, because they disagree |
| `directory-bits` | 4 | `x` on a directory — the readable directory you cannot enter |
| `special-bits` | 4 | setuid and the sticky bit; why `/tmp` is not a hole |
| `sudo-in-practice` | 4 | the redirect that fails under sudo, which is the first sudo mistake |
| `ssh` | 5 | reaching any machine that is not the one in front of you |
| `journalctl` | 5 | where a failed service actually says why |
| `file-descriptors` | 6 | the deleted file still holding the disk, and `lsof` |
| `exit-status` | 6 | `$?`, without which lesson 9's `&&` is a superstition |
| `surviving-the-hangup` | 6 | the SSH session that drops and takes the job with it |
| `outside-the-distribution` | 7 | Snap, Flatpak, PPAs and the piped installer, ranked by risk |
| `finding-things` | 7 | "what installed this file?" |
| `xargs` | 8 | the join between `find` and everything else, and `-print0` |
| `joining-files` | 8 | reading a unified diff, which is also every code review they will see |
| `quoting` | 9 | the space in a filename, and most of the shell bugs ever written |
| `exit-status` | 9 | a script that keeps going after a command failed |
| `debugging` | 9 | `bash -x` and `shellcheck` |
| `swap` | 11 | the difference between using swap and thrashing |
| `out-of-memory` | 11 | the process that vanished with nothing in its own log |
| `disk-space` | 11 | `df` full and `du` empty, which has one cause and no obvious place to look |
| `containers-lie` | 11 | the container that is slower than its host |
| `a-method` | 11 | a checklist that ends at a cause |
| `the-editor-you-get` | 12 | `visudo`, which can lock you out of your own machine |
| `the-environment` | 13 | the environment cron does not give you — why it worked by hand |
| `overlap-and-locking` | 13 | the job that overlaps itself |
| `output-and-failure` | 13 | that a scheduled job fails silently |

**SIX OF THE THIRTY-EIGHT NEVER BECAME A SECTION.** `updates-and-reboots` (7), `beyond-lines`
(8), `when-not-to` (9), `execution-policy` and `both-at-once` (10) and `not-opening-an-editor`
(12) were argued for here and are not in the written course. Five of them have their material
somewhere — `sed -i` is in lesson 8's `sed`, the execution policy is a paragraph inside lesson
10's `functions` — and `both-at-once`, the machine running bash and PowerShell side by side, is
absent entirely. They are listed here rather than quietly dropped, because the argument for each
was made and the writing did not answer it; whether to answer it is a content decision and not a
design one.

**Thirty-two sections, and every one of them is a thing that happens rather than a thing that
is true.** That is the pattern: a budget derived from hours buys the subject's nouns, and what it
leaves out is the behaviour — the failure, the surprise, the flag you need at the moment the
ordinary path stops working. Which is exactly the material a beginner cannot get anywhere else,
because it is what nobody writes down.

## What it does not cover, on purpose

| left out | whose it is | why it is not here |
|---|---|---|
| Docker, images, compose | `docker` | This course gives the filesystem, processes and permissions a container is made of. Building one is the course that depends on this. |
| Network configuration, firewalls, `iptables`/`nftables` | `networks`, `security` | Lesson 11 names `ss` and `ip` for diagnosis. Configuring an interface or writing a rule set is running a network. |
| `nginx`, Apache, reverse proxies | `servers-cache` | Lesson 5 teaches managing a service. Which service, and how to configure it, is the course downstream. |
| Databases, backups of them | `db-administration` | Same shape: the system underneath, here; the thing running on it, there. |
| Ansible, Terraform, configuration management | `devops`, `iac` | They exist to stop you doing this by hand. You have to be able to do it by hand first. |
| LVM, RAID, filesystem tuning, partitioning | `dba`, `networks-infra` material | Lesson 3 mounts a disk and reads `lsblk`. Laying one out is a specialism, and one with real consequences for getting it wrong. |
| Kernel internals, modules, compiling a kernel | nobody, yet | Interesting and not load-bearing. A beginner needs `systemctl` far more than `modprobe`. |
| SELinux and AppArmor policy | `security` | Named in lessons 2 and 4 so a student recognises a denial that is not a permission bit. Writing policy is a different job. |
| Git | `git` | Its own course, in thirteen tracks, and not a prerequisite in either direction. |
| `tmux` and `screen` in depth | — | Named in lesson 6 for the dropped session. The full multiplexer is a tool to adopt, not a subject. |
| zsh, fish, and bash's exotic corners | — | Lesson 1 says which shell you are in and lesson 9 writes portable-ish bash. Arrays are where this sheet stops, and `when-not-to` says so out loud. |
| PowerShell beyond an overview | — | The lesson's own title is "an overview", and its eleven readings honour it: the model, the pipeline, enough to be useful in a mixed shop. |

Every one of these is reachable from at least one track that starts here, and none is needed for
what lesson 13 asks: to schedule a job you wrote yourself and know whether it ran.

## Flags

**1 ·** **Free, and the second-widest reach in the catalogue.** Ten tracks, position 1 in `devsecops`, four dependents. Only `git` (13) and `web-fundamentals` (12) reach further, and neither of those is free *and* a prerequisite of this much.

**2 ·** **It is the strongest argument for shell as the sandbox's first runtime, ahead of `git`.** `git` would be improved by a shell; this course *is* a shell. And it is free, so the argument is about conversion rather than retention.

**3 ·** **228 sections against a budget of ~150, and the budget was the thing that was wrong.** The only measured density in the repository puts 70 hours at 164, and this sheet's sections are shorter than that one's because a command can be taught and then run. The declared hours do not move; see *What a section is worth here*.

**4 ·** **About a fifth of the exercises want a type that has no grader.** They are written anyway and answered `correct: null` — `EXECUTOR.md` is why that is a degradation and not a hole. It is also the clearest volume argument for building the executor that exists in the catalogue.
