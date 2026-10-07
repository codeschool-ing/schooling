---
title: The lab, and three ways to run it
version: 1
---

**A pipeline is only understood by running it, and by running it again tomorrow.** So this course
does not hand you a machine. You build one, on your own computer, and every command in every
lesson is typed there.

The lab is one Linux machine with these on it:

- **PostgreSQL 16**, with three databases: `shop`, the operational database the tills and the
  website write to; `wh`, the warehouse your pipelines will fill; and `airflow`, where Airflow keeps
  its own records from lesson 8 on.
- **Python 3**, with one virtual environment per tool. Airflow, dbt, Prefect and Dagster each pin
  their own versions of the same libraries, and in one environment they would fight.
- **The shop's data**, three months of trade drawn by a generator with fixed seeds, so your numbers
  are the ones printed here.
- **A small price API**, written for the course, that pages its answers, limits how fast you may
  ask, and can be made to fail on purpose.

All of it is built by one script, `lab.sh`, which comes with the course material. Copy the `lab`
directory to your home directory and run it once:

```
ana@vm:~$ sudo bash ~/lab/lab.sh up
```

It creates a user called `ana`, installs everything under `/opt/etl`, generates the data and
loads the shop. With the packages already downloaded once it took about a minute and a half on
the machine the course was recorded on; the first time, most of the wait is the download. Then
check what you have:

```
ana@vm:~/etl$ psql --version
psql (PostgreSQL) 16.15 (Ubuntu 16.15-0ubuntu0.24.04.1)
ana@vm:~/etl$ python --version
Python 3.13.16
ana@vm:~/etl$ airflow version
3.3.2
ana@vm:~/etl$ dbt --version | head -2
Core:
  - installed: 1.12.5
```

And what it cost:

```
ana@vm:~/etl$ du -sh /var/lib/etl-data /var/lib/etl-pg /opt/etl
19M	/var/lib/etl-data
79M	/var/lib/etl-pg
1.3G	/opt/etl
```

**The data is small and the tools are not.** Nineteen megabytes of trade and 1.3 GB of software
to move it. That ratio is normal for a laptop and the opposite of production, and lesson 19 is
where the data gets large enough to matter.

## Three ways to run it

**In a virtual machine — recommended.** An Ubuntu 24.04 virtual machine with 4 GB of memory and
10 GB of free disk. From lesson 8 Airflow runs four processes at once, and on the recording machine
they held about 1.4 GB of memory between them before any DAG had run. The script adds a user, a
database server and six Python environments, which is exactly the kind of change you do not want
on the computer you work on. `virtualization` lesson 4
builds one in VirtualBox if you have not.

**Installed on your own Linux computer.** Read `lab.sh` and do what it does by hand: install
PostgreSQL 16, create the three databases, make the virtual environments with the versions it
pins. It is under three hundred lines and every step is commented. This is the path that teaches the
most and breaks the most.

**In containers, for the tools alone.** Airflow publishes an official container image and a
Compose file, and dbt runs in any Python image. That gets you the software but not this lab — the
shop, its data and the day-by-day clock are in `lab.sh` — and the course was not recorded that
way. It is named here for the student who already works in containers and wants to bring the
lessons into that setup.
