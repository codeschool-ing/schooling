---
title: Your workspace
version: 1
---

Most of this course happens on paper or a whiteboard, and that is not a shortcut: a threat model is
a way of thinking about a drawing. Some of it happens at a terminal, though. Lesson 2 writes the
portal's diagram as code, lesson 3 runs a tool over it, lessons 9 to 11 compute risk with short
Python programs, and lessons 12 and 15 keep decisions and checks in a git repository. **The
platform gives you no machine for this. You build the workspace yourself, once, here**, and every
later lesson says which file it adds to it.

The workspace is small: **Python 3.11 or later, git, and one Python package, `pytm`**, the OWASP
project that describes a system's data flows as Python code and lists threats for it. It needs no
server, no database and no account anywhere.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l01-workspace\" aria-label=\"The workspace this course builds. A folder called tm in your home directory holds two things: .venv, a Python virtual environment with pytm 1.4.0 installed in it, and portal-model, a git repository where every file of the threat model lives. Each lesson adds a file to portal-model and commits it.\"><defs><marker id=\"l01-workspace-tm-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"40.0\" y=\"30.0\" width=\"160.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"120.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">~/tm</text><rect x=\"280.0\" y=\"20.0\" width=\"400.0\" height=\"80.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"296.0\" y=\"42.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">.venv</text><text x=\"296.0\" y=\"70.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Python, and pytm 1.4.0, pinned</text><rect x=\"280.0\" y=\"120.0\" width=\"400.0\" height=\"110.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"296.0\" y=\"142.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">portal-model</text><text x=\"296.0\" y=\"170.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">git: one commit per step of the course</text><text x=\"296.0\" y=\"196.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">model.py  threats.csv  requirements.csv  …</text><path d=\"M200.0 52.0 L240.0 52.0 L240.0 60.0 L280.0 60.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l01-workspace-tm-ah-paper-dim)\"></path><path d=\"M200.0 60.0 L230.0 60.0 L230.0 175.0 L280.0 175.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l01-workspace-tm-ah-paper-dim)\"></path></svg>", "caption": "Two things and nothing else: a pinned tool, and a repository where the model lives beside its history."}
```

### Choose where it runs

| path | what you need | what it costs your computer |
|---|---|---|
| **on your own computer (recommended)** | Linux or macOS as it is; on Windows, WSL with Ubuntu | almost nothing: a folder of about 60 MB |
| in a virtual machine | VirtualBox, UTM or Hyper-V, and an Ubuntu 24.04 image | 2 GB of memory while it runs, 10 GB of disk |
| online | a GitHub account and a Codespace on an empty repository | nothing locally; the free monthly hours are enough for this course |

The first path is recommended because nothing in this course needs isolating: there is no
malware, no target, nothing that listens on a port. The virtual machine is for anybody whose
computer is managed by an employer that does not allow installing software. The online path works
from a borrowed computer and is the slowest to type in.

The transcripts in this course were recorded on Ubuntu 24.04, as a user called `ana` on a machine
called `vm`. On Ubuntu or Debian, the system packages come first:

```sh
sudo apt install python3 python3-venv git
```

That command was not run in the recording: the machine already had all three. On macOS, `git`
arrives with the command line tools (`xcode-select --install`) and Python 3 from python.org or
Homebrew.

### Build it

Check the two versions first. pytm 1.4.0 needs Python 3.11 or later; Ubuntu 24.04 ships 3.12, and
the recording machine had 3.13.

```
ana@vm:~$ python3 --version
Python 3.13.16
ana@vm:~$ git --version
git version 2.43.0
```

Make a folder for the course and a **virtual environment** inside it, so pytm and its libraries
live in `~/tm/.venv` and nowhere else on the system. Activating it changes the prompt, which is
how you can tell later whether it is active:

```
ana@vm:~$ mkdir tm
ana@vm:~/tm$ python3 -m venv .venv
ana@vm:~/tm$ . .venv/bin/activate
(.venv) ana@vm:~/tm$ pip install --progress-bar off pytm==1.4.0
Collecting pytm==1.4.0
  Downloading pytm-1.4.0-py3-none-any.whl.metadata (24 kB)
Collecting pydantic<3.0.0,>=2.10.0 (from pytm==1.4.0)
  Downloading pydantic-2.13.5-py3-none-any.whl.metadata (110 kB)
Collecting annotated-types>=0.6.0 (from pydantic<3.0.0,>=2.10.0->pytm==1.4.0)
  Downloading annotated_types-0.8.0-py3-none-any.whl.metadata (15 kB)
Collecting pydantic-core==2.46.5 (from pydantic<3.0.0,>=2.10.0->pytm==1.4.0)
  Downloading pydantic_core-2.46.5-cp313-cp313-manylinux_2_17_x86_64.manylinux2014_x86_64.whl.metadata (6.6 kB)
Collecting typing-extensions>=4.14.1 (from pydantic<3.0.0,>=2.10.0->pytm==1.4.0)
  Downloading typing_extensions-4.16.0-py3-none-any.whl.metadata (3.3 kB)
Collecting typing-inspection>=0.4.2 (from pydantic<3.0.0,>=2.10.0->pytm==1.4.0)
  Downloading typing_inspection-0.4.4-py3-none-any.whl.metadata (2.6 kB)
Downloading pytm-1.4.0-py3-none-any.whl (185 kB)
Downloading pydantic-2.13.5-py3-none-any.whl (472 kB)
Downloading pydantic_core-2.46.5-cp313-cp313-manylinux_2_17_x86_64.manylinux2014_x86_64.whl (2.1 MB)
Downloading annotated_types-0.8.0-py3-none-any.whl (13 kB)
Downloading typing_extensions-4.16.0-py3-none-any.whl (45 kB)
Downloading typing_inspection-0.4.4-py3-none-any.whl (14 kB)
Installing collected packages: typing-extensions, annotated-types, typing-inspection, pydantic-core, pydantic, pytm
Successfully installed annotated-types-0.8.0 pydantic-2.13.5 pydantic-core-2.46.5 pytm-1.4.0 typing-extensions-4.16.0 typing-inspection-0.4.4
```

**The version is pinned on purpose.** pytm's list of threats changes between releases, and lesson 3
quotes how many it finds for the portal. With another version the count is a different number,
and the lesson's argument still holds while its arithmetic does not.

`pip show` confirms what was installed and where:

```
(.venv) ana@vm:~/tm$ pip show pytm
Name: pytm
Version: 1.4.0
Summary: A Pythonic framework for threat modeling
Home-page: https://github.com/OWASP/pytm
Author: pytm Team
Author-email: please_use_github_issues@nowhere.com
License: MIT
Location: /home/ana/tm/.venv/lib/python3.13/site-packages
Requires: pydantic
Required-by: 
```

Last, the repository where the model will live. A threat model kept as files in git has a history,
can be reviewed in a pull request like code, and is the shape lesson 15 depends on:

```
(.venv) ana@vm:~/tm$ git init -b main portal-model
Initialized empty Git repository in /home/ana/tm/portal-model/.git/
(.venv) ana@vm:~/tm$ ls -A
.venv
portal-model
```

That is the whole workspace. Each time you come back, `cd ~/tm` and `. .venv/bin/activate` before
anything else.

### When it does not work

Two failures are common enough to have been reproduced on purpose. **A version pip cannot find**
lists the ones that exist, which tells you pip reached PyPI and the problem is the number you
typed:

```
(.venv) ana@vm:~/tm$ pip install --progress-bar off pytm==9.9.9
ERROR: Could not find a version that satisfies the requirement pytm==9.9.9 (from versions: 0.3, 0.4, 0.6, 0.7, 0.8, 0.8.1, 1.0, 1.1.0, 1.1.1, 1.1.2, 1.2.0, 1.2.1, 1.3.0, 1.3.1, 1.4.0)
ERROR: No matching distribution found for pytm==9.9.9
```

If `1.4.0` is missing from that list, your Python is older than 3.11: pip leaves out the versions
that need a newer Python, and says so in a line of its own. If there is no list at all and pip complains about the network, your computer
reaches the internet through a proxy, and `HTTPS_PROXY` has to carry its address.

**A shell where the environment is not active** has never heard of pytm, because it was installed
into `.venv` and nowhere else:

```
(.venv) ana@vm:~/tm$ deactivate
ana@vm:~/tm$ python3 -c 'import pytm'
Traceback (most recent call last):
  File "<string>", line 1, in <module>
    import pytm
ModuleNotFoundError: No module named 'pytm'
```

The prompt is the tell: no `(.venv)` at its start. Two more failures belong to Debian and Ubuntu
and were not reproduced here. If `python3 -m venv` complains about `ensurepip`, the
`python3-venv` package is missing: install it, delete `.venv` and create it again. If pip refuses
with a message about an **externally managed environment**, it ran outside the virtual
environment, against the system's own Python. Activate `.venv` and try again, and never reach for
`sudo pip`.
