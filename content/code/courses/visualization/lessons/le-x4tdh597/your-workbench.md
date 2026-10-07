---
title: The computer you will draw on
version: 1
---

**Most of this course is judgement**: looking at a chart and deciding what it says, what it hides
and what would say it better. That needs no software. The rest is practice, and practice needs a
place to draw. This section sets that place up on your own computer, once, and every later lesson
that asks you to draw something assumes it exists.

You need two things:

- **a spreadsheet** that draws charts: LibreOffice Calc, Microsoft Excel or Google Sheets;
- **Python with matplotlib**, the plotting library this course's examples are written in.

::: track bi
On your track this course comes after `excel-analytics`, and the spreadsheet you learnt there draws
every chart in this course. Use it first. Python arrives later in your track, in its own course, so
here you only **run** the short programs the lessons print, by copying them. You do not need to
understand every line of them to learn what the chart shows, and each one is explained beside its
code.
:::

::: track data-science
On your track `python` and `python-data` came before this course, so matplotlib will feel familiar.
Use it first. Keep a spreadsheet to hand as well: half the charts you will be asked to fix at work
were made in one, and lesson 20 compares the two.
:::

::: track *
If you already program, start with Python. If you do not, start with the spreadsheet and only run
the programs the lessons print, by copying them. Every chart in the course can be drawn either way.
:::

## Three ways to get a working setup

| path | what it costs | when to choose it |
|---|---|---|
| **installed on your computer** (recommended) | about 1 GB of disk for LibreOffice and Python together | you have a laptop or desktop you can install software on |
| **in a virtual machine** | 25 GB of disk and 4 GB of memory for an Ubuntu machine in VirtualBox | your computer is not yours to change, or you want the exact system these lessons were recorded on |
| **online** | nothing to install; needs a Google account | you are on a borrowed or locked-down computer |

**The recommended path is the first.** The lessons were recorded on Ubuntu 24.04 and every command
below is the one typed there. On Windows and macOS the commands differ in small ways that the next
paragraphs name.

The online path is Google Sheets for the spreadsheet and Google Colab for Python, which comes with
matplotlib already installed. It works for every lesson, and you lose only the habit of running
things on your own machine.

## The spreadsheet

Install **LibreOffice** from `libreoffice.org`, or with `sudo apt install libreoffice-calc` on
Ubuntu. It is free and it opens the CSV files this course uses. If you already have Excel, use
that; the lessons give the menu path in both where it differs.

## Python and matplotlib

You need **Python 3.12 or newer**, because the version of numpy that matplotlib installs today
refuses anything older. On Ubuntu 24.04 it is already there. On Windows and macOS, install it from
`python.org` and, on Windows, tick *Add python.exe to PATH* in the installer.

Make a folder for the course, put the file `horta.py` from the next section in it, and open a
terminal there. Then create a **virtual environment**, a private copy of Python for this folder,
and install matplotlib into it:

```
ana@vm:~/viz$ python3 --version
Python 3.13.16
ana@vm:~/viz$ python3 -m venv .venv
ana@vm:~/viz$ .venv/bin/pip install --quiet matplotlib==3.11.2
ana@vm:~/viz$ .venv/bin/python -c "import matplotlib; print(matplotlib.__version__)"
3.11.2
```

**`--quiet` hides pip's progress, and silence means it worked.** The last line asks the new Python
which matplotlib it has, and `3.11.2` is the answer that matters. The version is pinned so that
your charts come out like the lessons' do; a newer one will work too, with small differences in
the default style.

Two things differ off Linux:

- **On Windows**, the programs are in `.venv\Scripts\` rather than `.venv/bin/`, so you type
  `.venv\Scripts\python` wherever the lessons type `.venv/bin/python`.
- **On macOS**, the commands are the same, but the first one may be `python3` from python.org rather
  than the older one that comes with the system. `python3 --version` tells you which you have.

The lessons always call `.venv/bin/python` by its full path. You may have learnt to *activate* the
environment instead, which changes your prompt and lets you type `python`; either works, and the
full path is what was recorded.
