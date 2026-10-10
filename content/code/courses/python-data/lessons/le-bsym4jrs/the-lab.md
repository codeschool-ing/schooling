---
title: The lab, and three ways to build it
version: 1
---

**Every lesson in this course is something you type and watch happen.** A broadcasting error, a
join that doubles your rows, a chart with its labels cut off: each is learnt in the second you see
it on your own screen, and no amount of reading replaces that second. So you need a machine with
the scientific stack on it, and this section builds one. The platform provides none, and the
course never assumes one.

The lab is small. It is one folder, `~/pydata`, holding:

- **a virtual environment**, `.venv`: a Python of its own with the seven libraries this course
  uses, installed at the versions every output here was recorded with;
- **JupyterLab**, the notebook application the next section opens;
- **the data**, three CSV files a short program writes, which the section after this one shows in
  full.

Nothing runs in the background, nothing is installed system-wide apart from Python itself, and
deleting the folder removes all of it.

## Three ways to have one

| path | what you get | what it costs your computer | the outputs |
|---|---|---|---|
| **installed** (recommended) | Python and the folder on the computer you already use | about 650 MB of disk; memory only while JupyterLab is open | match on Ubuntu 24.04; the same numbers elsewhere |
| **a virtual machine** | Ubuntu 24.04 apart from your own system | a few gigabytes of disk, and 2 GB of memory while it runs | match as printed |
| **online** | a Linux machine, or a notebook, in your browser | nothing on your computer; hours from somebody's allowance | close, not exact |

**Installed is the recommended path.** A virtual environment already keeps the libraries apart from
everything else on the computer, and that isolation is what a virtual machine would buy anywhere
else. JupyterLab runs in the browser you already have, the charts appear in it, and the files you
make are files on your own disk, where you can open them with anything.

The transcripts in this course were recorded on Ubuntu 24.04. Python prints the same numbers on
Windows and macOS, so a cell's output will match yours; what differs is the shell around it, and
the next part says where.

**A virtual machine** is the path if you would rather keep even Python off the computer you work
on. `virtualization` lesson 4 builds one in VirtualBox; give it Ubuntu 24.04 with a desktop, so
the browser JupyterLab opens is inside the machine with it. On Windows, **WSL** running Ubuntu
24.04 is a virtual machine too, and the commands below work in it as printed; JupyterLab's
address then opens in your Windows browser. Neither was run for this course beyond the Ubuntu
inside it.

**Online**, GitHub Codespaces gives you a Linux machine with a terminal in the browser, where the
commands below work, and Google Colab gives you a notebook with no setup at all. Both cost your
computer nothing and both are one company's allowance, on terms that company sets and can change.
Colab also brings its own versions of every library, which is the opposite of what lesson 3 is
about, and its own interface rather than JupyterLab's. Neither was run for this course. If you
use one, check the versions first with the last command of the next part.

## Building it

You need **Python 3.12 or newer**, because the NumPy this course pins does not install on anything
older. Check what you have, in a terminal:

```
ana@lab:~$ python3 --version
Python 3.12.3
```

On Ubuntu 24.04 that is the Python the system already has, and the one missing piece is the module
that makes virtual environments, which Ubuntu ships as a separate package:

```sh
sudo apt-get update
sudo apt-get install -y python3-venv
```

On Windows and macOS, install Python from python.org if `python3 --version` (on Windows,
`py --version`) answers with something older than 3.12 or nothing at all. The installer brings
`venv` with it. Neither system was used to record this course.

Then the folder, the environment and the libraries:

```sh
mkdir pydata
cd pydata
python3 -m venv .venv
source .venv/bin/activate
pip install jupyterlab==4.6.4 numpy==2.5.3 pandas==3.0.6 matplotlib==3.11.2 seaborn==0.13.2 pyarrow==26.0.0 openpyxl==3.1.5
```

On Windows the third and fourth lines are `py -m venv .venv` and `.venv\Scripts\activate`; the
rest is the same.

`python3 -m venv .venv` makes the environment: a directory with its own `python` and its own
`pip`. `source .venv/bin/activate` makes this terminal use them, and the prompt says so by putting
the environment's name in front of it, `(.venv)`. **Every terminal you open for this course needs
that line run once**, inside the folder, before anything else. Lesson 3 is about what the
environment is and why the versions are pinned; for now, pinned means that your pandas prints what
this course's pandas printed.

`pip install` takes a minute or two and ends with a long `Successfully installed` line naming
about a hundred packages, because each of the seven brings what it depends on. Check it:

```
(.venv) ana@lab:~/pydata$ python --version
Python 3.12.3
(.venv) ana@lab:~/pydata$ python -c "import numpy, pandas, matplotlib, seaborn; print(numpy.__version__, pandas.__version__, matplotlib.__version__, seaborn.__version__)"
2.5.3 3.0.6 3.11.2 0.13.2
(.venv) ana@lab:~/pydata$ jupyter lab --version
4.6.4
```

## Starting JupyterLab

```sh
jupyter lab
```

JupyterLab is a program that serves web pages to your browser, and starting it opens one. The
terminal keeps printing what the server is doing, and among its first lines are these:

```
[I 2026-10-10 04:06:02.538 ServerApp] Serving notebooks from local directory: /home/ana/pydata
[I 2026-10-10 04:06:02.538 ServerApp] Jupyter Server 2.21.1 is running at:
[I 2026-10-10 04:06:02.538 ServerApp] http://localhost:8888/lab?token=ea4dc1071297d10dd55cd029eda14770290d8dc83041108c
[I 2026-10-10 04:06:02.538 ServerApp]     http://127.0.0.1:8888/lab?token=ea4dc1071297d10dd55cd029eda14770290d8dc83041108c
[I 2026-10-10 04:06:02.538 ServerApp] Use Control-C to stop this server and shut down all kernels (twice to skip confirmation).
```

Three lines matter. **The address** ends in a long `token`, which is a password the server made up
for this run and put in the link, so that another program on your computer cannot use it. If your
browser did not open on its own, copy that address into it. **The port**, `8888`, is where the
server listens. And **`Use Control-C to stop this server`** is how it ends: the terminal stays
busy for as long as JupyterLab runs, so open a second terminal for anything else.

It cost this much disk, beside Python itself:

```
(.venv) ana@lab:~/pydata$ du -sh .venv
635M	.venv
```

## Starting again

Each time you come back to the course:

```sh
cd pydata
source .venv/bin/activate
jupyter lab
```

The section on failures, at the end of this lesson, starts from the first of those lines being
forgotten.
