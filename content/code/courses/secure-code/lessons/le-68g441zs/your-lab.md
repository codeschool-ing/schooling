---
title: Your lab, built once
version: 1
---

**The platform gives you no machine for this course. You build the lab yourself, once, here**, and
every later lesson adds one folder to it. It is small: Python 3.10 or later, git, two Python
packages, a terminal and a web browser. No database server, no container, no account anywhere.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l01-workspace\" aria-label=\"The workspace this course builds. A folder called sc in your home directory holds a Python virtual environment, .venv, with Flask 3.1.3 and pytest 9.1.1 installed in it, and one folder per lesson. Each lesson folder is a git repository of its own with an app.py and a test_app.py. Lesson 1's folder is cancel.\"><defs><marker id=\"l01-workspace-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"30\" y=\"100\" width=\"140\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"100.0\" y=\"122.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">~/sc</text><rect x=\"240\" y=\"20\" width=\"450\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"256\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">.venv</text><text x=\"256\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Flask 3.1.3 and pytest 9.1.1, pinned</text><rect x=\"240\" y=\"100\" width=\"450\" height=\"130\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"256\" y=\"120\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">cancel/</text><text x=\"256\" y=\"142\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">app.py   test_app.py   .git/</text><text x=\"256\" y=\"172\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">one folder per lesson, each a git repository</text><text x=\"256\" y=\"204\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">… and one more per lesson</text><path d=\"M170 116 L205 116 L205 50 L240 50\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l01-workspace-ah-paper-dim)\"></path><path d=\"M170 128 L240 128\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l01-workspace-ah-paper-dim)\"></path></svg>", "caption": "One environment shared by every lesson, and one small application per lesson that you can break and reset."}
```

### Choose where it runs

| path | what you need | what it costs your computer |
|---|---|---|
| **on your own computer (recommended)** | Linux or macOS as it is; on Windows, WSL with Ubuntu | almost nothing: a folder of about 35 MB |
| in a virtual machine | VirtualBox, UTM or Hyper-V, and an Ubuntu 24.04 image | 2 GB of memory while it runs, 10 GB of disk |
| online | a cloud development environment, such as GitHub Codespaces or Gitpod, on an empty repository | nothing locally; it runs on somebody else's computer, under their free allowance or your payment |

**The first path is recommended** because nothing in this course needs isolating from your
computer. The flawed applications are yours, they are small, and they listen only on `127.0.0.1`,
which nothing outside your machine can reach. There is no malware and nothing to download beyond
two well-known packages.

The virtual machine is for a computer managed by an employer that forbids installing software, or
for anybody who prefers to keep course work in a box they can delete. The online path works from a
borrowed computer. **Keep its forwarded ports private**: an online environment can publish a port
to the internet with one click, and a deliberately flawed application must never be one of them.
Free allowances change with the vendor's terms, so check the current one before you rely on it.

The transcripts in this course were recorded on Ubuntu 24.04, as a user called `ana` on a machine
called `vm`. On Ubuntu or Debian the system packages come first:

```sh
sudo apt install python3 python3-venv git curl
```

That command was not run in the recording: the machine already had all four. On macOS, `git` and
`curl` arrive with the command line tools (`xcode-select --install`) and Python 3 from python.org
or Homebrew. Any current Firefox, Chrome or Edge serves as the browser; lessons 7 to 9 use its
developer tools.

### Build it

Check the two versions first. Flask 3.1 needs Python 3.9 or later and this course uses features of
3.10; Ubuntu 24.04 ships 3.12, and the recording machine had 3.13.

```
ana@vm:~$ python3 --version
Python 3.13.16
ana@vm:~$ git --version
git version 2.43.0
```

Make a folder for the course and a **virtual environment** inside it, so Flask, pytest and
everything later lessons add live in `~/sc/.venv` and nowhere else on the system. Activating it
changes the prompt, which is how you can tell later whether it is active:

```
ana@vm:~$ mkdir sc
ana@vm:~$ cd sc
ana@vm:~/sc$ python3 -m venv .venv
ana@vm:~/sc$ . .venv/bin/activate
(.venv) ana@vm:~/sc$ pip install --progress-bar off flask==3.1.3 pytest==9.1.1
Collecting flask==3.1.3
  Downloading flask-3.1.3-py3-none-any.whl.metadata (3.2 kB)
Collecting pytest==9.1.1
  Downloading pytest-9.1.1-py3-none-any.whl.metadata (7.6 kB)
Collecting blinker>=1.9.0 (from flask==3.1.3)
  Downloading blinker-1.9.0-py3-none-any.whl.metadata (1.6 kB)
Collecting click>=8.1.3 (from flask==3.1.3)
  Downloading click-8.5.0-py3-none-any.whl.metadata (2.6 kB)
Collecting itsdangerous>=2.2.0 (from flask==3.1.3)
  Downloading itsdangerous-2.2.0-py3-none-any.whl.metadata (1.9 kB)
Collecting jinja2>=3.1.2 (from flask==3.1.3)
  Downloading jinja2-3.1.6-py3-none-any.whl.metadata (2.9 kB)
Collecting markupsafe>=2.1.1 (from flask==3.1.3)
  Downloading markupsafe-3.0.4-cp313-cp313-manylinux2014_x86_64.manylinux_2_17_x86_64.manylinux_2_28_x86_64.whl.metadata (2.7 kB)
Collecting werkzeug>=3.1.0 (from flask==3.1.3)
  Downloading werkzeug-3.1.9-py3-none-any.whl.metadata (4.1 kB)
Collecting iniconfig>=1.0.1 (from pytest==9.1.1)
  Downloading iniconfig-2.3.1-py3-none-any.whl.metadata (2.8 kB)
Collecting packaging>=22 (from pytest==9.1.1)
  Downloading packaging-26.3-py3-none-any.whl.metadata (3.5 kB)
Collecting pluggy<2,>=1.5 (from pytest==9.1.1)
  Downloading pluggy-1.7.0-py3-none-any.whl.metadata (5.0 kB)
Collecting pygments>=2.7.2 (from pytest==9.1.1)
  Downloading pygments-2.21.0-py3-none-any.whl.metadata (2.5 kB)
Downloading flask-3.1.3-py3-none-any.whl (103 kB)
Downloading pytest-9.1.1-py3-none-any.whl (386 kB)
Downloading pluggy-1.7.0-py3-none-any.whl (27 kB)
Downloading blinker-1.9.0-py3-none-any.whl (8.5 kB)
Downloading click-8.5.0-py3-none-any.whl (125 kB)
Downloading iniconfig-2.3.1-py3-none-any.whl (7.6 kB)
Downloading itsdangerous-2.2.0-py3-none-any.whl (16 kB)
Downloading jinja2-3.1.6-py3-none-any.whl (134 kB)
Downloading markupsafe-3.0.4-cp313-cp313-manylinux2014_x86_64.manylinux_2_17_x86_64.manylinux_2_28_x86_64.whl (23 kB)
Downloading packaging-26.3-py3-none-any.whl (129 kB)
Downloading pygments-2.21.0-py3-none-any.whl (1.3 MB)
Downloading werkzeug-3.1.9-py3-none-any.whl (228 kB)
Installing collected packages: pygments, pluggy, packaging, markupsafe, itsdangerous, iniconfig, click, blinker, werkzeug, pytest, jinja2, flask
Successfully installed blinker-1.9.0 click-8.5.0 flask-3.1.3 iniconfig-2.3.1 itsdangerous-2.2.0 jinja2-3.1.6 markupsafe-3.0.4 packaging-26.3 pluggy-1.7.0 pygments-2.21.0 pytest-9.1.1 werkzeug-3.1.9
```

**The versions are pinned on purpose.** A later Flask or pytest will run every program in this
course, but the transcripts quote the versions they were recorded with, and a pinned version is
the honest way to reproduce a recording. Lesson 17 is about what pinning buys in a real project
and what it costs.

pip pulled in ten more packages: six that Flask needs and four that pytest needs. `pip list` shows
the whole environment, which is worth knowing from the first day, because every one of those names
is code you now run:

```
(.venv) ana@vm:~/sc$ pip list
Package      Version
------------ -------
blinker      1.9.0
click        8.5.0
Flask        3.1.3
iniconfig    2.3.1
itsdangerous 2.2.0
Jinja2       3.1.6
MarkupSafe   3.0.4
packaging    26.3
pip          26.2.1
pluggy       1.7.0
Pygments     2.21.0
pytest       9.1.1
Werkzeug     3.1.9
```

Last, the first lesson's folder. **Each lesson's application lives in a folder of its own, and each
folder is a git repository**, so the fix you make is a diff you can read, and a broken experiment
is one `git checkout .` away from the version that worked:

```
(.venv) ana@vm:~/sc$ mkdir cancel
(.venv) ana@vm:~/sc$ cd cancel
(.venv) ana@vm:~/sc/cancel$ git init -b main
Initialized empty Git repository in /home/ana/sc/cancel/.git/
```

That is the whole lab. Each time you come back, open a terminal, `cd ~/sc` and
`. .venv/bin/activate` before anything else; `deactivate` leaves it.
