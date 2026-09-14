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
| section budget | ~150, about 11.5 a lesson — **and 223 are designed**; the arithmetic is below |
| sections | **223** — 170 reading, 40 video, 13 practice |
| exercises | ~890, floor 700 |
| video | estimated, not a target (`C-36`) |
| avatar visible | **~15%** of video runtime, and only in the opening and the closing — the reason is below |

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
with the portal and do not move.** The numbering 01–223 is the path a student walks, in the
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

### What a section is worth here, and why there are 223 of them

The budget of ~150 came from declared hours at the catalogue's average density. Two numbers
argue it is low.

**The measured precedent.** `web-fundamentals` is the only other designed sheet: 94 sections for
40 declared hours, or 2.35 sections an hour. At that density 70 hours is **164 sections**, not
150 — so the budget was already under the only figure anybody has actually designed against.

**And this course's sections are shorter.** 223 sections in 70 hours is under 19 minutes each,
against `web-fundamentals`' 25.5. That difference is real and it is not padding: a section there
establishes a concept that took five paragraphs to build, and a section here is frequently one
command, its three or four flags that matter, the output it prints, and five questions. `grep`
is not a smaller subject than the CSSOM; it is a subject that reaches the student in less time,
because they can run it. The average also understates the readings, because 26 of the 223 are an
opening or a closing and those are ninety seconds apiece.

**The declared hours do not move** — they are on the course card and in the portal — so of the
two ways to absorb 223 sections, this sheet takes the one that does not change the contract.
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
| 103 | `intro` | video | Software you do not download — **opening** |
| 104 | `why-a-package-manager` | reading | The installer that does not exist, and the trust that replaces it |
| 105 | `anatomy-of-a-package` | reading | Files, metadata, dependencies and the scripts that run on install |
| 106 | `repositories` | reading | What a repository is, mirrors, and the signature that makes any of it safe |
| 107 | `apt` | reading | `update`, `upgrade`, `install`, `remove`, `purge`, `search`, `show` — and update not being upgrade |
| 108 | `dnf-yum` | reading | The same verbs in the Red Hat family, plus groups and `history undo` |
| 109 | `zypper` | reading | SUSE's, and `zypper patch`, which is not quite upgrade |
| 110 | `dependencies` | reading | Resolution, conflicts, and what "held back" is telling you |
| 111 | `low-level` | reading | `dpkg` and `rpm` underneath, and the times you have to go there |
| 112 | `versions-and-pinning` | reading | Which version you actually get, pinning, and downgrading |
| 113 | `outside-the-repository` | reading | Third-party repos, PPAs, loose `.deb`/`.rpm`, Snap, Flatpak, AppImage — in order of risk |
| 114 | `building-from-source` | reading | `./configure && make && make install`, and why it is the last option and not the first |
| 115 | `updates-and-reboots` | reading | Security updates, unattended upgrades, and the kernel update that does need one |
| 116 | `where-did-this-come-from` | reading | `dpkg -S`, `rpm -qf`, `apt-file`: answering "what installed this file?" |
| 117 | `installing-something` | video | One tool installed on three distributions — **demonstration** |
| 118 | `closing` | video | Trust, versions, and the moment you decide to step outside the repository anyway — **closing** |
| 119 | `drill` | practice | Choose the command, read the failure, decide the source |

**`outside-the-repository` is the section that keeps the lesson honest.** Everything before it
describes a system where software is signed, versioned and removable; the student's actual next
step is a README telling them to pipe a URL into a shell. Naming the three packaging systems and
ranking the options by risk is the difference between a rule they will break silently and a
judgement they can make.

## Volume IV — Text, pipes and scripts

**Lesson 8 · Text: grep, sed, awk, cut, sort, uniq, pipes and redirection** — `le-k41k9p1e`

| | slug | kind | covers |
|---|---|---|---|
| 120 | `intro` | video | Small programs, one job each, and a pipe between them — **opening** |
| 121 | `text-is-the-interface` | reading | Why everything speaks lines, and what that buys you |
| 122 | `stdin-stdout-stderr` | reading | Three streams, and the one that does not go down the pipe |
| 123 | `redirection` | reading | `>`, `>>`, `<`, `2>`, `2>&1`, `&>` and `/dev/null` |
| 124 | `pipes` | reading | `\|`, and the filter as a shape you will use for the rest of your career |
| 125 | `grep` | reading | `-i`, `-v`, `-r`, `-n`, `-c`, `-l`, `-w`, `-A`/`-B`/`-C` |
| 126 | `regex-basics` | reading | Anchors, classes, quantifiers, groups — and where `grep -E` changes the rules |
| 127 | `cut-and-columns` | reading | `cut`, `paste`, `column`, and the delimiter that is not a space |
| 128 | `sort` | reading | `-n`, `-r`, `-k`, `-u`, `-t`, and the locale that changes the answer |
| 129 | `uniq` | reading | Why it needs sorted input, and `sort \| uniq -c \| sort -rn` as the idiom to keep |
| 130 | `small-filters` | reading | `tr`, `rev`, `fold`, `nl`, `tee` |
| 131 | `sed` | reading | Substitution, addresses, delete and print, `-i` and the backup it should be making |
| 132 | `awk` | reading | Records and fields, patterns and actions, `BEGIN`/`END`, `NR` and `NF` |
| 133 | `awk-further` | reading | Variables, arithmetic, and the one-line report |
| 134 | `xargs` | reading | Turning a list into arguments; `-n`, `-I`, `-0`, and `find -print0` |
| 135 | `diff-and-patch` | reading | Comparing two files, and reading a unified diff — which is also every code review |
| 136 | `beyond-lines` | reading | Where lines stop being enough: `jq` for JSON, and CSV's quoting |
| 137 | `a-log-file` | video | A real question answered from a real log, in one pipeline — **demonstration** |
| 138 | `closing` | video | Why the pipeline is the skill, rather than any one of the commands in it — **closing** |
| 139 | `drill` | practice | Predict the output; build the pipeline |

**Lesson 9 · Bash scripting: variables, conditionals, loops and functions** — `le-82pt20zt`

| | slug | kind | covers |
|---|---|---|---|
| 140 | `intro` | video | The commands you already know, in a file — **opening** |
| 141 | `a-script-is-a-file` | reading | Shebang, `chmod +x`, PATH, and `./script` against `bash script` |
| 142 | `variables` | reading | Assignment with no spaces, `$VAR` against `${VAR}`, and why you quote |
| 143 | `quoting` | reading | Single, double, backslash — and the space in a filename that breaks everything |
| 144 | `expansion` | reading | `$(…)`, `$((…))`, `${VAR:-default}`, and the order the shell does it in |
| 145 | `arguments` | reading | `$1`, `$@`, `$#`, `shift`, and `"$@"` against `$@` |
| 146 | `environment` | reading | Environment against shell variables, `export`, `env`, and PATH itself |
| 147 | `conditionals` | reading | `if`, `test`, `[ ]`, `[[ ]]`, string and numeric comparison, file tests |
| 148 | `chaining` | reading | `&&`, `\|\|`, `!`, and the exit status they are reading |
| 149 | `loops` | reading | `for`, `while`, `until`, `read`, and looping over lines without losing them |
| 150 | `case` | reading | `case`, and the argument parser it makes |
| 151 | `functions` | reading | Defining, arguments, `return` against output, and `local` |
| 152 | `arrays` | reading | Indexed arrays, `${arr[@]}`, and where bash stops being the right tool |
| 153 | `input-output` | reading | `read`, heredocs, and prompting without being lied to |
| 154 | `errors-and-traps` | reading | `set -euo pipefail` one flag at a time, `trap`, and cleaning up on exit |
| 155 | `debugging` | reading | `bash -x`, `shellcheck`, and the three bugs everybody writes |
| 156 | `when-not-to` | reading | The point at which a shell script should have been a program |
| 157 | `a-real-script` | video | A backup script written from nothing, including the bugs — **demonstration** |
| 158 | `closing` | video | When a script is the right answer, and the line past which it stops being one — **closing** |
| 159 | `drill` | practice | Read a script and say what it does; fix one that is wrong |

**`quoting` and `errors-and-traps` are the two sections that make the rest survive contact.**
Unquoted variables and a script that keeps going after a failed command are not stylistic
preferences: between them they are most of the shell scripts that have ever destroyed something.
`set -e` gets its own paragraph on where it does *not* fire, because taught as a magic line it
produces confidence without cover.

**Lesson 10 · An overview of PowerShell for Windows environments** — `le-3sfw2p12`

| | slug | kind | covers |
|---|---|---|---|
| 160 | `intro` | video | A shell that pipes objects — **opening** |
| 161 | `objects-not-text` | reading | The one difference every other difference follows from |
| 162 | `cmdlets` | reading | Verb-noun, and discoverability as a design decision |
| 163 | `the-pipeline` | reading | Piping objects: `Select-Object`, `Where-Object`, `ForEach-Object`, `Sort-Object` |
| 164 | `equivalents` | reading | The table — `ls`/`Get-ChildItem`, `cat`/`Get-Content`, `grep`/`Select-String` — and the aliases that mislead you |
| 165 | `help-system` | reading | `Get-Help`, `Get-Command`, `Get-Member`: finding out without leaving the shell |
| 166 | `providers` | reading | The filesystem, the registry and the certificate store, all as drives |
| 167 | `scripting` | reading | Variables, `if`, `foreach`, functions, `.ps1` |
| 168 | `execution-policy` | reading | Why your script will not run, and what the policy is and is not for |
| 169 | `remoting` | reading | `Enter-PSSession`, `Invoke-Command`, and WinRM against SSH |
| 170 | `powershell-on-linux` | reading | PowerShell 7 is cross-platform; when that is the right answer |
| 171 | `both-at-once` | reading | WSL in both directions, paths across the boundary, and line endings for the second time |
| 172 | `a-comparison` | video | One task, done twice — **demonstration** |
| 173 | `closing` | video | What crossing between two shells actually asks of you, and what it does not — **closing** |
| 174 | `drill` | practice | Translate between the two shells; predict what the pipeline carries |

## Volume V — Keeping it running

**Lesson 11 · Performance: CPU, memory, disk and I/O** — `le-pfg45b4t`

| | slug | kind | covers |
|---|---|---|---|
| 175 | `intro` | video | "It is slow" is not a diagnosis — **opening** |
| 176 | `what-slow-means` | reading | Four resources and a method: measure before you believe anybody, including yourself |
| 177 | `load-average` | reading | The three numbers, what Linux counts in them, and reading them per core |
| 178 | `cpu` | reading | `top`'s CPU line: user, system, nice, iowait — and steal, which means it is not your machine |
| 179 | `memory` | reading | `free -h`, and why "used" is not what you think: cache is not waste |
| 180 | `swap` | reading | Swappiness, and the difference between using swap and thrashing |
| 181 | `oom` | reading | The OOM killer, how to find out it fired, and what it chose |
| 182 | `disk-space` | reading | `df` against `du`, inodes, and the full disk with nothing on it |
| 183 | `disk-io` | reading | `iostat`, `iotop`, await and utilisation |
| 184 | `network-quickly` | reading | `ss`, `ip`, `ping`, and the port that is already in use |
| 185 | `per-process` | reading | Attributing it to something: `pidstat`, `/proc/<pid>` |
| 186 | `tracing` | reading | `strace` and `lsof` as two questions — what is it calling, and what is it holding |
| 187 | `limits` | reading | `ulimit`, cgroups named, and the container that is slower than its host |
| 188 | `a-method` | reading | A checklist that ends at a cause rather than at a graph |
| 189 | `a-slow-machine` | video | One real diagnosis, from complaint to cause — **demonstration** |
| 190 | `closing` | video | A method you can repeat, and the honesty it needs about what you actually measured — **closing** |
| 191 | `drill` | practice | Given four numbers, say which resource is the problem |

**`oom` and `disk-space` are the two that get skipped and then cost a night.** A process that
vanished with no error in its own log, and `df` saying the disk is full while `du` says it is
not, are both events with one cause and no obvious place to look — the journal for the first,
a deleted file still held open for the second, which is why `file-descriptors` in lesson 6 is
where it is.

**Lesson 12 · Terminal editors: Vim, Nano and Emacs** — `le-p2b3v94d`

| | slug | kind | covers |
|---|---|---|---|
| 192 | `intro` | video | The machine with no desktop and the file you have to fix — **opening** |
| 193 | `why-a-terminal-editor` | reading | Editing over SSH, in a container, on a server that is not booting |
| 194 | `nano` | reading | Open, edit, save, exit, and the bottom bar that tells you how |
| 195 | `vim-modes` | reading | Normal, insert, visual, command — the idea before a single key |
| 196 | `vim-survival` | reading | Ten commands that are enough, starting with how to leave |
| 197 | `vim-moving` | reading | Words, lines, screens, `gg` and `G`, search |
| 198 | `vim-editing` | reading | Operators and motions, `dd`, `yy`, `p`, `u`, and `.` |
| 199 | `vim-files` | reading | `:w`, `:q`, `:wq`, `:q!`, `:e`; buffers and splits, briefly |
| 200 | `vim-config` | reading | `.vimrc`, and three settings actually worth having |
| 201 | `emacs` | reading | The other one: buffers, `C-x C-s`, and why people choose it |
| 202 | `which-one` | reading | Choosing — and that `vi` is the one guaranteed to be on the machine |
| 203 | `editors-other-commands-open` | reading | `EDITOR`, `visudo`, `systemctl edit`, `crontab -e`: the editor you did not choose |
| 204 | `not-opening-an-editor` | reading | When `sed -i`, `tee` or a heredoc is the right answer instead |
| 205 | `a-config-fix` | video | A real config edited over SSH and the service restarted — **demonstration** |
| 206 | `closing` | video | Enough of an editor never to be stuck, and permission to learn the rest slowly — **closing** |
| 207 | `drill` | practice | Say what a key sequence does; get out of a mode |

**`editors-other-commands-open` is the section this lesson exists for.** A student who never
chooses an editor will still be dropped into one by `crontab -e` or `visudo` — and `visudo` in
particular is a program you cannot safely abandon halfway, on a file that can lock you out of
your own machine.

**Lesson 13 · Scheduling tasks: cron and systemd timers** — `le-0xex3wqd`

| | slug | kind | covers |
|---|---|---|---|
| 208 | `intro` | video | The work nobody should have to remember — **opening** |
| 209 | `why-schedule` | reading | Backups, rotation, cleanup, reports: what a machine does when you are asleep |
| 210 | `crontab` | reading | `crontab -e`, `-l`, `-r`; user crontabs against `/etc/crontab` and `cron.d` |
| 211 | `the-five-fields` | reading | Minute, hour, day, month, weekday; ranges, lists and steps |
| 212 | `cron-gotchas` | reading | The environment cron does not give you, PATH, the bare `%`, and the relative path that worked by hand |
| 213 | `cron-output` | reading | Where output goes, MAILTO, and redirecting to a log on purpose |
| 214 | `anacron-and-at` | reading | `cron.daily` and friends, anacron for a machine that is off, `at` for once |
| 215 | `systemd-timers` | reading | The pair: a service unit, and a timer that starts it |
| 216 | `oncalendar` | reading | `OnCalendar`, `OnBootSec`, and `systemd-analyze calendar` to check before you wait a day |
| 217 | `timer-advantages` | reading | `Persistent`, randomised delay, logs in the journal, dependencies on other units |
| 218 | `cron-or-timer` | reading | Choosing — and why a container usually has neither |
| 219 | `idempotence-and-locking` | reading | The job that must not run twice, and `flock` |
| 220 | `monitoring-jobs` | reading | Finding out a job stopped running, before the backup you needed was not there |
| 221 | `a-scheduled-backup` | video | Lesson 9's script, scheduled both ways, and made to fail on purpose — **demonstration** |
| 222 | `closing` | video | The last section of the course: what to do in the first week you are responsible for a machine — **closing** |
| 223 | `drill` | practice | Read a cron line; convert it to a timer; find the mistake |

**`monitoring-jobs` closes the course**, and it is the one a syllabus never has room for. A
scheduled job's failure mode is silence: it does not error where anybody is looking, and the
first sign is the thing it was supposed to produce not existing. Naming the pattern — a job that
reports success somewhere, and an alert when the report stops — is what separates a student who
can write a cron line from one who can be trusted with it.

---

## Exercises

| where | how many |
|---|---|
| in each of the 170 reading sections | 4–6 → ~710 |
| in each of the 13 practice sections, all `drillable` | 12–16 → ~180 |
| total proposed | ~890 |
| floor, below which it is not published | 700 |

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
one pass. So the count below is of sections that a design working to ~150 would not have
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
| `outside-the-repository` | 7 | Snap, Flatpak, PPAs and the piped installer, ranked by risk |
| `where-did-this-come-from` | 7 | "what installed this file?" |
| `updates-and-reboots` | 7 | which updates need one, which do not |
| `xargs` | 8 | the join between `find` and everything else, and `-print0` |
| `diff-and-patch` | 8 | reading a unified diff, which is also every code review they will see |
| `beyond-lines` | 8 | that JSON and CSV break the line-based tools, and what to reach for |
| `quoting` | 9 | the space in a filename, and most of the shell bugs ever written |
| `errors-and-traps` | 9 | a script that keeps going after a command failed |
| `debugging` | 9 | `bash -x` and `shellcheck` |
| `when-not-to` | 9 | the point where this is the wrong tool |
| `execution-policy` | 10 | the single most common reason a PowerShell script does not run |
| `both-at-once` | 10 | the boundary these students actually live on |
| `swap` | 11 | the difference between using swap and thrashing |
| `oom` | 11 | the process that vanished with nothing in its own log |
| `disk-space` | 11 | `df` full and `du` empty, which has one cause and no obvious place to look |
| `limits` | 11 | the container that is slower than its host |
| `a-method` | 11 | a checklist that ends at a cause |
| `editors-other-commands-open` | 12 | `visudo`, which can lock you out of your own machine |
| `not-opening-an-editor` | 12 | that the answer is often `sed -i` |
| `cron-gotchas` | 13 | the environment cron does not give you — why it worked by hand |
| `idempotence-and-locking` | 13 | the job that overlaps itself |
| `monitoring-jobs` | 13 | that a scheduled job fails silently |

**Thirty-eight sections, and every one of them is a thing that happens rather than a thing that
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

**3 ·** **223 sections against a budget of ~150, and the budget was the thing that was wrong.** The only measured density in the repository puts 70 hours at 164, and this sheet's sections are shorter than that one's because a command can be taught and then run. The declared hours do not move; see *What a section is worth here*.

**4 ·** **About a fifth of the exercises want a type that has no grader.** They are written anyway and answered `correct: null` — `EXECUTOR.md` is why that is a degradation and not a hole. It is also the clearest volume argument for building the executor that exists in the catalogue.
