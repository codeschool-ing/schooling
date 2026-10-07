---
title: The lab, and three ways to run it
version: 2
---

**Nobody understands a star schema by reading one.** You understand it when a query you expected to
be slow comes back in twenty milliseconds, or when a total you trusted turns out to count every
book twice. So every lesson here is run, and you should run it too, on a computer of your own.
Nothing in this course runs on a machine we host.

The lab is two databases on one Linux machine:

- **PostgreSQL 16** holds the shop's operational database, `shop`: fifteen tables in third normal
  form, the shape `sql-databases` taught you to build.
- **DuckDB** holds the warehouse, `wh.duckdb`, one file in your working directory. It is an
  analytical database that runs inside the program that opens it, with no server, and it stores
  data by column. Lesson 8 is about why that matters.

The machine in the transcripts belongs to Ana, the shop's data analyst. It is called `lab`, her
working directory is `~/wh`, and her prompt reads `ana@lab:~/wh$`. Yours will carry your own name.
This section installs the programs, the next one creates the shop's database, and the one after it
fills the database with two years of trade.

## Three ways to run it

| | what it is | what it costs your computer |
|---|---|---|
| **a virtual machine** (recommended) | Ubuntu Server 24.04 LTS in a virtual machine, with Multipass or another hypervisor | 2 processors and 4 GB of memory while it runs, and a 20 GB disk |
| installed | Ubuntu 24.04 as the system of a computer you use, or inside WSL on Windows | about 2 GB of disk, and a database server that starts with the computer |
| online | DuckDB in a web browser, at `shell.duckdb.org` | nothing, and only half of the course |

**A virtual machine is the recommendation**, because the course installs a database server and
then fills it, and both are easier to throw away than to remove. Multipass, from Canonical, makes
an Ubuntu virtual machine with one command on Windows, macOS and Linux. Install it from its
website, then in your computer's own terminal:

```sh
multipass launch 24.04 --name lab --cpus 2 --memory 4G --disk 20G
multipass shell lab
```

**Those two commands were not run for this course**, because the computer it was recorded on cannot
run a hypervisor. The first creates the machine and the second opens a shell inside it, as the user
`ubuntu`; everything after this point is typed in that shell. Any other hypervisor does the same
job with more installer screens: VirtualBox on Windows and Linux, UTM on an Apple-silicon Mac,
Hyper-V on Windows. Give the machine Ubuntu Server 24.04 LTS and the sizes in the table.

**Installed** costs nothing extra if your computer already runs Ubuntu 24.04, or Windows with WSL
and the Ubuntu 24.04 distribution, which runs the same commands. PostgreSQL then starts every time
the computer does, until you remove it. On a Mac, Homebrew installs PostgreSQL 16 and the same
Python packages, but the commands below are Ubuntu's and the course was not recorded that way.

**Online** is named so that you know it exists. DuckDB runs inside a web browser at
`shell.duckdb.org` and can query a CSV or Parquet file you open in it, which covers the warehouse
queries and not the PostgreSQL half. Several companies host PostgreSQL with a free allowance; none
is needed here, and an allowance that changes its terms is not something a course should rest on.

## The programs

Everything comes from Ubuntu's own archive and from the Python Package Index. In the machine's
shell:

```sh
sudo apt-get update
sudo apt-get install -y postgresql python3-venv
python3 -m venv ~/wh-env
~/wh-env/bin/pip install duckdb==1.5.6 duckdb-cli==1.5.6 deltalake==1.6.6 pyarrow==25.0.1
cat >> ~/.bashrc <<'END'
export PGDATABASE=shop
export TZ=America/Sao_Paulo
. ~/wh-env/bin/activate
END
. ~/.bashrc
mkdir ~/wh && cd ~/wh
```

The first two lines install **PostgreSQL 16**, the version Ubuntu 24.04 ships, and start it. The
next two make a Python virtual environment in `~/wh-env` and install DuckDB into it, at the version
the course was recorded with. The four packages are the command-line program, the Python library
lessons 11 and 12 use, and `deltalake` with `pyarrow` for lesson 10. A virtual environment keeps all of that out of the
system's own Python, and deleting the folder removes it.

The three lines added to `~/.bashrc` run in every new terminal. `PGDATABASE` lets you type `psql`
instead of `psql shop` every time; `TZ` makes times print in São Paulo's offset, as they do in the
transcripts; the last line puts the virtual environment's programs first on your path.

Those commands were run on the recording machine, and their output is a page of download progress
that is not worth quoting. What they leave behind is:

```
ana@lab:~/wh$ psql --version
psql (PostgreSQL) 16.15 (Ubuntu 16.15-0ubuntu0.24.04.1)
ana@lab:~/wh$ duckdb --version
v1.5.6 (Variegata) 069cc9f9b5
ana@lab:~/wh$ python3 --version
Python 3.12.3
```

Three programs, at the versions the transcripts were made with. A different patch number of
PostgreSQL, 16.16 rather than 16.15, changes nothing in this course. A different DuckDB version can
change the look of an error or the width of a table, so keep the pin.
