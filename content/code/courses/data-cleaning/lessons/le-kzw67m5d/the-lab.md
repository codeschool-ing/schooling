---
title: The lab, and three ways to build it
version: 1
---

**Nobody learns to clean data by reading about dirty data.** You learn it the first time a total
you trusted turns out to count a hundred orders twice, and you can only have that moment with
the files open in front of you. So every lesson is run, and you should run it too, on a machine
you build yourself.

The lab is one Linux computer with four things on it:

- **the files**, in `~/clean/raw`: nine CSV exports from Quitanda Verde's systems, made read-only on
  purpose — lesson 17 says why — and three small reference files from outside the company in
  `~/clean/ref`;
- **PostgreSQL 16**, with a database called `quitanda` and a schema called `raw` that holds every
  file loaded exactly as it arrived, **every column as text**;
- **Python 3 with pandas**, in a virtual environment, plus RapidFuzz for lesson 5's fuzzy matching
  and Matplotlib for lesson 15's charts;
- **R with dplyr**, which only lesson 16 uses.

```
ana@lab:~/clean$ psql --version
psql (PostgreSQL) 16.15 (Ubuntu 16.15-0ubuntu0.24.04.1)
ana@lab:~/clean$ python --version
Python 3.13.16
ana@lab:~/clean$ python -c 'import pandas; print(pandas.__version__)'
3.0.6
ana@lab:~/clean$ R --version | head -1
R version 4.3.3 (2024-02-29) -- "Angel Food Cake"
```

The course's lab script, `lab.sh`, sits beside the course's material with a `lab/` directory
holding the generator and the loading script. `sudo bash lab.sh up` creates a user called `ana`,
writes the data, starts PostgreSQL, loads the raw schema and installs the Python libraries at the
versions the course was recorded with. It left this much on disk:

```
ana@lab:~/clean$ du -sh raw ref /var/lib/clean-pg /opt/clean
6.8M	raw
16K	ref
71M	/var/lib/clean-pg
260M	/opt/clean
```

The data is under 7 MB. The largest thing on the machine is the Python environment, at 260 MB,
which is pandas and its numerical libraries. **Small data is a choice**: every query in this
course comes back at once, so the attention goes on what the answer says rather than on waiting
for it.

## Three ways to run it

**In a virtual machine — recommended.** An Ubuntu 24.04 virtual machine with 2 GB of memory and
5 GB of free disk is enough. `lab.sh` adds a user, a database server and system packages, which
is exactly the kind of change you do not want on the computer you work on, and a snapshot taken
after `up` gives you a clean start whenever an experiment goes wrong. `virtualization` lesson 4
builds one in VirtualBox if you have not.

**Installed on your own computer.** Install PostgreSQL 16, Python 3 and, for lesson 16, R with
the `dplyr`, `tidyr` and `readr` packages. Create a database called `quitanda`, run
`lab/generate.py` to write the files, and run `lab/raw.sql` from the directory that holds `raw/`.
That is what `lab.sh` does, one step at a time, and reading it is the instruction. Windows and
macOS work this way too; only the package manager changes.

**In containers.** PostgreSQL 16 runs well from the official `postgres:16` image, and pandas
needs nothing but Python. If you already work with containers, a database container and a
virtual environment on your own machine are a reasonable lab. The course was not recorded that
way, so a path or a version in a transcript may differ from what you see.

## When the setup fails

Four failures account for most of it, and each one names itself:

- `PostgreSQL 16 is required` — the script found no `initdb`. Install the `postgresql-16`
  package and run `up` again; it picks up where it stopped.
- `R is required for lesson 16` — install the four packages the message lists. Everything except
  lesson 16 works without them, so you can also come back to this later.
- `python3 -m venv` fails and names a package to install, `python3-venv` on Ubuntu. Install it and
  run `up` again.
- `pip` cannot reach the package index, so the environment is empty and `import pandas` fails. A
  proxy or a firewall is the usual cause. Once `pip install pandas` works by hand, the script works
  too.

If something fails that is not on the list, read the last lines the script printed. It stops at
the first error rather than carrying on, so the last line is the one that broke.
