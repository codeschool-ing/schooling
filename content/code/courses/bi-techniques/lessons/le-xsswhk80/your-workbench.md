---
title: The computer you will analyse on
version: 1
---

**Most of this course is reading results and deciding what they mean.** The rest is running the
analyses that produce them, and that needs a place to run them. This section sets that place up on
your own computer, once, and every later lesson that runs a program assumes it exists.

You need **Python 3.12 or newer** with three packages:

- **pandas**, which reads the CSV files and does the arithmetic on tables and dates;
- **statsmodels**, which holds the time-series models and the statistical tests;
- **scikit-learn**, which holds the clustering and the machine-learning models of lessons 15 to 19.

Installing those brings numpy and scipy with them, and that is everything the course runs.

::: track bi
On your track `python` came three courses ago, so the language is familiar and pandas may not be.
That is fine: every program in this course is printed whole, with a note beside each part saying
what it does, and nothing asks you to write pandas from a blank file. Read the notes, run the
program, and spend your attention on what it prints.
:::

::: track data-science
On your track `python-data` taught pandas, and `machine-learning` used scikit-learn just before
this course, so the tools here are ones you already hold. What is new is statsmodels and the
analyses themselves. The programs are short on purpose, and changing them is the best exercise
this course has.
:::

::: track *
If you have used pandas before, the programs will read easily. If you have not, every one is
printed whole with a note beside each part, and nothing asks you to write pandas from a blank file.
:::

## Three ways to get a working setup

| path | what it costs | when to choose it |
|---|---|---|
| **installed on your computer** (recommended) | about 420 MB of disk for the packages, plus Python itself | you have a laptop or desktop you can install software on |
| **in a virtual machine** | 25 GB of disk and 4 GB of memory for an Ubuntu 24.04 machine in VirtualBox | your computer is not yours to change, or you want the exact system these lessons were recorded on |
| **online, in a hosted notebook** | nothing to install; an account with the provider | you are on a borrowed or locked-down computer |

**The recommended path is the first.** Everything below was typed on Ubuntu 24.04, and on Windows
and macOS the commands differ in the small ways the end of this section names.

The virtual-machine path is the same installation inside a machine of its own, in four steps:

1. install **VirtualBox** from `virtualbox.org`, which is free;
2. download the **Ubuntu 24.04 Desktop** image from `ubuntu.com`, a file of about 6 GB;
3. in VirtualBox, choose *New*, pick the image, and give the machine 4 GB of memory and a 25 GB
   disk;
4. let the installer finish, sign in, open *Terminal*, and follow the rest of this section inside
   the machine.

If you want the long version, with what each setting means, lesson 4 of the `virtualization` course
is that machine built slowly.

The online path is a hosted notebook, such as Google Colab or Kaggle's notebooks, which come with
pandas, statsmodels and scikit-learn already installed. You paste each program into a cell
instead of saving it as a file, and you upload or write the CSV files there. Two warnings come with
it. The versions installed there are the provider's, so a number may differ from the lesson in the
last decimal places. And the terms are the provider's too: a free tier that exists today may not
exist next year, which is why no lesson depends on one.

## Python and the three packages

Check which Python you have. Ubuntu 24.04 already carries 3.12; on Windows and macOS, install it
from `python.org`, and on Windows tick *Add python.exe to PATH* in the installer.

Make a folder for the course, open a terminal in it, and create a **virtual environment**, a
private copy of Python for this folder, then install the packages into it:

```
ana@vm:~/bi$ python3 --version
Python 3.13.16
ana@vm:~/bi$ python3 -m venv .venv
ana@vm:~/bi$ .venv/bin/pip install --quiet pandas==3.0.6 statsmodels==0.15.0 scikit-learn==1.9.1
ana@vm:~/bi$ .venv/bin/python -c "import pandas, statsmodels, sklearn; print(pandas.__version__, statsmodels.__version__, sklearn.__version__)"
3.0.6 0.15.0 1.9.1
```

The machine these lessons were recorded on has Python 3.13, and 3.12 works the same.

**`--quiet` hides pip's progress, and silence means it worked.** The download is a few hundred
megabytes, so it takes a minute or two. The last command asks the new Python which versions it has,
and those three numbers are the answer that matters. The versions are pinned so that your results
come out like the lessons'; a newer version will work, and may print a number that differs in the
last place.

Two things differ off Linux:

- **On Windows**, the programs are in `.venv\Scripts\` rather than `.venv/bin/`, so you type
  `.venv\Scripts\python` wherever the lessons type `.venv/bin/python`.
- **On macOS**, the commands are the same. `python3 --version` tells you whether you are running
  the Python you installed or an older one that came with the system.

The lessons always call `.venv/bin/python` by its full path. You may have learnt to *activate* the
environment instead, which lets you type `python`; either works, and the full path is what was
recorded.
