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
- **Python 3.13**, with one virtual environment per tool. Airflow, dbt, Prefect and Dagster each pin
  their own versions of the same libraries, and in one environment they would fight.
- **The shop's data**, three months of trade drawn by a generator with fixed seeds, so your numbers
  are the ones printed here.
- **A small price API**, written in lesson 3, that pages its answers, limits how fast you may ask,
  and can be made to fail on purpose.

**All of it comes from four files this lesson shows you whole**, which you save in a directory
called `~/pontofinal`: two scripts in the next section, and the shop's database and its data in the
section after. One of the scripts builds everything; the section after those says how to run it.

## Three ways to run it

**In a virtual machine — recommended.** An Ubuntu 24.04 virtual machine with 4 GB of memory and
10 GB of free disk. From lesson 8 Airflow runs four processes at once, and on the recording machine
they held about 1.4 GB of memory between them before any DAG had run. The setup adds a user, a
database server and six Python environments, which is exactly the kind of change you do not want
on the computer you work on. `virtualization` lesson 4 builds one in VirtualBox if you have not.

**Installed on your own Linux computer.** The same steps, on the computer itself. Everything goes
under `/opt/etl`, `/var/lib/etl-*` and a user called `ana`, so it stays apart from your own files,
but it does change the machine, and taking it out again is yours to do by hand. This is the path
that teaches the most and breaks the most.

**In containers, for the tools alone.** Airflow publishes an official container image and a
Compose file, and dbt runs in any Python image. That gets you the software but not this lab — the
shop, its data and the day-by-day clock are in the four files — and the course was not recorded
that way. It is named here for the student who already works in containers and wants to bring the
lessons into that setup.

## Before the files

On Ubuntu 24.04, the packages come first. Ubuntu 24.04's own Python is 3.12 and the course was
recorded on 3.13, which the deadsnakes PPA provides:

```sh
sudo add-apt-repository -y ppa:deadsnakes/ppa
sudo apt-get install -y python3.13-venv postgresql-16 make git curl
```

Then the user. **Every transcript in this course is `ana`'s, on a machine called `vm`**, so making
the same user makes every path in them yours as well. She needs `sudo`, because `shop`, the
command the next section installs, runs as root:

```sh
sudo adduser ana
sudo usermod -aG sudo ana
sudo -iu ana
mkdir ~/pontofinal
```

Those were not captured: the recording machine already had the packages and the user. From here on
every command is `ana`'s, and every transcript is a capture.
