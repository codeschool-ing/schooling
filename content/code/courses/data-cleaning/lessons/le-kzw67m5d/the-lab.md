---
title: The lab, and three ways to build it
version: 1
---

**Nobody learns to clean data by reading about dirty data.** You learn it the first time a total
you trusted turns out to count a hundred orders twice, and you can only have that moment with
the files open in front of you. So every lesson is run, and you should run it too, on a machine
you build yourself. This section builds it, and the next one makes the data.

The lab is one Linux computer with four things on it:

- **the files**, in `~/clean/raw`: nine CSV exports from Quitanda Verde's systems, made read-only on
  purpose — lesson 17 says why — and three small reference files from outside the company in
  `~/clean/ref`;
- **PostgreSQL 16**, with a database called `quitanda` and a schema called `raw` that holds every
  file loaded exactly as it arrived, **every column as text**;
- **Python 3 with pandas**, in a virtual environment, plus RapidFuzz for lesson 5's fuzzy matching
  and Matplotlib for lesson 15's charts;
- **R with dplyr**, which only lesson 16 uses.

## Three ways to have one

| path | what you get | what it costs | the transcripts |
|---|---|---|---|
| **a virtual machine** (recommended) | Ubuntu 24.04 apart from your own system | a few gigabytes of disk, and 2 GB of memory while it runs | match as printed |
| **installed** | the same programs on the computer you already use | a database server running on your computer | match on Ubuntu 24.04; close elsewhere |
| **online** | a Linux machine in your browser | nothing on your computer; hours from a monthly allowance | close, not exact |

**The virtual machine is the recommended path.** The setup adds a database server and system
packages, which is the kind of change you may not want on the computer you work on, and a
snapshot taken once it is done gives you a clean start whenever an experiment goes wrong.
`virtualization` lesson 4 builds one in VirtualBox if you have not. On Windows, WSL running
Ubuntu 24.04 is a virtual machine too, and works the same way. Name the machine `lab` if you like:
every transcript here prints `ana@lab`, where `ana` is the analyst and `lab` the machine. Yours will
print your own name.

**Installed** is fine on a computer that already runs Ubuntu 24.04, with the same commands. On
macOS or another Linux the programs are the same and the package names differ; that was not run
here, so a version or a path in a transcript may differ from yours.

**Online**, GitHub Codespaces gives you a Linux machine with a terminal in the browser. It costs
your computer nothing; GitHub gives personal accounts a monthly allowance and charges past it, on
terms it sets and can change. It was not run for this course. Which Linux a codespace runs decides
whether the commands below work as printed, and `cat /etc/os-release` tells you before you start.

## Building it

Everything below is typed in a terminal on the machine you chose. First the programs, from
Ubuntu's own packages:

```sh
sudo apt-get update
sudo apt-get install -y postgresql python3-venv r-base-core r-cran-dplyr r-cran-tidyr r-cran-readr
```

`postgresql` is version 16 on Ubuntu 24.04, and installing it creates a database server and starts
it. The server knows no user yet except its own, `postgres`, so the next line asks it to create one
with your login name, allowed to create databases:

```sh
sudo -u postgres createuser --createdb "$USER"
```

From then on `psql` connects as you, through a socket on the same machine, with no password: the
server asks the operating system who is on the other end.

Then pandas and the two libraries beside it, in a **virtual environment**: a directory of its own,
`~/venv`, with its own Python and its own packages, so nothing here touches the Python Ubuntu itself
runs on. The versions are pinned, because a newer pandas can print a number differently, and
lesson 17 is about why that matters:

```sh
python3 -m venv ~/venv
source ~/venv/bin/activate
pip install pandas==3.0.6 numpy==2.5.3 rapidfuzz==3.14.6 matplotlib==3.11.2
```

Last, four lines at the end of `~/.bashrc`, so that every new terminal starts the same way:

```sh
cat >> ~/.bashrc <<'EOF'
# data-cleaning
export TZ=America/Sao_Paulo
export PGDATABASE=quitanda
source ~/venv/bin/activate
EOF
```

`TZ` puts the machine on the company's clock, which lesson 7 needs. `PGDATABASE` lets `psql` find
the database without being told its name every time, and the last line makes `python` the one in
`~/venv`. Open a new terminal and check:

```
ana@lab:~$ tail -4 .bashrc
# data-cleaning
export TZ=America/Sao_Paulo
export PGDATABASE=quitanda
source ~/venv/bin/activate
```

```
ana@lab:~$ psql --version
psql (PostgreSQL) 16.15 (Ubuntu 16.15-0ubuntu0.24.04.1)
ana@lab:~$ python --version
Python 3.12.3
ana@lab:~$ python -c 'import pandas; print(pandas.__version__)'
3.0.6
ana@lab:~$ R --version | head -1
R version 4.3.3 (2024-02-29) -- "Angel Food Cake"
```

```
ana@lab:~$ pg_lsclusters
Ver Cluster Port Status Owner    Data directory              Log file
16  main    5432 online postgres /var/lib/postgresql/16/main /var/log/postgresql/postgresql-16-main.log
```

`online` is the server running. It cost this much disk, beside the operating system:

```
ana@lab:~$ du -sh venv /usr/lib/R /usr/lib/postgresql
264M	venv
74M	/usr/lib/R
44M	/usr/lib/postgresql
```

The largest thing on the machine is the Python environment, at 264 MB, which is pandas and its
numerical libraries. The files the course cleans, made in the next section, are under 7 MB. **Small
data is a choice**: every query in this course comes back at once, so the attention goes on what the
answer says rather than on waiting for it.

## When the setup fails

Three failures account for most of it, and each one names itself.

**The server is not running.** `psql` cannot find the socket it talks through:

```
ana@lab:~$ psql -c "SELECT 1"
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5432" failed: No such file or directory
	Is the server running locally and accepting connections on that socket?
ana@lab:~$ pg_lsclusters
Ver Cluster Port Status Owner    Data directory              Log file
16  main    5432 down   postgres /var/lib/postgresql/16/main /var/log/postgresql/postgresql-16-main.log
```

`pg_lsclusters` says `down`. Something stopped it, or the machine started without starting it. Start
it, and check:

```
ana@lab:~$ sudo service postgresql start
 * Starting PostgreSQL 16 database server
   ...done.
ana@lab:~$ pg_lsclusters
Ver Cluster Port Status Owner    Data directory              Log file
16  main    5432 online postgres /var/lib/postgresql/16/main /var/log/postgresql/postgresql-16-main.log
ana@lab:~$ psql -c "SELECT 1"
 ?column? 
----------
        1
(1 row)
```

If it will not start, the log file in the last column says why, and its last lines are the ones
that matter.

**You skipped `createuser`.** The server is up and does not know you. Here a second user on the
same machine, `bia`, who never ran it:

```
bia@lab:~$ psql
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5432" failed: FATAL:  role "bia" does not exist
```

Run the `createuser` line above, with your own login name, and try again.

**`pip` ran outside the virtual environment.** In a terminal opened before `~/.bashrc` had its new
lines, `python3` is Ubuntu's own, and Ubuntu refuses to install packages into it:

```
ana@lab:~$ python3 -m pip install pandas==3.0.6
error: externally-managed-environment

× This environment is externally managed
```

The message goes on to suggest a virtual environment, which is what `~/venv` is. Open a new
terminal, or run `source ~/venv/bin/activate`, and `pip` installs into the right place. If
`python3 -m venv` itself fails, the package `python3-venv` is missing from the `apt-get` line.

If something fails that is not here, read the last lines it printed before reading anything else.
The first error is the one that matters, and the lines after it are usually its consequences.
