---
title: The lab, and three ways to build it
version: 1
---

**This course is a map, and a map you only read is easily forgotten.** So most lessons from lesson 3
onwards end with something running: a source made by a short program, a file written in five formats,
a stream with an event arriving late, two copies of one value that stop agreeing. Each program is
printed whole in the lesson that uses it, and you run it on a machine you build yourself. The
platform runs nothing for you. This section builds the machine.

It is small on purpose. The lab is **one directory and one Python**:

- `~/roda`, a directory where every program in the course is saved and run;
- **Python 3.11 or newer**, the one you installed in `python` lesson 1. That course accepts 3.10,
  and this one needs one version more, because pyarrow 26 does;
- a **virtual environment** in `~/roda/.venv` with two libraries: **pyarrow**, which reads and writes
  Parquet and ORC, and **fastavro**, which does the same for Avro. Lesson 6 uses both. Everything else
  in the course is Python's own standard library.

There is no database server to install, and no container. Where a lesson needs a database it uses
SQLite, which is a file and comes inside Python.

## Three ways to have one

| path | what you get | what it costs your computer | the transcripts |
|---|---|---|---|
| **installed** (recommended) | the lab on the computer you already use | 195 MB of disk, and nothing running when you are not | match on Ubuntu 24.04; close elsewhere |
| **a virtual machine** | Ubuntu 24.04 apart from your own system | a few gigabytes of disk, and 2 GB of memory while it runs | match as printed |
| **online** | a Linux machine in your browser | nothing on your computer; hours from a monthly allowance | close, not exact |

**Installed is the recommended path.** A virtual environment is a directory: it changes nothing else
on the computer, starts nothing in the background, and deleting `~/roda` removes every trace of this
course. pyarrow and fastavro publish ready-built packages for Windows, macOS and Linux, so `pip` needs
no compiler on any of them. On Windows two of the commands below are spelt differently, and the
section says which.

**A virtual machine** is the path if you would rather keep your own system untouched, or if the
computer is one you may not install software on. `python` lesson 1 builds one with Ubuntu Server 24.04,
and `virtualization` lesson 4 builds one properly in VirtualBox. On Windows, WSL running Ubuntu 24.04
is a virtual machine too, and the Linux commands below work in it as printed. Every transcript in this
course was recorded on Ubuntu 24.04 with Python 3.12, on a machine called `lab`, as a user called
`ana`. Yours will print your own names.

**Online**, GitHub Codespaces gives you a Linux machine with a terminal in the browser, and it costs
your computer nothing. GitHub gives personal accounts a monthly allowance of hours and charges past
it, on terms it sets and can change; any service that gives you a terminal and a `python3` will do.
It was not run for this course, and `python3 --version` tells you what you have before you start.

## Building it

On Ubuntu and Debian, the module that makes virtual environments is a package of its own. Install it
first:

```sh
sudo apt-get update
sudo apt-get install -y python3-venv
```

On Windows and macOS the Python from python.org already has it, and you skip those two lines.

Then the directory, the environment and the two libraries. The versions are pinned, because lesson 6
prints the size of the files each one writes, and a newer version can write a different number of
bytes:

```sh
mkdir ~/roda
cd ~/roda
python3 -m venv .venv
source .venv/bin/activate
pip install pyarrow==26.0.0 fastavro==1.13.1
```

On Windows, in PowerShell, the fourth line is `.venv\Scripts\Activate.ps1`, and `python3` is `py`.

`source` **activates** the environment: from then on, in that terminal, `python` and `pip` are the
ones inside `.venv`, and the prompt starts with `(.venv)`. The transcripts in this course leave that
prefix out, so the lines are shorter; everything after it is what you will see.

Last, three lines at the end of `~/.bashrc`, so that every new terminal starts on the company's clock
with the environment already active:

```sh
cat >> ~/.bashrc <<'EOF'
# data-fundamentals
export TZ=America/Sao_Paulo
source ~/roda/.venv/bin/activate
EOF
```

`TZ` matters from lesson 3, where a ride starts at a time of day, and most of all in lesson 8, where
the time of an event is the whole subject. On Windows, leave this step out and activate the
environment by hand in each new terminal. Open a new terminal and check:

```
ana@lab:~/roda$ python --version
Python 3.12.3
ana@lab:~/roda$ which python
/home/ana/roda/.venv/bin/python
ana@lab:~/roda$ python -c "import pyarrow, fastavro; print(pyarrow.__version__, fastavro.__version__)"
26.0.0 1.13.1
ana@lab:~/roda$ date +%Z
-03
```

That is the lab. It cost this much disk:

```
ana@lab:~/roda$ du -sh .venv
195M	.venv
ana@lab:~/roda$ du -sh .venv/lib/python3.12/site-packages/* | sort -h | tail -3
13M	.venv/lib/python3.12/site-packages/fastavro
16M	.venv/lib/python3.12/site-packages/pip
167M	.venv/lib/python3.12/site-packages/pyarrow
```

Nearly all of it is pyarrow, which carries a columnar engine written in C++ inside it. If you are on
a virtual machine, take a snapshot now: an experiment that goes wrong later is then one click from
undone.
